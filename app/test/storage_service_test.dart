import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/review_service.dart';
import 'package:sweeep/index/storage_service.dart';

void main() {
  late SweeepDatabase db;
  late StorageService svc;
  final now = DateTime(2026, 10, 20, 12);
  int ago(int days) => now.subtract(Duration(days: days)).millisecondsSinceEpoch;

  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    svc = StorageService(db);
  });
  tearDown(() => db.close());

  Future<void> add(String id, {int type = 0, int size = 1000, int days = 0, bool shot = false, bool rec = false, int? dur, String? chat, String? bucket}) =>
      db.into(db.assets).insert(AssetsCompanion.insert(
          id: id,
          mediaType: type,
          width: 1,
          height: 1,
          sizeBytes: size,
          createdAtMs: ago(days),
          modifiedAtMs: ago(days),
          durationMs: Value(dur),
          isScreenshot: Value(shot),
          isScreenRecording: Value(rec),
          chatSource: Value(chat),
          bucket: Value(bucket)));

  test('quick wins pick the right files and skip kept and trashed ones', () async {
    await add('oldShot', shot: true, days: 120, size: 500);
    await add('newShot', shot: true, days: 5, size: 500);
    await add('keptShot', shot: true, days: 200, size: 500);
    await add('longRec', type: 1, rec: true, dur: 90000, days: 60, size: 4000);
    await add('shortRec', type: 1, rec: true, dur: 20000, days: 60, size: 4000);
    await add('meme', chat: 'whatsapp', size: 100000, days: 40);
    await add('bigChat', chat: 'whatsapp', size: 3000000, days: 40);
    await add('trashedShot', shot: true, days: 300, size: 500);
    await db.into(db.decisions).insert(DecisionsCompanion.insert(assetId: 'keptShot', decision: 0, decidedAtMs: 1));
    await db.into(db.trashItems).insert(TrashItemsCompanion.insert(assetId: 'trashedShot', sizeBytes: 500, trashedAtMs: 1, expiresAtMs: 2, reason: 0));

    final d = await svc.load(now: now);
    int bytes(QuickWin w) => d.wins.firstWhere((e) => e.win == w).bytes;
    expect(bytes(QuickWin.oldScreenshots), 500);
    expect(bytes(QuickWin.longRecordings), 4000);
    expect(bytes(QuickWin.chatLeftovers), 100000);
    expect(d.safeBytes, 500 + 4000 + 100000);
  });

  test('duplicate extras and similar extras count as safe, the best one does not', () async {
    await add('a', size: 10);
    await add('b', size: 10);
    await add('c', size: 10);
    final g0 = await db.into(db.groups).insert(GroupsCompanion.insert(kind: 0, bestAssetId: const Value('a'), savingsBytes: 10, createdAtMs: 1));
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g0, assetId: 'a'));
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g0, assetId: 'b'));
    final g1 = await db.into(db.groups).insert(GroupsCompanion.insert(kind: 1, bestAssetId: const Value('c'), savingsBytes: 10, createdAtMs: 1));
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g1, assetId: 'c'));
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: g1, assetId: 'a'));

    final d = await svc.load(now: now);
    // b is an exact duplicate extra, a is a similar-group extra (c is best there)
    expect(d.safeBytes, 20);
    expect(d.wins.firstWhere((e) => e.win == QuickWin.duplicates).count, 1);
  });

  test('cuts: newest months get a block each, older ones fold into earlier; types and sources split', () async {
    for (var i = 0; i < 9; i++) {
      await db.into(db.assets).insert(AssetsCompanion.insert(
          id: 'm$i', mediaType: 0, width: 1, height: 1, sizeBytes: 100, createdAtMs: DateTime(2026, 10 - i, 15, 12).millisecondsSinceEpoch, modifiedAtMs: 0));
    }
    await add('cam', bucket: 'Camera', size: 7, days: 1);
    await add('wa', chat: 'whatsapp', size: 7, days: 1);
    await add('shot', shot: true, size: 7, days: 1);
    await add('vid', type: 1, size: 7, days: 1);

    final d = await svc.load(now: now);
    final months = d.cuts[StorageCut.months]!;
    expect(months.length, StorageService.monthTiles + 1);
    expect(months.last.key, 'earlier');
    expect(months.first.key, '2026-10');

    final types = {for (final t in d.cuts[StorageCut.types]!) t.key: t.count};
    expect(types['chat'], 1);
    expect(types['screenshots'], 1);
    expect(types['videos'], 1);
    expect(types['photos'], 10);

    final sources = {for (final t in d.cuts[StorageCut.sources]!) t.key: t.count};
    expect(sources['camera'], 1);
    expect(sources['whatsapp'], 1);
    expect(sources['screenshots'], 1);
  });

  test('a quick win deck and grid list only its own files', () async {
    await add('oldShot', shot: true, days: 120, size: 500);
    await add('newShot', shot: true, days: 5, size: 500);
    final review = ReviewService(db);
    expect((await review.category(CategoryKind.quickWin, win: QuickWin.oldScreenshots)).map((e) => e.id), ['oldShot']);
    expect((await review.queue(SwipeSource.quickWin, win: QuickWin.oldScreenshots)).map((e) => e.id), ['oldShot']);
  });
}
