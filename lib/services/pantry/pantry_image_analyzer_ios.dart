import 'package:flutter/services.dart';

import 'pantry_image_analyzer.dart';
import 'pantry_vision_merge.dart';
import 'pantry_vision_raw.dart';

/// On-device Apple Vision pipeline (classify + OCR + barcode + saliency regions).
class OnDeviceIosPantryImageAnalyzer implements PantryImageAnalyzer {
  static const _channel = MethodChannel('com.recipeai/pantry_vision');

  @override
  bool get isOnDevice => true;

  @override
  Future<PantryAnalyzeResult> analyze({
    required Uint8List bytes,
    required String mimeType,
    String? idToken,
  }) async {
    if (bytes.isEmpty) {
      return const PantryAnalyzeResult(suggestions: []);
    }

    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'analyzePantryImage',
      <String, Object>{
        'bytes': bytes,
        'mimeType': mimeType,
      },
    );

    if (result == null) {
      return const PantryAnalyzeResult(suggestions: []);
    }

    final raw = PantryVisionRawResult.fromJson(
      Map<String, dynamic>.from(result),
    );
    return PantryAnalyzeResult(
      suggestions: PantryVisionMerge.toSuggestions(raw),
    );
  }
}
