import 'package:drift/drift.dart';

import '../data/database.dart';
import '../platform/media_source.dart';
import '../platform/messages.g.dart' as pg;

class IndexResult {
  const IndexResult({required this.upserted, required this.removed, required this.total, required this.full});
  final int upserted;
  final int removed;
  final int total;

  /// True when no previous sync existed (everything was enumerated).
  final bool full;
}

class LibraryStats {
  const LibraryStats({
    required this.total,
    required this.photos,
    required this.videos,
    required this.screenshots,
    required this.screenRecordings,
    required this.chatMedia,
    required this.bytes,
  });
  final int total;
  final int photos;
  final int videos;
  final int screenshots;
  final int screenRecordings;
  final int chatMedia;
  final int bytes;
}

/// Delta index: mirrors the device library into the `assets` table.
///
/// First run enumerates everything. Later runs only fetch items modified
/// since the last sync (with a small overlap) and drop rows whose asset no
/// longer exists.
class IndexService {
  IndexService(this.db, this.media, {int Function()? clock}) : _now = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SweeepDatabase db;
  final MediaSource media;
  final int Function() _now;

  static const lastSyncKey = 'last_index_ms';
  static const pageSize = 500;
  static const overlapMs = 5000;

  Future<int?> _lastSync() async {
    final row = await (db.select(db.scanState)..where((s) => s.key.equals(lastSyncKey))).getSingleOrNull();
    return row == null ? null : int.tryParse(row.value);
  }

  Future<IndexResult> sync({void Function(int processed)? onProgress}) async {
    final started = _now();
    final last = await _lastSync();
    final since = last == null ? null : (last - overlapMs).clamp(0, started);

    var upserted = 0;
    String? cursor;
    do {
      final page = await media.listAssets(sinceMs: since, cursor: cursor, limit: pageSize);
      if (page.assets.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.assets, page.assets.map(_toCompanion));
        });
        upserted += page.assets.length;
        onProgress?.call(upserted);
      }
      cursor = page.nextCursor;
    } while (cursor != null);

    final removed = await _removeMissing();

    await db.into(db.scanState).insertOnConflictUpdate(
          ScanStateCompanion.insert(key: lastSyncKey, value: started.toString()),
        );

    final total = await (db.selectOnly(db.assets)..addColumns([db.assets.id.count()]))
        .map((r) => r.read(db.assets.id.count()) ?? 0)
        .getSingle();
    return IndexResult(upserted: upserted, removed: removed, total: total, full: last == null);
  }

  Future<int> _removeMissing() async {
    final live = (await media.allAssetIds()).toSet();
    final known = await (db.selectOnly(db.assets)..addColumns([db.assets.id])).map((r) => r.read(db.assets.id)!).get();
    final gone = known.where((id) => !live.contains(id)).toList();
    for (var i = 0; i < gone.length; i += 500) {
      final chunk = gone.sublist(i, i + 500 > gone.length ? gone.length : i + 500);
      await (db.delete(db.assets)..where((a) => a.id.isIn(chunk))).go();
    }
    return gone.length;
  }

  AssetsCompanion _toCompanion(pg.AssetInfo a) => AssetsCompanion.insert(
        id: a.id,
        mediaType: a.mediaType == pg.MediaType.video ? 1 : 0,
        width: a.width,
        height: a.height,
        sizeBytes: a.sizeBytes,
        durationMs: Value(a.durationMs),
        createdAtMs: a.createdAtMs,
        modifiedAtMs: a.modifiedAtMs,
        bucket: Value(a.bucket),
        isScreenshot: Value(a.isScreenshot),
        isScreenRecording: Value(a.isScreenRecording),
        chatSource: Value(a.chatSource),
      );

  Future<LibraryStats> stats() async {
    final r = await db.customSelect('''
      SELECT COUNT(*) AS total,
             COALESCE(SUM(media_type = 0), 0) AS photos,
             COALESCE(SUM(media_type = 1), 0) AS videos,
             COALESCE(SUM(is_screenshot), 0) AS shots,
             COALESCE(SUM(is_screen_recording), 0) AS recs,
             COALESCE(SUM(chat_source IS NOT NULL), 0) AS chats,
             COALESCE(SUM(size_bytes), 0) AS bytes
      FROM assets
    ''').getSingle();
    return LibraryStats(
      total: r.read<int>('total'),
      photos: r.read<int>('photos'),
      videos: r.read<int>('videos'),
      screenshots: r.read<int>('shots'),
      screenRecordings: r.read<int>('recs'),
      chatMedia: r.read<int>('chats'),
      bytes: r.read<int>('bytes'),
    );
  }

  /// Newest photo ids, for thumbnail checks.
  Future<List<String>> newestPhotoIds(int n) async {
    final q = db.select(db.assets)
      ..where((a) => a.mediaType.equals(0))
      ..orderBy([(a) => OrderingTerm.desc(a.createdAtMs)])
      ..limit(n);
    return (await q.get()).map((a) => a.id).toList();
  }
}
