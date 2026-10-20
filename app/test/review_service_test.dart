import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/review_service.dart';
import 'package:sweeep/platform/media_source.dart';
import 'package:sweeep/platform/messages.g.dart';

class _Media implements MediaSource {
  _Media(this.result);
  final DeleteResult result;
  @override
  Future<DeleteResult> deleteAssets(List<String> assetIds) async => result;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  late SweeepDatabase db;
  late ReviewService svc;
  setUpAll(initializeDateFormatting);
  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    svc = ReviewService(db);
  });
  tearDown(() => db.close());

  Future<void> add(String id, {int type = 0, bool shot = false, int t = 0, int size = 10, String? chat}) => db.into(db.assets).insert(AssetsCompanion.insert(
        id: id, mediaType: type, width: 1, height: 1, sizeBytes: size, createdAtMs: t, modifiedAtMs: t, isScreenshot: Value(shot), chatSource: Value(chat)));

  test('queue is newest first, photos only, skips decided items', () async {
    await add('old', t: 1);
    await add('new', t: 3);
    await add('vid', type: 1, t: 5);
    await add('shot', shot: true, t: 2);
    expect((await svc.queue(SwipeSource.all)).map((e) => e.id), ['new', 'shot', 'old']);
    expect((await svc.queue(SwipeSource.screenshots)).map((e) => e.id), ['shot']);

    final items = await svc.queue(SwipeSource.all);
    await svc.keep(items[0]);
    await svc.trash(items[1]);
    expect((await svc.queue(SwipeSource.all)).map((e) => e.id), ['old']);
  });

  test('timeline groups photos by month with progress and a month-only queue', () async {
    int ms(int y, int m, int d) => DateTime(y, m, d, 12).millisecondsSinceEpoch;
    await add('o1', t: ms(2026, 10, 3));
    await add('o2', t: ms(2026, 10, 19));
    await add('s1', t: ms(2026, 9, 5));
    await add('v', type: 1, t: ms(2026, 10, 7));
    final q = await svc.queue(SwipeSource.all, month: '2026-10');
    expect(q.map((e) => e.id), ['o2', 'o1']);
    await svc.keep(q.first);

    final months = await svc.months();
    expect(months.map((m) => m.key), ['2026-10', '2026-09']);
    expect(months[0].count, 2);
    expect(months[0].swept, 1);
    expect(months[0].done, isFalse);
    expect(months[0].tiles.map((t) => t.id), ['o2', 'o1']);
    expect(months[0].title, 'October 2026');
    expect((await svc.queue(SwipeSource.all, month: '2026-10')).map((e) => e.id), ['o1']);
  });

  test('trash lists items, undo and restore bring them back', () async {
    await add('a', t: 1, size: 5);
    await add('b', t: 2, size: 7);
    final q = await svc.queue(SwipeSource.all);
    await svc.trash(q[0]);
    await svc.trash(q[1]);
    expect((await svc.trashed()).map((e) => e.id).toSet(), {'a', 'b'});

    await svc.undo('b');
    expect((await svc.trashed()).map((e) => e.id), ['a']);
    await svc.restore(['a']);
    expect(await svc.trashed(), isEmpty);
    expect((await svc.queue(SwipeSource.all)).length, 2);
  });

  test('deleteForever drops only what the system really deleted', () async {
    await add('a', t: 1, size: 5);
    await add('b', t: 2, size: 7);
    for (final i in await svc.queue(SwipeSource.all)) {
      await svc.trash(i);
    }
    final r = await svc.deleteForever(_Media(DeleteResult(deletedIds: ['a'], cancelled: false)), ['a', 'b']);
    expect((r.deleted, r.bytes, r.cancelled), (1, 5, false));
    expect((await svc.trashed()).map((e) => e.id), ['b']);
    expect((await db.select(db.assets).get()).map((a) => a.id), ['b']);

    final c = await svc.deleteForever(_Media(DeleteResult(deletedIds: [], cancelled: true)), ['b']);
    expect((c.deleted, c.cancelled), (0, true));
    expect((await svc.trashed()).length, 1);
  });

  test('category lists filter, sort and bulk trash', () async {
    await add('v1', type: 1, t: 1, size: 50);
    await add('v2', type: 1, t: 2, size: 900);
    await add('s1', shot: true, t: 3);
    await add('c1', t: 4, chat: 'telegram');
    await add('c2', t: 5, chat: 'whatsapp', size: 70);

    expect((await svc.category(CategoryKind.videos)).map((e) => e.id), ['v2', 'v1']); // newest first
    expect((await svc.category(CategoryKind.videos, bySize: true)).map((e) => e.id), ['v2', 'v1']);
    expect((await svc.category(CategoryKind.screenshots)).map((e) => e.id), ['s1']);
    expect((await svc.category(CategoryKind.chat)).map((e) => e.id), ['c2', 'c1']);
    expect((await svc.category(CategoryKind.chat, chatSource: 'telegram')).map((e) => e.id), ['c1']);
    expect((await svc.chatSources()).toSet(), {'telegram', 'whatsapp'});

    await svc.trashMany(await svc.category(CategoryKind.videos));
    expect(await svc.category(CategoryKind.videos), isEmpty);
    expect((await svc.trashed()).length, 2);
  });

  test('trash entries know their days left; swipe hint is remembered', () async {
    await add('a', t: 1);
    await svc.trash((await svc.queue(SwipeSource.all)).first);
    final e = (await svc.trashed()).single;
    expect(e.daysLeft(), 30);
    expect(e.daysLeft(DateTime.fromMillisecondsSinceEpoch(e.expiresAtMs - 1)), 1);
    expect(e.daysLeft(DateTime.fromMillisecondsSinceEpoch(e.expiresAtMs + 5)), 0);

    expect(await svc.swipeHintSeen(), isFalse);
    await svc.markSwipeHintSeen();
    expect(await svc.swipeHintSeen(), isTrue);
  });
}
