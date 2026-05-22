import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/monetization_config.dart';
import '../core/telemetry/app_telemetry.dart';
import '../data/api/api_service.dart';
import '../data/models/subscription_status.dart';
import '../services/session_manager.dart';

/// Premium entitlement, store purchases, and profile sync.
class SubscriptionViewModel extends ChangeNotifier {
  SubscriptionViewModel({
    required ApiService apiService,
    required SessionManager sessionManager,
    required AppTelemetry appTelemetry,
    FirebaseAuth? firebaseAuth,
  })  : _api = apiService,
        _session = sessionManager,
        _telemetry = appTelemetry,
        _auth = firebaseAuth ?? FirebaseAuth.instance {
    _status = _session.readSubscriptionCacheSync();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        if (kDebugMode) debugPrint('[Subscription] purchase stream: $e');
      },
    );
    unawaited(_initStore());
  }

  final ApiService _api;
  final SessionManager _session;
  final AppTelemetry _telemetry;
  final FirebaseAuth _auth;

  late SubscriptionStatus _status;
  SubscriptionStatus get status => _status;
  bool get isPremium => _status.isPremium;

  bool _storeAvailable = false;
  bool get storeAvailable => _storeAvailable;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> _initStore() async {
    if (kIsWeb) return;
    _storeAvailable = await InAppPurchase.instance.isAvailable();
    if (!_storeAvailable) return;
    final response = await InAppPurchase.instance.queryProductDetails(
      {MonetizationConfig.standardProductId},
    );
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }
    notifyListeners();
  }

  void applyProfileSubscription(Map<String, dynamic>? subscriptionJson) {
    _status = SubscriptionStatus.fromJson(subscriptionJson);
    unawaited(_session.saveSubscriptionCacheSync(_status));
    unawaited(_telemetry.setSubscriptionTier(
      _status.isPremium ? 'standard' : 'free',
    ));
    notifyListeners();
  }

  Future<void> refreshFromApi() async {
    final user = _auth.currentUser;
    if (user == null || _session.isGuestMode()) {
      _status = const SubscriptionStatus();
      await _session.clearSubscriptionCacheSync();
      await _telemetry.setSubscriptionTier('free');
      notifyListeners();
      return;
    }
    try {
      final token = await user.getIdToken();
      final profile = await _api.getUserProfile(idToken: token);
      applyProfileSubscription(profile.subscription);
    } catch (e) {
      if (kDebugMode) debugPrint('[Subscription] refreshFromApi: $e');
    }
  }

  /// Clears in-flight purchase UI state (e.g. when paywall is dismissed).
  void resetPurchaseUiState() {
    if (!_loading && _error == null) return;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> subscribe() async {
    if (kIsWeb) {
      _error = 'Subscriptions are available in the mobile app.';
      notifyListeners();
      return;
    }
    final user = _auth.currentUser;
    if (user == null || _session.isGuestMode()) {
      _error = 'Sign in to subscribe.';
      notifyListeners();
      return;
    }
    if (!_storeAvailable || _product == null) {
      _error = 'Store is not available right now.';
      notifyListeners();
      return;
    }
    _error = null;
    notifyListeners();
    final param = PurchaseParam(productDetails: _product!);
    try {
      final started =
          await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _error = 'Could not start purchase. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (kIsWeb) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != MonetizationConfig.standardProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _loading = true;
          notifyListeners();
          break;
        case PurchaseStatus.error:
          _loading = false;
          final code = purchase.error?.code ?? '';
          if (_isUserCanceledPurchase(code)) {
            _error = null;
            await _telemetry.logPremiumPurchaseResult(result: 'cancel');
          } else {
            _error = purchase.error?.message ?? 'Purchase failed';
            await _telemetry.logPremiumPurchaseResult(
              result: 'error',
              errorCode: purchase.error?.code,
            );
          }
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _loading = false;
          _error = null;
          await _telemetry.logPremiumPurchaseResult(result: 'cancel');
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _loading = true;
          notifyListeners();
          await _verifyWithBackend(purchase);
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          break;
      }
    }
  }

  bool _isUserCanceledPurchase(String errorCode) {
    final normalized = errorCode.toLowerCase();
    return normalized.contains('cancel') ||
        normalized == '1' || // Android BILLING_RESPONSE_RESULT_USER_CANCELED
        normalized == 'user_canceled';
  }

  Future<void> _verifyWithBackend(PurchaseDetails purchase) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final token = await user.getIdToken();
      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      final verification = purchase.verificationData;
      final result = await _api.verifySubscription(
        platform: platform,
        productId: purchase.productID,
        purchaseToken:
            platform == 'android' ? verification.serverVerificationData : null,
        receiptData:
            platform == 'ios' ? verification.serverVerificationData : null,
        idToken: token,
      );
      final sub = result['subscription'];
      if (sub is Map) {
        applyProfileSubscription(Map<String, dynamic>.from(sub));
      } else {
        await refreshFromApi();
      }
      _loading = false;
      _error = null;
      await _telemetry.logPremiumPurchaseResult(result: 'success');
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      await _telemetry.logPremiumPurchaseResult(
        result: 'error',
        errorCode: 'verify_failed',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
