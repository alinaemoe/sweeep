import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Android foreground service that keeps a long scan alive while the app is
/// in the background (see `ScanService.kt`). Every call is best effort: on
/// other platforms, or if the OS refuses, the scan simply runs in-app.
class ScanForeground {
  ScanForeground();

  static const _ch = MethodChannel('app.sweeep/scan');
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> start() => _call('start', {'text': l10n.notifStart});

  /// Throttled to about one notification update per second.
  Future<void> update(int done, int total, String text) {
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < 1000 && done < total) return Future.value();
    _last = now;
    return _call('update', {'done': done, 'total': total, 'text': text});
  }

  Future<void> stop() => _call('stop');

  Future<void> _call(String method, [Map<String, Object?>? args]) async {
    try {
      await _ch.invokeMethod<void>(method, args == null ? null : {...args, 'title': l10n.notifTitle, 'channel': l10n.notifChannel});
    } on MissingPluginException {
      // not Android / plugin absent (tests)
    } on PlatformException {
      // the scan carries on without the service
    }
  }
}
