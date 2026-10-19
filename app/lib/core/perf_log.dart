import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Profile-build only: prints a frame-time summary to logcat every ~2 s
/// (`adb logcat -s flutter | grep SWEEEP_PERF`). Does nothing in debug/release.
void startPerfLog() {
  if (!kProfileMode) return;
  var frames = 0, slowBuild = 0, slowRaster = 0;
  var worstBuild = 0.0, worstRaster = 0.0;
  var last = DateTime.now();
  SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
    for (final t in timings) {
      final b = t.buildDuration.inMicroseconds / 1000, r = t.rasterDuration.inMicroseconds / 1000;
      frames++;
      if (b > 16.7) slowBuild++;
      if (r > 16.7) slowRaster++;
      if (b > worstBuild) worstBuild = b;
      if (r > worstRaster) worstRaster = r;
    }
    final now = DateTime.now();
    if (now.difference(last).inMilliseconds >= 2000) {
      debugPrint('SWEEEP_PERF frames=$frames slowBuild=$slowBuild slowRaster=$slowRaster worstBuild=${worstBuild.toStringAsFixed(1)}ms worstRaster=${worstRaster.toStringAsFixed(1)}ms');
      frames = slowBuild = slowRaster = 0;
      worstBuild = worstRaster = 0;
      last = now;
    }
  });
}
