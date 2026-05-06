import 'dart:typed_data';

/// Web / unsupported: no on-device OCR in this build.
Future<String?> recognizeRecipeTextFromBytes(
  Uint8List bytes,
  String mimeType,
) async =>
    null;
