import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/index_service.dart';
import 'package:sweeep/platform/media_source.dart';
import 'package:sweeep/platform/messages.g.dart';

AssetInfo asset(String id, {int mod = 1000, bool shot = false, bool video = false, String? chat}) => AssetInfo(
      id: id,
      mediaType: video ? MediaType.video : MediaType.photo,
      width: 100,
      height: 100,
      sizeBytes: 1000,
      createdAtMs: mod,
      modifiedAtMs: mod,
      isScreenshot: shot,
      chatSource: chat,
    );

class FakeMedia implements MediaSource {
  final List<AssetInfo> library = [];
  final List<int?> sinceCalls = [];

  @override
  Future<PermissionState> permissionState() async => PermissionState.granted;
  @override
  Future<PermissionState> requestPermission() async => PermissionState.granted;
  @override
  Future<List<String>> allAssetIds() async => library.map((a) => a.id).toList();
  @override
  Future<Uint8List?> thumbnail(String assetId, {int maxSide = 256}) async => null;
  @override
  Future<Uint8List?> sha256(String assetId) async => null;
  @override
  Future<GrayThumb?> grayThumbnail(String assetId, {int maxSide = 128}) async => null;

  /// Newest first, keyset-paged like the Kotlin side.
  @override
  Future<AssetPage> listAssets({int? sinceMs, String? cursor, int limit = 500}) async {
    sinceCalls.add(sinceMs);
    var items = library.where((a) => sinceMs == null || a.modifiedAtMs >= sinceMs).toList()
      ..sort((a, b) => b.modifiedAtMs != a.modifiedAtMs ? b.modifiedAtMs.compareTo(a.modifiedAtMs) : int.parse(b.id).compareTo(int.parse(a.id)));
    if (cursor != null) {
      final p = cursor.split('|');
      final mod = int.parse(p[0]);
      final id = int.parse(p[1]);
      items = items.where((a) => a.modifiedAtMs < mod || (a.modifiedAtMs == mod && int.parse(a.id) < id)).toList();
    }
    final page = items.take(limit).toList();
    final next = page.length >= limit ? '${page.last.modifiedAtMs}|${page.last.id}' : null;
    return AssetPage(assets: page, nextCursor: next);
  }
}

void main() {
  late SweeepDatabase db;
  late FakeMedia media;
  var now = 100000;

  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    media = FakeMedia();
    now = 100000;
  });
  tearDown(() => db.close());

  IndexService svc() => IndexService(db, media, clock: () => now);

  test('first sync enumerates everything across pages', () async {
    for (var i = 1; i <= 1203; i++) {
      media.library.add(asset('$i', mod: i));
    }
    final r = await svc().sync();
    expect(r.full, isTrue);
    expect(r.upserted, 1203);
    expect(r.total, 1203);
    expect(media.sinceCalls.first, isNull);
  });

  test('delta sync only asks for recent changes, updates and removes', () async {
    for (var i = 1; i <= 10; i++) {
      media.library.add(asset('$i', mod: 1000));
    }
    await svc().sync();

    now = 200000;
    media.library.removeWhere((a) => a.id == '3');
    media.library.add(asset('11', mod: 150000));
    media.library[0] = asset('1', mod: 160000, shot: true);

    final r = await svc().sync();
    expect(r.full, isFalse);
    expect(media.sinceCalls.last, 100000 - IndexService.overlapMs);
    expect(r.upserted, 2); // new #11 and modified #1
    expect(r.removed, 1);
    expect(r.total, 10);
    final one = await (db.select(db.assets)..where((a) => a.id.equals('1'))).getSingle();
    expect(one.isScreenshot, isTrue);
  });

  test('stats count categories', () async {
    media.library
      ..add(asset('1'))
      ..add(asset('2', shot: true))
      ..add(asset('3', video: true))
      ..add(asset('4', chat: 'whatsapp'));
    final s = svc();
    await s.sync();
    final st = await s.stats();
    expect(st.total, 4);
    expect(st.photos, 3);
    expect(st.videos, 1);
    expect(st.screenshots, 1);
    expect(st.chatMedia, 1);
    expect(st.bytes, 4000);
  });
}
