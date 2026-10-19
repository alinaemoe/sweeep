import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/review_service.dart';

void main() {
  late SweeepDatabase db;
  late ReviewService svc;
  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    svc = ReviewService(db);
  });
  tearDown(() => db.close());

  Future<void> add(String id, {int type = 0, bool shot = false, int t = 0, int size = 10}) => db.into(db.assets).insert(AssetsCompanion.insert(
        id: id, mediaType: type, width: 1, height: 1, sizeBytes: size, createdAtMs: t, modifiedAtMs: t, isScreenshot: Value(shot)));

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
}
