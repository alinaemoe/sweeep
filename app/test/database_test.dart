import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/data/database.dart';

void main() {
  late SweeepDatabase db;

  setUp(() => db = SweeepDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('u64 hashes round-trip through signed SQLite ints', () {
    for (final v in [BigInt.zero, BigInt.one, BigInt.parse('18446744073709551615'), BigInt.parse('9223372036854775808')]) {
      expect(hashFromDb(hashToDb(v)), v);
    }
  });

  test('deleting an asset cascades to hashes, group members, trash', () async {
    await db.into(db.assets).insert(AssetsCompanion.insert(
          id: 'a1',
          mediaType: 0,
          width: 4000,
          height: 3000,
          sizeBytes: 3200000,
          createdAtMs: 1,
          modifiedAtMs: 1,
        ));
    await db.into(db.hashes).insert(HashesCompanion.insert(
          assetId: 'a1',
          analyzedAtMs: 2,
          analysisVersion: 1,
          phash: Value(hashToDb(BigInt.parse('18446744073709551615'))),
        ));
    final gid = await db.into(db.groups).insert(GroupsCompanion.insert(kind: 0, savingsBytes: 100, createdAtMs: 3));
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: gid, assetId: 'a1'));
    await db.into(db.trashItems).insert(TrashItemsCompanion.insert(
          assetId: 'a1',
          sizeBytes: 3200000,
          trashedAtMs: 4,
          expiresAtMs: 5,
          reason: 0,
        ));

    final stored = await (db.select(db.hashes)..where((h) => h.assetId.equals('a1'))).getSingle();
    expect(hashFromDb(stored.phash!), BigInt.parse('18446744073709551615'));

    await (db.delete(db.assets)..where((a) => a.id.equals('a1'))).go();

    expect(await db.select(db.hashes).get(), isEmpty);
    expect(await db.select(db.groupMembers).get(), isEmpty);
    expect(await db.select(db.trashItems).get(), isEmpty);
  });
}
