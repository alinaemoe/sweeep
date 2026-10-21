import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/features/wrap/month_wrap_screen.dart';
import 'package:sweeep/index/month_wrap_service.dart';

void main() {
  late SweeepDatabase db;
  late MonthWrapService svc;
  setUpAll(initializeDateFormatting);
  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    svc = MonthWrapService(db);
  });
  tearDown(() => db.close());

  int ms(int y, int m, int d) => DateTime(y, m, d, 12).millisecondsSinceEpoch;

  Future<void> add(String id, int t, {int size = 100, double? sharp}) async {
    await db.into(db.assets).insert(AssetsCompanion.insert(id: id, mediaType: 0, width: 1, height: 1, sizeBytes: size, createdAtMs: t, modifiedAtMs: t));
    if (sharp != null) await db.into(db.hashes).insert(HashesCompanion.insert(assetId: id, laplacianVar: Value(sharp), analyzedAtMs: 1, analysisVersion: 1));
  }

  Future<void> keep(String id) => db.into(db.decisions).insert(DecisionsCompanion.insert(assetId: id, decision: 0, decidedAtMs: ms(2026, 10, 20)));

  Future<void> trash(String id, int size) async {
    await db.into(db.decisions).insert(DecisionsCompanion.insert(assetId: id, decision: 1, decidedAtMs: ms(2026, 10, 20)));
    await db.into(db.trashItems).insert(TrashItemsCompanion.insert(assetId: id, sizeBytes: size, trashedAtMs: 1, expiresAtMs: 2, reason: 0));
  }

  test('a month is pending only when every photo is decided, and only once', () async {
    await add('a', ms(2026, 6, 3));
    await add('b', ms(2026, 6, 9));
    await keep('a');
    expect(await svc.pendingFor(ms(2026, 6, 3)), isNull);
    await trash('b', 100);
    expect(await svc.pendingFor(ms(2026, 6, 9)), '2026-06');
    await svc.markShown('2026-06');
    expect(await svc.pendingFor(ms(2026, 6, 9)), isNull);
  });

  test('numbers: looked, kept, cleared, freed; best = sharpest kept, one per group', () async {
    await add('k1', ms(2026, 6, 1), sharp: 900);
    await add('k2', ms(2026, 6, 2), sharp: 800); // same group as k1, skipped
    await add('k3', ms(2026, 6, 3), sharp: 500);
    await add('k4', ms(2026, 6, 4)); // no hash, never "best"
    await add('t1', ms(2026, 6, 5), size: 1000);
    await add('other', ms(2026, 7, 1), sharp: 9999); // another month
    for (final id in ['k1', 'k2', 'k3', 'k4']) {
      await keep(id);
    }
    await trash('t1', 1000);
    final g = await db.into(db.groups).insert(GroupsCompanion.insert(kind: 1, savingsBytes: 1, createdAtMs: 1));
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g, assetId: 'k1'));
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g, assetId: 'k2'));
    await db.into(db.sessions).insert(SessionsCompanion.insert(startedMs: ms(2026, 10, 20), endedMs: ms(2026, 10, 20) + 1000, goal: 25, swept: 5, trashed: 1, bytes: 1000));

    final d = await svc.data('2026-06');
    expect(d.looked, 5);
    expect(d.kept, 4);
    expect(d.trashed, 1);
    expect(d.freedBytes, 1000);
    expect(d.best, ['k1', 'k3']);
    expect(d.sessions, 1);
    expect(d.nextMonth, '2026-07');
  });

  test('the stretched month word', () {
    expect(stretchMonth('June'), 'JUUUNE');
    expect(stretchMonth('April'), 'APRIIIL');
    expect(stretchMonth('Июнь'), 'ИЮЮЮНЬ');
  });
}
