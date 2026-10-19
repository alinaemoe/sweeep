import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/core/native_core.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/analysis_service.dart';
import 'package:sweeep/index/index_service.dart';
import 'package:sweeep/platform/media_source.dart';
import 'package:sweeep/platform/messages.g.dart';

AssetInfo asset(String id, {int created = 0, int size = 1000}) => AssetInfo(
      id: id,
      mediaType: MediaType.photo,
      width: 100,
      height: 100,
      sizeBytes: size,
      createdAtMs: created,
      modifiedAtMs: created,
      isScreenshot: false,
    );

class FakeMedia implements MediaSource {
  FakeMedia(this.assets, {this.unreadable = const {}});
  final List<AssetInfo> assets;
  final Set<String> unreadable;
  int thumbCalls = 0;

  @override
  Future<PermissionState> permissionState() async => PermissionState.granted;
  @override
  Future<PermissionState> requestPermission() async => PermissionState.granted;
  @override
  Future<List<String>> allAssetIds() async => assets.map((a) => a.id).toList();
  @override
  Future<AssetPage> listAssets({int? sinceMs, String? cursor, int limit = 500}) async => AssetPage(assets: assets);
  @override
  Future<Uint8List?> thumbnail(String assetId, {int maxSide = 256}) async => null;
  @override
  Future<Uint8List?> sha256(String assetId) async => null;
  @override
  Future<GrayThumb?> grayThumbnail(String assetId, {int maxSide = 128}) async {
    thumbCalls++;
    if (unreadable.contains(assetId)) return null;
    return GrayThumb(width: 4, height: 4, bytes: Uint8List(16));
  }
}

/// Deterministic fake: hash derived from the first byte pattern is not
/// needed, so it hands out preset hashes in call order.
class FakeCore implements AnalysisCore {
  int calls = 0;
  @override
  Analysis? analyze(Uint8List gray, int width, int height) {
    calls++;
    return Analysis(phash: calls, dhash: calls, ahash: calls, laplacianVar: calls * 10.0, medianBrightness: 100);
  }

  @override
  GroupLabels groupSimilar(List<int> hashes, List<int> timestampsMs, {int maxHamming = 8, int windowMs = 5000}) =>
      GroupLabels(0, Int32List(hashes.length)..fillRange(0, hashes.length, -1));
}

void main() {
  late SweeepDatabase db;
  setUp(() => db = SweeepDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<(FakeMedia, AnalysisService)> setup(int n, {Set<String> unreadable = const {}}) async {
    final media = FakeMedia([for (var i = 1; i <= n; i++) asset('$i', created: i)], unreadable: unreadable);
    await IndexService(db, media).sync();
    return (media, AnalysisService(db, media, FakeCore(), concurrency: 3, batchSize: 10));
  }

  test('hashes every asset in batches and reports progress', () async {
    final (_, svc) = await setup(25);
    expect(await svc.pendingCount(), 25);
    final progress = <int>[];
    final done = await svc.run(onProgress: (d, t) => progress.add(d));
    expect(done, 25);
    expect(progress, [10, 20, 25]);
    expect(await svc.pendingCount(), 0);
  });

  test('cancel stops between batches and a new run resumes without redoing work', () async {
    final (media, svc) = await setup(25);
    var batches = 0;
    final first = await svc.run(onProgress: (_, __) => batches++, shouldCancel: () => batches >= 1);
    expect(first, 10);
    expect(await svc.pendingCount(), 15);

    final callsBefore = media.thumbCalls;
    final second = await svc.run();
    expect(second, 15);
    expect(media.thumbCalls - callsBefore, 15); // only the remaining ones
    expect(await svc.pendingCount(), 0);
  });

  test('unreadable assets get a null row and are not retried', () async {
    final (media, svc) = await setup(6, unreadable: {'2', '5'});
    await svc.run();
    expect(await svc.pendingCount(), 0);
    final calls = media.thumbCalls;
    await svc.run();
    expect(media.thumbCalls, calls);
    final st = await svc.stats();
    expect(st.unreadable, 2);
    expect(st.hashed, 4);
  });

  test('bumping the analysis version makes everything pending again', () async {
    final (_, svc) = await setup(5);
    await svc.run();
    await db.customStatement('UPDATE hashes SET analysis_version = 0');
    expect(await svc.pendingCount(), 5);
  });
}
