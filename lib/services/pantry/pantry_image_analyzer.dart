import 'dart:typed_data';

import '../../data/api/api_service.dart';
import 'pantry_image_analyzer_stub.dart'
    if (dart.library.io) 'pantry_image_analyzer_impl.dart';
import 'pantry_scan_suggestion.dart';

/// Analyzes pantry/fridge photos into grocery line suggestions.
abstract class PantryImageAnalyzer {
  Future<List<PantryScanSuggestion>> analyze({
    required Uint8List bytes,
    required String mimeType,
    String? idToken,
  });

  /// Whether analysis runs fully on-device (no network).
  bool get isOnDevice;
}

/// Platform-appropriate analyzer: on-device on iOS/Android, cloud elsewhere.
PantryImageAnalyzer createPantryImageAnalyzer(ApiService apiService) =>
    createPantryImageAnalyzerImpl(apiService);
