import 'dart:convert';
import 'dart:typed_data';

import '../../data/api/api_service.dart';
import 'pantry_image_analyzer.dart';
import 'pantry_scan_suggestion.dart';

/// Cloud Claude vision via POST analyze-pantry-image (all platforms).
class CloudPantryImageAnalyzer implements PantryImageAnalyzer {
  CloudPantryImageAnalyzer(this._apiService);

  final ApiService _apiService;

  @override
  bool get isOnDevice => false;

  @override
  Future<PantryAnalyzeResult> analyze({
    required Uint8List bytes,
    required String mimeType,
    String? idToken,
  }) async {
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Sign in required for cloud pantry scan.');
    }
    final response = await _apiService.analyzePantryImage(
      imageBase64: base64Encode(bytes),
      mimeType: mimeType,
      idToken: idToken,
    );
    return PantryAnalyzeResult(
      suggestions: PantryScanSuggestion.fromApiItems(response.items),
      quota: response.quota,
    );
  }
}
