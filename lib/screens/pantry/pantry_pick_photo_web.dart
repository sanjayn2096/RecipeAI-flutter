// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

// Web-only picker; mirrors image_picker_for_web host-injection pattern so WebKit works.

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart' show ImageSource;

import 'pantry_captured_photo.dart';

const String _pantryPhotoInputHostId = '__pantry_photo_input_host';

html.Element _ensureHost(html.Element body) {
  html.Element? existing =
      html.document.querySelector('#$_pantryPhotoInputHostId');
  if (existing != null) {
    return existing;
  }
  final host = html.document.createElement('flt-pantry-photo-inputs')
    ..id = _pantryPhotoInputHostId;
  body.append(host);
  return host;
}

html.File? _firstFile(html.FileUploadInputElement input) {
  final list = input.files;
  if (list == null || list.isEmpty) return null;
  return list[0];
}

/// WebKit may fire [cancel] when the camera/Gallery UI dismisses; completing
/// null immediately races [change] after "Use Photo" and drops the file.
/// Prefer [change] + deferred reads of [input.files].
Future<PantryCapturedPhoto?> pickPantryPhoto(ImageSource source) async {
  final body = html.document.body;
  if (body == null) return null;

  final host = _ensureHost(body);
  host.children.clear();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  if (source == ImageSource.camera) {
    input.setAttribute('capture', 'environment');
  }

  host.append(input);

  final completer = Completer<html.File?>();

  void tryPick() {
    if (completer.isCompleted) return;
    final f = _firstFile(input);
    if (f != null) completer.complete(f);
  }

  Timer? deferNull;
  void scheduleNullIfStillEmpty() {
    deferNull?.cancel();
    deferNull = Timer(const Duration(milliseconds: 450), () {
      tryPick();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
  }

  void onCancel(html.Event _) {
    scheduleMicrotask(() {
      html.window.requestAnimationFrame((_) {
        html.window.requestAnimationFrame((__) {
          tryPick();
          if (!completer.isCompleted) scheduleNullIfStillEmpty();
        });
      });
    });
  }

  final longTimeout = Timer(const Duration(seconds: 120), () {
    tryPick();
    if (!completer.isCompleted) completer.complete(null);
  });

  late final StreamSubscription<html.Event> sub;
  sub = input.onChange.listen((_) {
    tryPick();
    scheduleMicrotask(tryPick);
    html.window.requestAnimationFrame((_) => tryPick());
    Timer(const Duration(milliseconds: 120), tryPick);
  });

  input.addEventListener('cancel', onCancel);

  input.click();

  html.File? file;
  try {
    file = await completer.future;
  } finally {
    longTimeout.cancel();
    deferNull?.cancel();
    await sub.cancel();
    input.removeEventListener('cancel', onCancel);
    input.remove();
  }

  if (file == null) return null;

  final reader = html.FileReader()..readAsArrayBuffer(file);
  await reader.onLoad.first;
  final result = reader.result;
  if (result is! ByteBuffer) return null;
  final bytes = Uint8List.view(result);
  final trimmed = file.type.trim();
  final mime = trimmed.isEmpty ? 'image/jpeg' : trimmed;
  return PantryCapturedPhoto(bytes: bytes, mimeType: mime);
}
