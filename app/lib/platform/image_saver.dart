
import 'package:flutter/services.dart';

/// Writes a PNG the app made itself into the gallery (Pictures/Sweeep).
/// Returns where it went, or null when saving was not possible.
class ImageSaver {
  static const _ch = MethodChannel('app.sweeep/imagesaver');

  static Future<String?> savePng(Uint8List bytes, String name) async {
    try {
      return await _ch.invokeMethod<String>('savePng', {'bytes': bytes, 'name': name});
    } on MissingPluginException {
      return null;
    }
  }
}
