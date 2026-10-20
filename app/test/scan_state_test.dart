import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/providers.dart';

void main() {
  test('phase follows the stage that is running', () {
    expect(const LibraryState(syncing: true).phase, 0);
    expect(const LibraryState(analyzing: true).phase, 1);
    expect(const LibraryState(verifying: true).phase, 2);
    expect(const LibraryState(verifying: true, grouping: true).phase, 3);
    expect(const LibraryState().phase, 4);
  });

  test('a paused scan remembers which stage it stopped in', () {
    expect(const LibraryState(paused: true, analysisDone: 10, analysisTotal: 100).phase, 1);
    expect(const LibraryState(paused: true, analysisDone: 100, analysisTotal: 100).phase, 2);
  });

  test('progress only moves forward through the stages', () {
    final reading = const LibraryState(syncing: true).progress;
    final earlyHash = const LibraryState(analyzing: true, analysisDone: 10, analysisTotal: 100).progress;
    final lateHash = const LibraryState(analyzing: true, analysisDone: 100, analysisTotal: 100).progress;
    final compare = const LibraryState(verifying: true, verifyDone: 5, verifyTotal: 10).progress;
    final group = const LibraryState(verifying: true, grouping: true).progress;
    final done = const LibraryState().progress;
    final all = [reading, earlyHash, lateHash, compare, group, done];
    for (var i = 1; i < all.length; i++) {
      expect(all[i], greaterThan(all[i - 1]), reason: 'step $i');
    }
    expect(done, 1);
  });

  test('already hashed files count towards progress when a scan resumes', () {
    const resumed = LibraryState(analyzing: true, alreadyHashed: 900, analysisDone: 50, analysisTotal: 100);
    const fresh = LibraryState(analyzing: true, analysisDone: 50, analysisTotal: 100);
    expect(resumed.progress, greaterThan(fresh.progress));
  });
}
