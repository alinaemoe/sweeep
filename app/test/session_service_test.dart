import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/session_service.dart';

void main() {
  setUpAll(initializeDateFormatting);
  // Tue 20 Oct 2026
  final today = DateTime(2026, 10, 20);
  Set<DateTime> d(List<int> daysAgo) => {for (final n in daysAgo) today.subtract(Duration(days: n))};

  test('streak counts consecutive days; an empty today does not break it', () {
    expect(computeStreak(d([]), today).current, 0);
    final s = computeStreak(d([1, 2, 3]), today);
    expect(s.current, 3);
    expect(s.todayDone, isFalse);
    expect(computeStreak(d([0, 1, 2, 3]), today).current, 4);
  });

  test('one missed day a week is forgiven, two in a row end the streak', () {
    // today, [yesterday missed], 2..4 ago: Mon 19 is missed, week of 19 Oct has a free freeze
    final s = computeStreak(d([0, 2, 3, 4]), today);
    expect(s.current, 4);
    expect(s.freezeLeft, isFalse);
    expect(computeStreak(d([0, 3, 4]), today).current, 1);
  });

  test('best streak survives a later break', () {
    final s = computeStreak(d([0, 10, 11, 12, 13, 14]), today);
    expect(s.best, 5);
    expect(s.current, 1);
  });

  group('plan', () {
    late SweeepDatabase db;
    setUp(() => db = SweeepDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());
    int ms(int y, int m, int day) => DateTime(y, m, day, 12).millisecondsSinceEpoch;
    Future<void> add(String id, int t) => db.into(db.assets).insert(AssetsCompanion.insert(id: id, mediaType: 0, width: 1, height: 1, sizeBytes: 10, createdAtMs: t, modifiedAtMs: t));

    test('starts with the oldest unfinished month, lookalikes first, then spills into the next month', () async {
      await add('a1', ms(2026, 5, 1));
      await add('a2', ms(2026, 5, 2));
      await add('a3', ms(2026, 5, 3));
      await add('b1', ms(2026, 6, 1));
      final g = await db.into(db.groups).insert(GroupsCompanion.insert(kind: 1, savingsBytes: 1, createdAtMs: 1));
      await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g, assetId: 'a3'));
      await db.into(db.decisions).insert(DecisionsCompanion.insert(assetId: 'a1', decision: 0, decidedAtMs: 1));

      final p = await SessionService(db).plan(3);
      expect(p.startMonth, '2026-05');
      expect(p.items.map((e) => e.id), ['a3', 'a2', 'b1']);
    });

    test('saved goal defaults to 50 and remembers the choice', () async {
      final s = SessionService(db);
      expect(await s.goal(), 50);
      await s.setGoal(25);
      expect(await s.goal(), 25);
    });
  });
}
