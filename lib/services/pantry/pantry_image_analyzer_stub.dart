import '../../data/api/api_service.dart';
import 'pantry_image_analyzer.dart';
import 'pantry_image_analyzer_cloud.dart';

PantryImageAnalyzer createPantryImageAnalyzerImpl(ApiService apiService) =>
    CloudPantryImageAnalyzer(apiService);
