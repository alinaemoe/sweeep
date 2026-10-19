import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/core/native_core.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/group_service.dart';
import 'package:sweeep/index/home_service.dart';
import 'package:sweeep/platform/media_source.dart';

class _Media implements MediaSource {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Core implements AnalysisCore {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  late SweeepDatabase db;
  late HomeService home;
  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    home = HomeService(db, GroupService(db, _Media(), _Core()));
  });
  tearDown(() => db.close());

  Future<void> add(String id,
      {int type = 0, int size = 100, int created = 0, bool shot = false, int? dur, double? lap, int? bright}) async {
    await db.into(db.assets).insert(AssetsCompanion.insert(
          id: id,
          mediaType: type,
          width: 10,
          height: 10,
          sizeBytes: size,
          createdAtMs: created,
          modifiedAtMs: created,
          isScreenshot: Value(shot),
          durationMs: Value(dur),
        ));
    if (lap != null || bright != null) {
      await db.into(db.hashes).insert(HashesCompanion.insert(
            assetId: id,
            analyzedAtMs: 1,
            analysisVersion: 1,
            laplacianVar: Value(lap),
            medianBrightness: Value(bright),
          ));
    }
  }

  test('empty library gives empty categories', () async {
    final d = await home.load();
    expect(d.libraryCount, 0);
    expect(d.reclaimableBytes, 0);
    expect(d.screenshots.count, 0);
    expect(d.videos.items, isEmpty);
    expect(d.blurry.count, 0);
  });

  test('categories count, sum and skip trashed items', () async {
    await add('s1', shot: true, size: 10, created: 2);
    await add('s2', shot: true, size: 20, created: 1);
    await add('v1', type: 1, size: 500, dur: 61000);
    await add('v2', type: 1, size: 900, dur: 5000);
    await add('sharp', lap: 900, bright: 120);
    await add('soft', lap: 100, bright: 120, size: 7);
    await add('night', lap: 900, bright: 10, size: 3);
    await db.into(db.trashItems).insert(TrashItemsCompanion.insert(assetId: 's2', sizeBytes: 20, trashedAtMs: 1, expiresAtMs: 2, reason: 0));

    final d = await home.load();
    expect(d.libraryCount, 7);
    expect(d.screenshots.count, 1); // s2 is trashed
    expect(d.screenshots.bytes, 10);
    expect(d.videos.count, 2);
    expect(d.videos.items.first.id, 'v2'); // biggest first
    expect(d.videos.items.last.durationMs, 61000);
    expect(d.blurry.count, 2);
    expect(d.blurry.bytes, 10);
    expect({for (final i in d.blurry.items) i.id: i.tag}, {'soft': 'blurry', 'night': 'dark'});
  });
}
