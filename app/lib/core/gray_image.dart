import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Expands an 8-bit grayscale buffer into a [ui.Image] (for debug previews).
Future<ui.Image> grayToImage(Uint8List gray, int width, int height) {
  final rgba = Uint8List(width * height * 4);
  for (var i = 0; i < width * height; i++) {
    final v = gray[i];
    final o = i * 4;
    rgba[o] = v;
    rgba[o + 1] = v;
    rgba[o + 2] = v;
    rgba[o + 3] = 255;
  }
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}
