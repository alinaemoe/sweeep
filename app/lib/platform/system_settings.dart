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
}
