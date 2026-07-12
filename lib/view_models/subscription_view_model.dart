import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/monetization_config.dart';
import '../core/subscription_log.dart';
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
      onError: (Object e, StackTrace st) {
        subscriptionLog('purchaseStream error: $e');
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
        }
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
    subscriptionLog(
      'initStore: start platform=${defaultTargetPlatform.name} '
      'productId=${MonetizationConfig.standardProductId}',
    );
    if (kIsWeb) {
      subscriptionLog('initStore: skipped (web)');
      return;
    }
    _storeAvailable = await InAppPurchase.instance.isAvailable();
    subscriptionLog('initStore: isAvailable=$_storeAvailable');
    if (!_storeAvailable) {
      notifyListeners();
      return;
    }
    final response = await InAppPurchase.instance.queryProductDetails(
      {MonetizationConfig.standardProductId},
    );
    final queryError = response.error;
    subscriptionLog(
      'initStore: queryProductDetails '
      'found=${response.productDetails.length} '
      'notFoundIDs=${response.notFoundIDs} '
      'error=${queryError != null ? '${queryError.code}: ${queryError.message}' : 'none'}',
    );
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
      subscriptionLog(
        'initStore: product loaded id=${_product!.id} price=${_product!.price}',
      );
    } else {
      subscriptionLog('initStore: no product details returned');
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
      _session.updateSignedInRecipeGenerationUsage(
        profile.recipeGenerationUsage,
      );
      applyProfileSubscription(profile.subscription);
    } catch (e, st) {
      subscriptionLog('refreshFromApi failed: $e');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      }
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
    subscriptionLog('subscribe: tap');
    if (kIsWeb) {
      _error = 'Subscriptions are available in the mobile app.';
      subscriptionLog('subscribe: blocked (web)');
      notifyListeners();
      return;
    }
    final user = _auth.currentUser;
    if (user == null || _session.isGuestMode()) {
      _error = 'Sign in to subscribe.';
      subscriptionLog(
        'subscribe: blocked (auth) user=${user?.uid} guest=${_session.isGuestMode()}',
      );
      notifyListeners();
      return;
    }
    if (!_storeAvailable || _product == null) {
      _error = 'Store is not available right now.';
      subscriptionLog(
        'subscribe: blocked (store) storeAvailable=$_storeAvailable '
        'productLoaded=${_product != null}',
      );
      notifyListeners();
      return;
    }
    _error = null;
    notifyListeners();
    final param = PurchaseParam(productDetails: _product!);
    subscriptionLog(
      'subscribe: calling buyNonConsumable product=${_product!.id}',
    );
    try {
      final started =
          await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
      subscriptionLog('subscribe: buyNonConsumable started=$started');
      if (!started) {
        _error = 'Could not start purchase. Please try again.';
        notifyListeners();
      }
    } catch (e, st) {
      subscriptionLog('subscribe: buyNonConsumable exception: $e');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      }
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (kIsWeb) return;
    subscriptionLog('restorePurchases: start');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await InAppPurchase.instance.restorePurchases();
      subscriptionLog('restorePurchases: request sent');
    } catch (e, st) {
      subscriptionLog('restorePurchases failed: $e');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      }
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Redeem a backend promo code for free Premium (friends & family / campaigns).
  /// Returns true on success.
  Future<bool> redeemPromoCode(String code) async {
    final trimmed = code.trim();
    subscriptionLog('redeemPromoCode: start');
    final user = _auth.currentUser;
    if (user == null || _session.isGuestMode()) {
      _error = 'Sign in to redeem a promo code.';
      subscriptionLog('redeemPromoCode: blocked (auth)');
      notifyListeners();
      return false;
    }
    if (trimmed.isEmpty) {
      _error = 'Enter a promo code.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await user.getIdToken();
      final result = await _api.redeemPromoCode(code: trimmed, idToken: token);
      final sub = result['subscription'];
      if (sub is Map) {
        applyProfileSubscription(Map<String, dynamic>.from(sub));
      } else {
        await refreshFromApi();
      }
      _loading = false;
      _error = null;
      subscriptionLog('redeemPromoCode: success');
      await _telemetry.logPremiumPromoRedeemResult(result: 'success');
      notifyListeners();
      return true;
    } catch (e, st) {
      subscriptionLog('redeemPromoCode failed: $e');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      }
      _loading = false;
      if (e is ApiException) {
        _error = e.message;
        await _telemetry.logPremiumPromoRedeemResult(
          result: 'error',
          errorCode: e.code ?? 'redeem_failed',
        );
      } else {
        _error = e.toString();
        await _telemetry.logPremiumPromoRedeemResult(
          result: 'error',
          errorCode: 'redeem_failed',
        );
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    subscriptionLog('purchaseUpdates: count=${purchases.length}');
    for (final purchase in purchases) {
      subscriptionLog(
        'purchaseUpdates: product=${purchase.productID} '
        'status=${purchase.status.name} '
        'pendingComplete=${purchase.pendingCompletePurchase}',
      );
      if (purchase.productID != MonetizationConfig.standardProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          subscriptionLog('purchaseUpdates: pending');
          _loading = true;
          notifyListeners();
          break;
        case PurchaseStatus.error:
          _loading = false;
          final code = purchase.error?.code ?? '';
          subscriptionLog(
            'purchaseUpdates: error code=$code '
            'message=${purchase.error?.message}',
          );
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
          subscriptionLog('purchaseUpdates: canceled');
          _loading = false;
          _error = null;
          await _telemetry.logPremiumPurchaseResult(result: 'cancel');
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          subscriptionLog('purchaseUpdates: ${purchase.status.name} → verify');
          _loading = true;
          notifyListeners();
          await _verifyWithBackend(purchase);
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
            subscriptionLog('purchaseUpdates: completePurchase done');
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
    if (user == null) {
      subscriptionLog('verifyWithBackend: skipped (no user)');
      return;
    }
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    subscriptionLog('verifyWithBackend: start platform=$platform');
    try {
      final token = await user.getIdToken();
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
      subscriptionLog('verifyWithBackend: success');
      await _telemetry.logPremiumPurchaseResult(result: 'success');
      notifyListeners();
    } catch (e, st) {
      subscriptionLog('verifyWithBackend failed: $e');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      }
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
