import 'dart:typed_data';

import '../../data/api/api_service.dart';
import '../../data/models/pantry_scan_quota.dart';
import 'pantry_image_analyzer_stub.dart'
    if (dart.library.io) 'pantry_image_analyzer_impl.dart';
import 'pantry_scan_suggestion.dart';

/// Result of pantry/fridge photo analysis.
class PantryAnalyzeResult {
  const PantryAnalyzeResult({
    required this.suggestions,
    this.quota,
  });

  final List<PantryScanSuggestion> suggestions;
  final PantryScanQuota? quota;
}

/// Analyzes pantry/fridge photos into grocery line suggestions.
abstract class PantryImageAnalyzer {
  Future<PantryAnalyzeResult> analyze({
    required Uint8List bytes,
    required String mimeType,
    String? idToken,
  });

  /// Whether analysis runs fully on-device (no network).
  bool get isOnDevice;
}

/// Cloud Claude analyzer (POST analyze-pantry-image) on all platforms.
PantryImageAnalyzer createPantryImageAnalyzer(ApiService apiService) =>
    createPantryImageAnalyzerImpl(apiService);
