import 'dart:typed_data';

/// Result of capturing or selecting a pantry/fridge photo.
class PantryCapturedPhoto {
  const PantryCapturedPhoto({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;
}
