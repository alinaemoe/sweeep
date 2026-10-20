import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/core/native_core.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/group_service.dart';
import 'package:sweeep/platform/media_source.dart';
import 'package:sweeep/platform/messages.g.dart';

class FakeMedia implements MediaSource {
  @override
  Future<DeleteResult> deleteAssets(List<String> assetIds) async => DeleteResult(deletedIds: assetIds, cancelled: false);
  FakeMedia(this.digests);
  final Map<String, int> digests; // asset id -> digest seed (equal seed = identical file)
  final List<String> hashed = [];

  @override
  Future<PermissionState> permissionState() async => PermissionState.granted;
  @override
  Future<PermissionState> requestPermission() async => PermissionState.granted;
  @override
  Future<AssetPage> listAssets({int? sinceMs, String? cursor, int limit = 500}) async => AssetPage(assets: []);
  @override
  Future<List<String>> allAssetIds() async => [];
  @override
  Future<GrayThumb?> grayThumbnail(String assetId, {int maxSide = 128}) async => null;
  @override
  Future<Uint8List?> thumbnail(String assetId, {int maxSide = 256}) async => null;
  @override
  Future<Uint8List?> sha256(String assetId) async {
    hashed.add(assetId);
    final seed = digests[assetId];
    return seed == null ? null : Uint8List.fromList(List.filled(32, seed));
  }
}

/// Groups by exact hash equality (stand-in for the Rust grouping).
class FakeCore implements AnalysisCore {
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

void main() {
  late SweeepDatabase db;
  setUp(() => db = SweeepDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addAsset(String id, {required int size, int created = 0, int? phash, double lap = 0}) async {
    await db.into(db.assets).insert(AssetsCompanion.insert(
          id: id,
          mediaType: 0,
          width: 100,
          height: 100,
          sizeBytes: size,
          createdAtMs: created,
          modifiedAtMs: created,
        ));
    await db.into(db.hashes).insert(HashesCompanion.insert(
          assetId: id,
          analyzedAtMs: 1,
          analysisVersion: 1,
          phash: Value(phash),
          laplacianVar: Value(lap),
        ));
  }

  GroupService svc(FakeMedia m) => GroupService(db, m, FakeCore(), concurrency: 2);

  test('only files that share a size are hashed for exact duplicates', () async {
    await addAsset('a', size: 100);
    await addAsset('b', size: 100);
    await addAsset('c', size: 555); // unique size, never read
    final m = FakeMedia({'a': 1, 'b': 1, 'c': 9});
    final s = svc(m);
    expect(await s.exactCandidates(), unorderedEquals(['a', 'b']));
    await s.hashExactCandidates();
    expect(m.hashed, unorderedEquals(['a', 'b']));
    expect(await s.exactCandidates(), isEmpty);
  });

  test('exact groups keep the oldest copy; similar groups keep the sharpest', () async {
    // exact pair (same digest) + a different file of the same size
    await addAsset('e1', size: 100, created: 20, phash: 1000);
    await addAsset('e2', size: 100, created: 10, phash: 1000); // oldest -> best
    await addAsset('e3', size: 100, created: 30, phash: 2000);
    // similar trio (same phash), different sizes, middle one sharpest
    await addAsset('s1', size: 300, created: 1, phash: 5, lap: 10);
    await addAsset('s2', size: 200, created: 2, phash: 5, lap: 99);
    await addAsset('s3', size: 100, created: 3, phash: 5, lap: 50);
    final s = svc(FakeMedia({'e1': 7, 'e2': 7, 'e3': 8}));
    await s.hashExactCandidates();
    final r = await s.rebuild();

    expect(r.exactGroups, 1);
    expect(r.similarGroups, 1);

    final dup = (await s.groups(GroupKind.duplicate)).single;
    expect(dup.bestId, 'e2');
    expect(dup.members.map((m) => m.assetId).toSet(), {'e1', 'e2'});
    expect(dup.savingsBytes, 100);

    final sim = (await s.groups(GroupKind.similar)).single;
    expect(sim.bestId, 's2');
    expect(sim.members.first.assetId, 's2'); // best first
    expect(sim.savingsBytes, 300 + 100); // everything but the best
  });

  test('exact-dup extras never reappear as a similar group', () async {
    // two identical files that also share a phash: must be ONE duplicate group, zero similar
    await addAsset('x1', size: 50, created: 1, phash: 77);
    await addAsset('x2', size: 50, created: 2, phash: 77);
    final s = svc(FakeMedia({'x1': 3, 'x2': 3}));
    await s.hashExactCandidates();
    final r = await s.rebuild();
    expect(r.exactGroups, 1);
    expect(r.similarGroups, 0);
  });

  test('trashing members hides them and dissolves groups that become singletons', () async {
    await addAsset('p', size: 10, created: 1, phash: 4, lap: 5);
    await addAsset('q', size: 10, created: 2, phash: 4, lap: 1);
    final s = svc(FakeMedia({}));
    await s.rebuild();
    final g = (await s.groups(GroupKind.similar)).single;
    expect(g.bestId, 'p');
    await s.trash(g.others);
    expect(await s.groups(GroupKind.similar), isEmpty);
    final t = await s.trashSummary();
    expect((t.count, t.bytes), (1, 10));
  });

  test('rebuild replaces previous groups instead of accumulating', () async {
    await addAsset('p', size: 10, created: 1, phash: 4);
    await addAsset('q', size: 10, created: 2, phash: 4);
    final s = svc(FakeMedia({}));
    await s.rebuild();
    await s.rebuild();
    expect((await db.select(db.groups).get()).length, 1);
    expect((await db.select(db.groupMembers).get()).length, 2);
  });

  test('rescan keeps ids of unchanged groups, adds new ones and drops vanished ones', () async {
    await addAsset('p', size: 10, created: 1, phash: 4);
    await addAsset('q', size: 10, created: 2, phash: 4);
    await addAsset('m', size: 10, created: 100, phash: 9);
    await addAsset('n', size: 10, created: 101, phash: 9);
    final s = svc(FakeMedia({}));
    await s.rebuild();
    final before = {for (final g in await s.groups(GroupKind.similar)) (g.members.map((m) => m.assetId).toList()..sort()).join(): g.id};
    expect(before.length, 2);

    // a third copy joins the first group (membership changed), the second is untouched
    await addAsset('r', size: 10, created: 3, phash: 4);
    await s.rebuild();
    final after = {for (final g in await s.groups(GroupKind.similar)) (g.members.map((m) => m.assetId).toList()..sort()).join(): g.id};
    expect(after.length, 2);
    expect(after['mn'], before['mn']);
    expect(after['pqr'], isNot(before['pq']));
    expect((await db.select(db.groups).get()).length, 2); // old p+q group is gone
  });

  test('kept photos are recorded as reviewed and leave the swipe queue', () async {
    await addAsset('k1', size: 10, created: 1, phash: 3, lap: 9);
    await addAsset('k2', size: 10, created: 2, phash: 3, lap: 1);
    final s = svc(FakeMedia({}));
    await s.rebuild();
    final g = (await s.groups(GroupKind.similar)).single;
    await s.markKept(g.members);
    final decided = await db.select(db.decisions).get();
    expect(decided.map((d) => (d.assetId, d.decision)).toSet(), {('k1', 0), ('k2', 0)});
    await s.trash([g.others.single]); // changing one's mind later: trash wins
    expect((await s.trashSummary()).count, 1);
  });

  test('limit and totals agree with the full list, and ignore trashed groups', () async {
    // three similar pairs with different savings (size of the extra copy)
    for (final (i, size) in [(1, 10), (2, 30), (3, 20)]) {
      await addAsset('b$i', size: 100, created: i * 100000, phash: i, lap: 9);
      await addAsset('c$i', size: size, created: i * 100000 + 1, phash: i, lap: 1);
    }
    final s = svc(FakeMedia({}));
    await s.rebuild();

    final all = await s.groups(GroupKind.similar);
    expect(all.map((g) => g.savingsBytes), [30, 20, 10]);
    final top = await s.groups(GroupKind.similar, limit: 2);
    expect(top.map((g) => g.id), all.take(2).map((g) => g.id));
    var totals = await s.groupTotals(GroupKind.similar);
    expect((totals.count, totals.savings), (3, 60));

    await s.trash(all.first.others); // first group drops to one live member
    totals = await s.groupTotals(GroupKind.similar);
    expect((totals.count, totals.savings), (2, 30));
    expect((await s.groups(GroupKind.similar, limit: 5)).length, 2);
    expect((await s.groupTotals(GroupKind.duplicate)).count, 0);
  });
}
