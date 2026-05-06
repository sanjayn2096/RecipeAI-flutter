import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'pantry_captured_photo.dart';

/// Photo pick for iOS/Android/desktop (dart:io) via plugin.
Future<PantryCapturedPhoto?> pickPantryPhoto(ImageSource source) async {
  final picker = ImagePicker();
  final x = await picker.pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 82,
  );
  if (x == null) return null;
  final Uint8List bytes = await x.readAsBytes();
  final pathLower = x.path.toLowerCase();
  final mime =
      x.mimeType ?? (pathLower.endsWith('.png') ? 'image/png' : 'image/jpeg');
  return PantryCapturedPhoto(bytes: bytes, mimeType: mime);
}
