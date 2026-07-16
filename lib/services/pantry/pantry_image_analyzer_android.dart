import 'dart:io' show Directory, File;
import 'dart:typed_data';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'pantry_image_analyzer.dart';
import 'pantry_label_mapper.dart';
import 'pantry_vision_merge.dart';
import 'pantry_vision_raw.dart';

/// On-device ML Kit pipeline mirroring the iOS Vision approach.
class OnDeviceAndroidPantryImageAnalyzer implements PantryImageAnalyzer {
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

    final ext = mimeType.toLowerCase().contains('png') ? 'png' : 'jpg';
    final f = File(
      '${Directory.systemTemp.path}/pantry_scan_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await f.writeAsBytes(bytes);

    try {
      final input = InputImage.fromFilePath(f.path);

      final classifications = <PantryVisionClassification>[];
      final ocrLines = <String>[];
      final barcodes = <String>[];

      final labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.35),
      );
      try {
        final labels = await labeler.processImage(input);
        for (final label in labels) {
          final mapped = PantryLabelMapper.mapMlKitLabel(
            label.label,
            label.confidence,
          );
          if (mapped != null) {
            classifications.add(
              PantryVisionClassification(
                identifier: label.label,
                confidence: mapped.confidence,
              ),
            );
          }
        }
      } finally {
        await labeler.close();
      }

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final textResult = await recognizer.processImage(input);
        for (final block in textResult.blocks) {
          final line = block.text.trim();
          if (line.length >= 3) ocrLines.add(line);
        }
      } finally {
        await recognizer.close();
      }

      final scanner = BarcodeScanner(formats: const [BarcodeFormat.all]);
      try {
        final codes = await scanner.processImage(input);
        for (final code in codes) {
          final value = code.displayValue?.trim();
          if (value != null && value.isNotEmpty) barcodes.add(value);
        }
      } finally {
        await scanner.close();
      }

      final raw = PantryVisionRawResult(
        classifications: classifications,
        ocrLines: ocrLines,
        barcodes: barcodes,
      );
      return PantryAnalyzeResult(
        suggestions: PantryVisionMerge.toSuggestions(raw),
      );
    } finally {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
