import 'package:image_picker/image_picker.dart';

import 'pantry_captured_photo.dart';
import 'pantry_pick_photo_io.dart'
    if (dart.library.html) 'pantry_pick_photo_web.dart' as impl;

/// Picks pantry photo bytes; uses plugin on native and HTML `<input>` on web
/// so mobile browsers (Safari / Chrome-on-iOS) do not rely on broken
/// [ImagePicker] registrations.
Future<PantryCapturedPhoto?> pickPantryPhoto(ImageSource source) =>
    impl.pickPantryPhoto(source);
