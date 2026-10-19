import 'package:flutter/services.dart';

/// Talks to `TonePlugin.kt`: a local sine generator (no files, no network).
class ToneService {
  const ToneService();

  static const _ch = MethodChannel('app.sweeep/tone');

  /// [side]: 0 both speakers, 1 left, 2 right.
  Future<void> start({required double freq, bool pulse = false, bool sweep = false, int side = 0}) =>
      _ch.invokeMethod('start', {'freq': freq, 'pulse': pulse, 'sweep': sweep, 'side': side});

  Future<void> update({double? freq, bool? pulse, bool? sweep, int? side}) => _ch.invokeMethod('update', {
        if (freq != null) 'freq': freq,
        if (pulse != null) 'pulse': pulse,
        if (sweep != null) 'sweep': sweep,
        if (side != null) 'side': side,
      });

  Future<void> stop() => _ch.invokeMethod('stop');
}
