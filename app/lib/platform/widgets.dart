import 'package:flutter/services.dart';

/// Android home screen widgets: the numbers they show, a preview from the same
/// renderer, pinning, and the tap that opened the app.
class HomeWidgets {
  static const _ch = MethodChannel('app.sweeep/widgets');

  /// Plain values and already translated texts; no photos, no names.
  static Future<void> save(Map<String, Object?> snapshot) async {
    try {
      await _ch.invokeMethod<bool>('save', snapshot);
    } on MissingPluginException {
      // not on Android
    }
  }

  /// 'open', 'space' or 'session:N', once; null when nothing was tapped.
  static Future<String?> takeAction() async {
    try {
      return await _ch.invokeMethod<String>('takeAction');
    } on MissingPluginException {
      return null;
    }
  }

  /// Called when a widget is tapped while the app is already open.
  static void onAction(void Function() cb) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'action') cb();
      return null;
    });
  }

  static Future<Uint8List?> preview(String kind,
      {required double w,
      required double h,
      double density = 3,
      bool empty = false}) async {
    try {
      return await _ch.invokeMethod<Uint8List>('render',
          {'kind': kind, 'w': w, 'h': h, 'density': density, 'empty': empty});
    } on MissingPluginException {
      return null;
    }
  }

  static Future<bool> isAdded(String kind) async {
    try {
      return await _ch.invokeMethod<bool>('isAdded', {'kind': kind}) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Asks the launcher to place the widget; false when it cannot do that.
  static Future<bool> pin(String kind) async {
    try {
      return await _ch.invokeMethod<bool>('pin', {'kind': kind}) ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
