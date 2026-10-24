import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/moments_algo.dart';
import 'package:sweeep/index/moments_service.dart';

void main() {
  late SweeepDatabase db;
  late MomentsService svc;
  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    svc = MomentsService(db);
  });
  tearDown(() => db.close());

  var n = 0;
  Future<void> shots(DateTime start, int count, {int stepMin = 5, double? lat, double? lon, bool screenshot = false}) async {
    for (var i = 0; i < count; i++) {
      final t = start.add(Duration(minutes: stepMin * i)).millisecondsSinceEpoch;
      await db.into(db.assets).insert(AssetsCompanion.insert(
            id: 'a${n++}',
            mediaType: 0,
            width: 1,
            height: 1,
            sizeBytes: 100,
            createdAtMs: t,
            modifiedAtMs: t,
            isScreenshot: Value(screenshot),
            lat: Value(lat),
            lon: Value(lon),
            geoState: Value(lat == null ? 0 : 1),
          ));
    }
  }

  test('events come from time alone and screenshots never join', () async {
    await shots(DateTime(2026, 6, 6, 10), 14);
    await shots(DateTime(2026, 6, 6, 10, 1), 30, screenshot: true);
    await shots(DateTime(2026, 6, 20, 10), 5); // too few
    expect(await svc.recompute(), 1);
    final e = (await svc.list()).single;
    expect(e.count, 14);
    expect(e.title, 'w_weekend');
    expect(e.awayKm, isNull);
  });

  test('places turn names into trips and weekends once the home is known', () async {
    await db.into(db.scanState).insert(ScanStateCompanion.insert(key: MomentsService.placesKey, value: '1'));
    await shots(DateTime(2026, 5, 1, 23), 40, stepMin: 1, lat: 53.9, lon: 27.56); // nights at home
    await shots(DateTime(2026, 5, 3, 10), 15, lat: 41.9, lon: 12.5);
    await svc.recompute();
    final titles = [for (final e in await svc.list()) e.title];
    expect(titles.any((t) => t.startsWith('trip:1:')), isTrue);
  });

  test('turning places off wipes every stored coordinate', () async {
    await db.into(db.scanState).insert(ScanStateCompanion.insert(key: MomentsService.placesKey, value: '1'));
    await shots(DateTime(2026, 5, 3, 10), 15, lat: 41.9, lon: 12.5);
    await svc.setPlaces(false);
    final r = await db.customSelect('SELECT COUNT(*) AS n FROM assets WHERE lat IS NOT NULL OR lon IS NOT NULL OR geo_state != 0').getSingle();
    expect(r.read<int>('n'), 0);
    expect(await svc.placesOn(), isFalse);
  });

  test('new photos only rebuild the tail, old events keep their ids', () async {
    await shots(DateTime(2026, 6, 1, 10), 14);
    await shots(DateTime(2026, 6, 3, 10), 14);
    await shots(DateTime(2026, 6, 5, 10), 14);
    await svc.recompute();
    final before = {for (final e in await svc.list()) e.startMs: e.id};
    expect(before.length, 3);
    await shots(DateTime(2026, 6, 9, 10), 13);
    await svc.recompute();
    final after = {for (final e in await svc.list()) e.startMs: e.id};
    expect(after.length, 4);
    final oldest = before.keys.reduce((a, b) => a < b ? a : b);
    expect(after[oldest], before[oldest]); // not rebuilt
  });

  test('a changed algorithm version or old photos appearing rebuild everything', () async {
    await shots(DateTime(2026, 6, 3, 10), 14);
    await shots(DateTime(2026, 6, 5, 10), 14);
    await svc.recompute();
    final firstId = (await svc.list()).last.id;
    await shots(DateTime(2026, 1, 3, 10), 13); // an old backup shows up
    await svc.recompute();
    final events = await svc.list();
    expect(events.length, 3);
    expect(events.last.id == firstId, isFalse);
    await db.into(db.scanState).insertOnConflictUpdate(ScanStateCompanion.insert(key: 'events_algo', value: '0'));
    await svc.recompute();
    expect((await svc.list()).length, 3);
  });

  test('rename sticks and a blank name goes back to the generated one', () async {
    await shots(DateTime(2026, 6, 3, 10), 14);
    await svc.recompute();
    final id = (await svc.list()).single.id;
    await svc.rename(id, '  Lake  ');
    expect((await svc.byId(id))!.userTitle, 'Lake');
    await svc.rename(id, '   ');
    expect((await svc.byId(id))!.userTitle, isNull);
  });

  test('near-twins and best frames count similar groups inside the event', () async {
    await shots(DateTime(2026, 6, 3, 10), 14);
    await svc.recompute();
    final ev = await svc.list();
    final ids = (await (db.select(db.eventMembers)).get()).map((m) => m.assetId).take(4).toList();
    final g = await db.into(db.groups).insert(GroupsCompanion.insert(kind: 1, savingsBytes: 1, createdAtMs: 1, bestAssetId: Value(ids.first)));
    for (final a in ids) {
      await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g, assetId: a));
    }
    final v = (await svc.byId(ev.single.id))!;
    expect((v.best, v.twins), (1, 3));
    expect(v.tiles.isNotEmpty, isTrue);
  });

  test('upgrading from schema 4 adds the place columns and the event tables, keeping the photos', () async {
    final dir = Directory.systemTemp.createTempSync('sweeep_moments');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var first = SweeepDatabase(NativeDatabase(file));
    await first.select(first.assets).get();
    await first.customStatement('DROP TABLE event_members');
    await first.customStatement('DROP TABLE events');
    await first.customStatement('ALTER TABLE assets DROP COLUMN lat');
    await first.customStatement('ALTER TABLE assets DROP COLUMN lon');
    await first.customStatement('ALTER TABLE assets DROP COLUMN geo_state');
    await first.customStatement(
        "INSERT INTO assets (id, media_type, width, height, size_bytes, created_at_ms, modified_at_ms, is_screenshot, is_screen_recording) VALUES ('x', 0, 1, 1, 5, 1, 1, 0, 0)");
    await first.customStatement('PRAGMA user_version = 4');
    await first.close();

    first = SweeepDatabase(NativeDatabase(file));
    final a = await first.select(first.assets).getSingle();
    expect((a.id, a.lat, a.lon, a.geoState), ('x', null, null, 0));
    expect(await first.select(first.events).get(), isEmpty);
    await first.close();
  });

  test('config thresholds are the agreed ones', () {
    expect(MomentsConfig.gap, const Duration(hours: 4));
    expect(MomentsConfig.minPhotos, 12);
    expect(MomentsConfig.awayKm, 50);
    expect(MomentsConfig.tripGap, const Duration(hours: 18));
  });
}
