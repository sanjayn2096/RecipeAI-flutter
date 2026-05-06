import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR (ML Kit, Android / iOS only). Returns combined plain text or null.
Future<String?> recognizeRecipeTextFromBytes(
  Uint8List bytes,
  String mimeType,
) async {
  if (!Platform.isAndroid && !Platform.isIOS) return null;
  if (bytes.isEmpty) return null;
  final ext = mimeType.toLowerCase().contains('png') ? 'png' : 'jpg';
  final f = File(
    '${Directory.systemTemp.path}/recipe_import_${DateTime.now().millisecondsSinceEpoch}.$ext',
  );
  await f.writeAsBytes(bytes);
  try {
    final input = InputImage.fromFilePath(f.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(input);
      final t = result.text.trim();
      return t.isEmpty ? null : t;
    } finally {
      await recognizer.close();
    }
  } finally {
    try {
      await f.delete();
    } catch (_) {}
  }
}
