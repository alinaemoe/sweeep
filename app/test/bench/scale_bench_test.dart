// Scale benchmark: how the Dart/SQLite side behaves on 50k and 100k photos.
//
// Not part of the normal test run. Start it with
//   BENCH=1 flutter test test/bench
// (PowerShell: $env:BENCH=1; flutter test test/bench)
//
// It builds a synthetic library in an in-memory Drift database (same schema
// as the app), then times every query behind Home, Swipe/Timeline, Groups and
// the scan's group-building step. Rust hashing and the platform thumbnail
// calls are not part of this; they are measured on the phone (see
// docs/benchmarks.md). Numbers are from the dev machine: a phone is
// roughly 3-5x slower, so keep generous headroom.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/core/native_core.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/analysis_service.dart';
import 'package:sweeep/index/group_service.dart';
import 'package:sweeep/index/home_service.dart';
import 'package:sweeep/index/review_service.dart';
import 'package:sweeep/platform/media_source.dart';

class _NoMedia implements MediaSource {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

/// Groups by exact hash equality (stand-in for the Rust grouping, which is
/// benchmarked separately in core/).
class _EqualHashCore implements AnalysisCore {
  @override
  Analysis? analyze(Uint8List gray, int width, int height) => null;
  @override
  GroupLabels groupSimilar(List<int> hashes, List<int> timestampsMs, {int maxHamming = 6, int windowMs = 5000}) {
    final byHash = <int, List<int>>{};
    for (var i = 0; i < hashes.length; i++) {
      byHash.putIfAbsent(hashes[i], () => []).add(i);
    }
    final labels = Int32List(hashes.length)..fillRange(0, hashes.length, -1);
    var g = 0;
    for (final idx in byHash.values.where((v) => v.length > 1)) {
      for (final i in idx) {
        labels[i] = g;
      }
      g++;
    }
    return GroupLabels(g, labels);
  }
}

Future<void> _seed(SweeepDatabase db, int n) async {
  final rnd = Random(42);
  final now = DateTime(2026, 10, 20).millisecondsSinceEpoch;
  const sixYearsSec = 6 * 365 * 24 * 3600;
  final assets = <AssetsCompanion>[];
  final hashes = <HashesCompanion>[];
  var clusterHash = 0;
  var clusterLeft = 0;
  var clusterT = 0;
  Uint8List? dupDigest;
  var dupSize = 0;
  var dupT = 0;

  Future<void> flush() async {
    await db.batch((b) {
      b.insertAll(db.assets, assets);
      b.insertAll(db.hashes, hashes);
    });
    assets.clear();
    hashes.clear();
  }

  for (var i = 0; i < n; i++) {
    final video = i % 20 == 0;
    final shot = !video && i % 10 == 3;
    final chat = i % 33 == 0;
    var t = now - rnd.nextInt(sixYearsSec) * 1000;
    var size = 200000 + rnd.nextInt(5800000);
    Uint8List? digest;

    var phash = rnd.nextInt(1 << 32) << 21 ^ rnd.nextInt(1 << 32);
    if (!video) {
      if (clusterLeft > 0) {
        // member of a burst: same look, a second or so apart
        phash = clusterHash;
        t = clusterT + (7 - clusterLeft) * 900;
        clusterLeft--;
      } else if (i % 17 == 0) {
        clusterHash = phash;
        clusterLeft = 1 + rnd.nextInt(5);
        clusterT = t;
      } else if (dupDigest != null && i % 71 == 1) {
        size = dupSize; // exact copy of the previous 71st photo
        digest = dupDigest;
        t = dupT + 60000;
        dupDigest = null;
      } else if (i % 71 == 0) {
        dupSize = size;
        dupT = t;
        dupDigest = Uint8List.fromList(List.filled(32, 1 + rnd.nextInt(250)));
        digest = dupDigest;
      }
    }

    assets.add(AssetsCompanion.insert(
      id: 'a$i',
      mediaType: video ? 1 : 0,
      width: 4000,
      height: 3000,
      sizeBytes: size,
      createdAtMs: t,
      modifiedAtMs: t,
      durationMs: Value(video ? 5000 + rnd.nextInt(120000) : null),
      bucket: const Value('Camera'),
      isScreenshot: Value(shot),
      chatSource: Value(chat ? 'whatsapp' : null),
    ));
    hashes.add(HashesCompanion.insert(
      assetId: 'a$i',
      analyzedAtMs: now,
      analysisVersion: AnalysisService.version,
      phash: Value(video ? null : phash),
      laplacianVar: Value(video ? null : rnd.nextDouble() * 1500),
      medianBrightness: Value(video ? null : rnd.nextInt(256)),
      sha256: Value(digest),
    ));
    if (assets.length >= 5000) await flush();
  }
  await flush();
}

void main() {
  if (Platform.environment['BENCH'] != '1') {
    test('scale benchmark (set BENCH=1 to run)', () {}, skip: 'run with BENCH=1');
    return;
  }

  for (final n in [50000, 100000]) {
    test('scale $n', () async {
      final db = SweeepDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final out = StringBuffer('\n=== $n assets ===\n');
      Future<T> time<T>(String name, Future<T> Function() f) async {
        final sw = Stopwatch()..start();
        final r = await f();
        out.writeln('${name.padRight(34)} ${sw.elapsedMilliseconds.toString().padLeft(6)} ms');
        return r;
      }

      await time('seed (assets + hashes)', () => _seed(db, n));
      if (Platform.environment['BENCH_INDEX'] == '1') {
        await time('create indexes', () async {
          await db.customStatement('CREATE INDEX IF NOT EXISTS idx_assets_type_created ON assets(media_type, created_at_ms)');
          await db.customStatement('CREATE INDEX IF NOT EXISTS idx_assets_screenshot ON assets(is_screenshot, created_at_ms)');
          await db.customStatement('CREATE INDEX IF NOT EXISTS idx_assets_size ON assets(size_bytes)');
          await db.customStatement('CREATE INDEX IF NOT EXISTS idx_assets_chat ON assets(chat_source)');
        });
      }

      final groups = GroupService(db, _NoMedia(), _EqualHashCore());
      final analysis = AnalysisService(db, _NoMedia(), _EqualHashCore());
      final home = HomeService(db, groups);
      final review = ReviewService(db);

      await time('pendingCount', analysis.pendingCount);
      await time('exactCandidates', groups.exactCandidates);
      final built = await time('rebuild groups (cold)', groups.rebuild);
      out.writeln('  -> ${built.exactGroups} exact, ${built.similarGroups} similar groups');
      await time('rebuild groups (nothing changed)', groups.rebuild);
      await time('groups(similar)', () => groups.groups(GroupKind.similar));
      await time('groups(duplicate)', () => groups.groups(GroupKind.duplicate));
      await time('trashSummary', groups.trashSummary);
      await time('Home load', home.load);
      await time('Home load (2nd)', home.load);
      final months = await time('Timeline months()', review.months);
      out.writeln('  -> ${months.length} months');
      await time('queue(all)', () => review.queue(SwipeSource.all));
      await time('queue(all, newest month)', () => review.queue(SwipeSource.all, month: months.first.key));
      await time('queue(blurry & dark)', () => review.queue(SwipeSource.blurry));
      await time('category(videos)', () => review.category(CategoryKind.videos));
      await time('category(screenshots)', () => review.category(CategoryKind.screenshots));
      await time('category(chat)', () => review.category(CategoryKind.chat));

      // keep the numbers visible even when flutter test is quiet
      // ignore: avoid_print
      print(out);
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
