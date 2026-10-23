import 'package:flutter/services.dart';

/// Opens this app's page in the system settings (photo access, notifications).
class SystemSettings {
  static const _ch = MethodChannel('app.sweeep/system');

  static Future<bool> openApp() async {
    try {
      return await _ch.invokeMethod<bool>('openAppSettings') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Percent of the phone's internal storage in use, or null when unknown.
  static Future<int?> usedPercent() async {
    try {
      final m = await _ch.invokeMapMethod<String, Object?>('storageStat');
      final total = (m?['total'] as num?)?.toInt() ?? 0;
      final free = (m?['free'] as num?)?.toInt() ?? 0;
      if (total <= 0) return null;
      return ((total - free) * 100 / total).round().clamp(0, 100);
    } on MissingPluginException {
      return null;
    }
  }
}
