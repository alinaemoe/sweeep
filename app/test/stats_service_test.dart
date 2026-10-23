import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/stats_service.dart';

void main() {
  late SweeepDatabase db;
  setUp(() => db = SweeepDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  int ms(int y, int m, int d, [int h = 12]) =>
      DateTime(y, m, d, h).millisecondsSinceEpoch;
  Future<void> asset(String id, {int size = 100, bool shot = false}) =>
      db.into(db.assets).insert(AssetsCompanion.insert(
          id: id,
          mediaType: 0,
          width: 1,
          height: 1,
          sizeBytes: size,
          createdAtMs: 1,
          modifiedAtMs: 1,
          isScreenshot: Value(shot)));
  Future<void> decide(String id, int decision, int t) =>
      db.into(db.decisions).insert(DecisionsCompanion.insert(
          assetId: id, decision: decision, decidedAtMs: t));

  test(
      'snapshot sums decisions per day with kept, cleared bytes and categories',
      () async {
    await asset('a');
    await asset('b', size: 500);
    await asset('c', size: 700, shot: true);
    await decide('a', 0, ms(2026, 10, 20));
    await decide('b', 1, ms(2026, 10, 20));
    await decide('c', 1, ms(2026, 10, 21));
    await StatsService(db).snapshot();
    final r = {for (final r in await db.select(db.dailyStats).get()) r.day: r};
    expect(r['2026-10-20']!.swept, 2);
    expect(r['2026-10-20']!.kept, 1);
    expect(r['2026-10-20']!.clearedFiles, 1);
    expect(r['2026-10-20']!.clearedBytes, 500);
    expect(r['2026-10-20']!.catOther, 1);
    expect(r['2026-10-21']!.catShots, 1);
  });

  test('a day survives deleting the files for good', () async {
    await asset('a', size: 900);
    await decide('a', 1, ms(2026, 10, 20));
    final s = StatsService(db);
    await s.snapshot();
    await (db.delete(db.assets)..where((a) => a.id.equals('a')))
        .go(); // cascades the decision away
    await s.snapshot();
    final r = (await db.select(db.dailyStats).get()).single;
    expect((r.swept, r.clearedBytes), (1, 900));
  });

  test('sessions land on the day they ended and the storage percent is kept',
      () async {
    await db.into(db.sessions).insert(SessionsCompanion.insert(
        startedMs: ms(2026, 10, 20),
        endedMs: ms(2026, 10, 20, 13),
        goal: 50,
        swept: 50,
        trashed: 3,
        bytes: 10));
    await StatsService(db)
        .snapshot(now: DateTime(2026, 10, 20, 15), usedPct: 61);
    final r = (await db.select(db.dailyStats).get()).single;
    expect((r.day, r.sessions, r.usedPct), ('2026-10-20', 1, 61));
  });

  test(
      'upgrading from schema 3 backfills swept and kept without inventing bytes for gone files',
      () async {
    final dir = Directory.systemTemp.createTempSync('sweeep_stats');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var first = SweeepDatabase(NativeDatabase(file));
    await first.select(first.assets).get(); // creates the schema
    await first.customStatement('DROP TABLE daily_stats');
    await first.customStatement(
        'INSERT INTO assets (id, media_type, width, height, size_bytes, created_at_ms, modified_at_ms, is_screenshot, is_screen_recording) VALUES (\'x\', 0, 1, 1, 321, 1, 1, 0, 0)');
    await first.customStatement(
        'INSERT INTO decisions (asset_id, decision, decided_at_ms) VALUES (\'x\', 1, ${ms(2026, 10, 19)})');
    await first.customStatement('PRAGMA user_version = 3');
    await first.close();

    first = SweeepDatabase(NativeDatabase(file));
    final r = (await first.select(first.dailyStats).get()).single;
    expect((r.day, r.swept, r.kept, r.clearedFiles, r.clearedBytes),
        ('2026-10-19', 1, 0, 1, 321));
    await first.close();
  });

  group('weeks', () {
    DailyStat row(String day, int swept, {int bytes = 0, int? used}) =>
        DailyStat(
            day: day,
            swept: swept,
            kept: swept,
            clearedFiles: 0,
            clearedBytes: bytes,
            sessions: 0,
            catDups: 0,
            catSimilar: 0,
            catShots: 0,
            catBlurry: 0,
            catOther: 0,
            usedPct: used);
    // Wed 21 Oct 2026
    final today = DateTime(2026, 10, 21);

    test('no history is one empty week and never divides by zero', () {
      final b = WeekBook.from(const [], today: today, goal: 50);
      expect(b.count, 1);
      final w = b.week(0);
      expect(
          (w.swept, w.streak, w.goalsHit, w.prevClearedBytes), (0, 0, 0, null));
      expect(w.start, DateTime(2026, 10, 19));
    });

    test('weeks run Monday to Sunday and page back to the first recorded day',
        () {
      final b = WeekBook.from(
          [row('2026-10-05', 10), row('2026-10-20', 60, bytes: 2000)],
          today: today, goal: 50);
      expect(b.count, 3);
      expect(b.week(0).days[1].swept, 60);
      expect(b.week(0).goalsHit, 1);
      expect(b.week(1).clearedBytes, 0);
      expect(b.week(0).prevClearedBytes, 0);
      expect(b.week(2).prevClearedBytes, isNull);
      expect(b.week(2).start, DateTime(2026, 10, 5));
    });

    test(
        'streak counts days with swiping up to today, and a past week ends on its Sunday',
        () {
      final b = WeekBook.from([
        row('2026-10-17', 5),
        row('2026-10-18', 5),
        row('2026-10-19', 5),
        row('2026-10-20', 5),
        row('2026-10-21', 5)
      ], today: today, goal: 50);
      expect(b.week(0).streak, 5);
      expect(b.week(1).streak, 2);
    });

    test('storage runs from the first value seen to the latest', () {
      final b = WeekBook.from(
          [row('2026-10-17', 0, used: 61), row('2026-10-20', 0, used: 60)],
          today: today, goal: 50, usedNow: 58);
      expect((b.week(0).usedFrom, b.week(0).usedTo), (61, 58));
      expect((b.week(1).usedFrom, b.week(1).usedTo), (61, 61));
    });
  });
}
