import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/goal_service.dart';
import 'package:sweeep/index/review_service.dart';

void main() {
  late SweeepDatabase db;
  final now = DateTime(2026, 10, 20, 12);
  int ago(int days) => now.subtract(Duration(days: days)).millisecondsSinceEpoch;

  setUp(() => db = SweeepDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> add(String id, int size, {bool shot = false, int days = 0}) =>
      db.into(db.assets).insert(AssetsCompanion.insert(id: id, mediaType: 0, width: 1, height: 1, sizeBytes: size, createdAtMs: ago(days), modifiedAtMs: ago(days), isScreenshot: Value(shot)));

  Future<void> group(int kind, String best, List<String> members) async {
    final g = await db.into(db.groups).insert(GroupsCompanion.insert(kind: kind, bestAssetId: Value(best), savingsBytes: 1, createdAtMs: 1));
    for (final m in members) {
      await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g, assetId: m));
    }
  }

  test('rows come safest first and a file claimed by an earlier rule is not counted again', () async {
    await add('best', 100);
    await add('twin', 1000); // exact duplicate extra, also an old screenshot and a similar extra
    await add('other', 10);
    await add('oldShot', 5000, shot: true, days: 200);
    await db.update(db.assets).replace(AssetsCompanion(
        id: const Value('twin'), mediaType: const Value(0), width: const Value(1), height: const Value(1), sizeBytes: const Value(1000), createdAtMs: Value(ago(200)), modifiedAtMs: Value(ago(200)), isScreenshot: const Value(true)));
    await group(0, 'best', ['best', 'twin']);
    await group(1, 'best', ['best', 'twin', 'other']);

    final plan = await GoalService(db).load(now: now);
    expect(plan.rows.map((r) => r.rule), [GoalRule.duplicates, GoalRule.oldScreenshots, GoalRule.similar]);
    expect(plan.rows[0].items.map((e) => e.id), ['twin']);
    expect(plan.rows[1].items.map((e) => e.id), ['oldShot']); // twin already went with the duplicates
    expect(plan.rows[2].items.map((e) => e.id), ['other']);
    expect(plan.totalBytes, 1000 + 5000 + 10);
  });

  test('pick takes whole rows from the top while the goal is not met', () {
    GoalRow row(GoalRule r, int bytes) => GoalRow(rule: r, items: [CategoryItem(id: r.name, sizeBytes: bytes, createdAtMs: 0, isVideo: false)]);
    final plan = GoalPlan([row(GoalRule.duplicates, 10), row(GoalRule.oldScreenshots, 200), row(GoalRule.blurry, 100), row(GoalRule.similar, 50)]);
    expect(plan.pick(5), [true, false, false, false]);
    expect(plan.pick(100), [true, true, false, false]); // 10 < 100 so the 200 row is taken whole
    expect(plan.pick(1000), [true, true, true, true]);
    expect(plan.pickedBytes(100), 210);
    expect(plan.pickedItems(100).map((e) => e.id), ['duplicates', 'oldScreenshots']);
  });

  test('kept and trashed files never enter a plan', () async {
    await add('a', 10, shot: true, days: 200);
    await add('b', 10, shot: true, days: 200);
    await db.into(db.decisions).insert(DecisionsCompanion.insert(assetId: 'a', decision: 0, decidedAtMs: 1));
    await db.into(db.trashItems).insert(TrashItemsCompanion.insert(assetId: 'b', sizeBytes: 10, trashedAtMs: 1, expiresAtMs: 2, reason: 0));
    expect((await GoalService(db).load(now: now)).rows, isEmpty);
  });
}
