import '../../data/api/api_service.dart';
import 'pantry_image_analyzer.dart';
import 'pantry_image_analyzer_cloud.dart';

/// Cloud Claude via POST analyze-pantry-image on all platforms.
/// On-device iOS/Android analyzers remain in the tree for easy rollback.
PantryImageAnalyzer createPantryImageAnalyzerImpl(ApiService apiService) {
  return CloudPantryImageAnalyzer(apiService);
}
