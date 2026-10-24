import 'package:flutter/services.dart';

/// Where photos were taken. Reads the originals on the phone (ACCESS_MEDIA_LOCATION);
/// no network, no map service.
class Places {
  static const _ch = MethodChannel('app.sweeep/places');

  static Future<bool> hasPermission() async {
    try {
      return await _ch.invokeMethod<bool>('hasPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Asks Android for the permission; true when it is granted.
  static Future<bool> request() async {
    try {
      return await _ch.invokeMethod<bool>('request') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// id -> [lat, lon] for the photos that have a place; the others are left out.
  static Future<Map<String, List<double>>> read(List<String> ids) async {
    try {
      final m = await _ch.invokeMapMethod<String, List<Object?>>('read', {'ids': ids}) ?? const {};
      return {
        for (final e in m.entries) e.key: [for (final v in e.value) (v as num).toDouble()],
      };
    } on MissingPluginException {
      return const {};
    }
  }
}
