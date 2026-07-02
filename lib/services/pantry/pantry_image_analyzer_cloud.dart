import 'dart:convert';
import 'dart:typed_data';

import '../../data/api/api_service.dart';
import 'pantry_image_analyzer.dart';
import 'pantry_scan_suggestion.dart';

/// Cloud Gemini vision via POST analyze-pantry-image (Android/web fallback).
class CloudPantryImageAnalyzer implements PantryImageAnalyzer {
  CloudPantryImageAnalyzer(this._apiService);

  final ApiService _apiService;

  @override
  bool get isOnDevice => false;

  @override
  Future<List<PantryScanSuggestion>> analyze({
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
    return PantryScanSuggestion.fromApiItems(response.items);
  }
}
