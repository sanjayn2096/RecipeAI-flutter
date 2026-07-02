import 'dart:io' show Platform;

import '../../data/api/api_service.dart';
import 'pantry_image_analyzer.dart';
import 'pantry_image_analyzer_android.dart';
import 'pantry_image_analyzer_cloud.dart';
import 'pantry_image_analyzer_ios.dart';

PantryImageAnalyzer createPantryImageAnalyzerImpl(ApiService apiService) {
  if (Platform.isIOS) return OnDeviceIosPantryImageAnalyzer();
  if (Platform.isAndroid) return OnDeviceAndroidPantryImageAnalyzer();
  return CloudPantryImageAnalyzer(apiService);
}
