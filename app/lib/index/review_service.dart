import 'package:drift/drift.dart' show Variable;

import '../data/database.dart';
import '../platform/media_source.dart';
import 'group_service.dart';
import 'home_service.dart';

enum SwipeSource { all, screenshots, blurry }

const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/// '2026-10' -> 'October 2026'.
String monthTitle(String key) => '${_monthNames[int.parse(key.substring(5)) - 1]} ${key.substring(0, 4)}';

/// One month of the library for the Timeline: how many photos, how many are
/// already decided (kept or trashed) and the newest few as preview tiles.
class MonthSummary {
  const MonthSummary({required this.key, required this.count, required this.swept, required this.tiles});
  final String key; // 'YYYY-MM'
  final int count;
  final int swept;
  final List<({String id, int t})> tiles;

  bool get done => swept >= count;
  String get title => monthTitle(key);
}

enum CategoryKind { videos, screenshots, chat }

class SwipeItem {
  const SwipeItem({required this.id, required this.sizeBytes, required this.createdAtMs});
  final String id;
  final int sizeBytes;
  final int createdAtMs;
}

class CategoryItem {
  const CategoryItem({required this.id, required this.sizeBytes, required this.createdAtMs, required this.isVideo, this.durationMs, this.chatSource});
  final String id;
  final int sizeBytes;
  final int createdAtMs;
  final bool isVideo;
  final int? durationMs;
  final String? chatSource;
}

class TrashEntry {
  const TrashEntry({required this.id, required this.sizeBytes, required this.isVideo, required this.expiresAtMs, this.durationMs});
  final String id;
  final int sizeBytes;
  final bool isVideo;
  final int expiresAtMs;
  final int? durationMs;

  /// Whole days left before the 30-day soft trash expires (never below 0).
  int daysLeft([DateTime? now]) {
    final ms = expiresAtMs - (now ?? DateTime.now()).millisecondsSinceEpoch;
    return ms <= 0 ? 0 : (ms / Duration.millisecondsPerDay).ceil();
  }
}

class DeleteOutcome {
  const DeleteOutcome({required this.deleted, required this.bytes, required this.cancelled});
  final int deleted;
  final int bytes;
  final bool cancelled;
}

/// Swipe queue + app-trash operations. Nothing is deleted from the device
/// here: "trash" only records ids (soft trash, 30 days).
class ReviewService {
  ReviewService(this.db);
  final SweeepDatabase db;

  static const queueLimit = 500;

  static const _monthExpr = "strftime('%Y-%m', a.created_at_ms / 1000, 'unixepoch', 'localtime')";

  /// Every month that has photos, newest first, with progress and preview tiles.
  Future<List<MonthSummary>> months() async {
    final rows = await db.customSelect('''
      SELECT $_monthExpr AS m, COUNT(*) AS n,
        SUM(CASE WHEN a.id IN (SELECT asset_id FROM decisions) OR a.id IN (SELECT asset_id FROM trash_items) THEN 1 ELSE 0 END) AS swept
      FROM assets a WHERE a.media_type = 0 GROUP BY m ORDER BY m DESC
    ''').get();
    final tileRows = await db.customSelect('''
      SELECT id, t, m FROM (
        SELECT a.id AS id, a.created_at_ms AS t, $_monthExpr AS m,
          ROW_NUMBER() OVER (PARTITION BY $_monthExpr ORDER BY a.created_at_ms DESC) AS rn
        FROM assets a WHERE a.media_type = 0
      ) WHERE rn <= 6 ORDER BY m DESC, t DESC
    ''').get();
    final tiles = <String, List<({String id, int t})>>{};
    for (final r in tileRows) {
      tiles.putIfAbsent(r.read<String>('m'), () => []).add((id: r.read<String>('id'), t: r.read<int>('t')));
    }
    return [
      for (final r in rows)
        MonthSummary(key: r.read<String>('m'), count: r.read<int>('n'), swept: r.read<int>('swept'), tiles: tiles[r.read<String>('m')] ?? const []),
    ];
  }

  /// Undecided photos for [source], newest first. [month] ('YYYY-MM') narrows
  /// the queue to one month of the Timeline.
  Future<List<SwipeItem>> queue(SwipeSource source, {String? month}) async {
    final where = switch (source) {
      SwipeSource.all => 'a.media_type = 0',
      SwipeSource.screenshots => 'a.media_type = 0 AND a.is_screenshot = 1',
      SwipeSource.blurry => '''a.media_type = 0 AND a.is_screenshot = 0 AND a.id IN (
          SELECT asset_id FROM hashes
          WHERE (laplacian_var IS NOT NULL AND laplacian_var < ${HomeService.blurBelow})
             OR (median_brightness IS NOT NULL AND median_brightness < ${HomeService.darkBelow}))''',
    };
    final rows = await db.customSelect('''
      SELECT a.id AS id, a.size_bytes AS size, a.created_at_ms AS t FROM assets a
      WHERE $where
        AND a.id NOT IN (SELECT asset_id FROM trash_items)
        AND a.id NOT IN (SELECT asset_id FROM decisions)
        ${month == null ? '' : "AND $_monthExpr = '$month'"}
      ORDER BY a.created_at_ms DESC LIMIT $queueLimit
    ''').get();
    return [for (final r in rows) SwipeItem(id: r.read<String>('id'), sizeBytes: r.read<int>('size'), createdAtMs: r.read<int>('t'))];
  }

  /// All items of a category (not yet in the app trash). [chatSource] filters
  /// the chat category to one app; [bySize] sorts largest first, else newest.
  Future<List<CategoryItem>> category(CategoryKind kind, {String? chatSource, bool bySize = false}) async {
    final where = switch (kind) {
      CategoryKind.videos => 'a.media_type = 1',
      CategoryKind.screenshots => 'a.media_type = 0 AND a.is_screenshot = 1',
      CategoryKind.chat => chatSource == null ? 'a.chat_source IS NOT NULL' : 'a.chat_source = ?',
    };
    final rows = await db.customSelect(
      '''
      SELECT a.id AS id, a.size_bytes AS size, a.created_at_ms AS t, a.media_type AS mt, a.duration_ms AS dur, a.chat_source AS cs
      FROM assets a WHERE $where AND a.id NOT IN (SELECT asset_id FROM trash_items)
      ORDER BY ${bySize ? 'a.size_bytes' : 'a.created_at_ms'} DESC
      ''',
      variables: [if (kind == CategoryKind.chat && chatSource != null) Variable.withString(chatSource)],
    ).get();
    return [
      for (final r in rows)
        CategoryItem(
          id: r.read<String>('id'),
          sizeBytes: r.read<int>('size'),
          createdAtMs: r.read<int>('t'),
          isVideo: r.read<int>('mt') == 1,
          durationMs: r.read<int?>('dur'),
          chatSource: r.read<String?>('cs'),
        ),
    ];
  }

  Future<List<String>> chatSources() async {
    final rows = await db.customSelect('SELECT chat_source AS s, COUNT(*) AS n FROM assets WHERE chat_source IS NOT NULL GROUP BY chat_source ORDER BY n DESC').get();
    return [for (final r in rows) r.read<String>('s')];
  }

  /// Bulk soft-trash (reason 2 = category).
  Future<void> trashMany(List<CategoryItem> items) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + GroupService.trashDays * Duration.millisecondsPerDay;
    await db.batch((b) {
      b.insertAllOnConflictUpdate(db.trashItems, [
        for (final i in items) TrashItemsCompanion.insert(assetId: i.id, sizeBytes: i.sizeBytes, trashedAtMs: now, expiresAtMs: expires, reason: 2),
      ]);
      b.insertAllOnConflictUpdate(db.decisions, [
        for (final i in items) DecisionsCompanion.insert(assetId: i.id, decision: 1, decidedAtMs: now),
      ]);
    });
  }

  static const _hintKey = 'swipe_hint_seen';

  Future<bool> swipeHintSeen() async => (await (db.select(db.scanState)..where((s) => s.key.equals(_hintKey))).getSingleOrNull()) != null;

  Future<void> markSwipeHintSeen() => db.into(db.scanState).insertOnConflictUpdate(ScanStateCompanion.insert(key: _hintKey, value: '1'));

  Future<void> keep(SwipeItem item) => db.into(db.decisions).insertOnConflictUpdate(
        DecisionsCompanion.insert(assetId: item.id, decision: 0, decidedAtMs: DateTime.now().millisecondsSinceEpoch),
      );

  Future<void> trash(SwipeItem item) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.batch((b) {
      b.insertAllOnConflictUpdate(db.trashItems, [
        TrashItemsCompanion.insert(
          assetId: item.id,
          sizeBytes: item.sizeBytes,
          trashedAtMs: now,
          expiresAtMs: now + GroupService.trashDays * Duration.millisecondsPerDay,
          reason: 0,
        ),
      ]);
      b.insertAllOnConflictUpdate(db.decisions, [DecisionsCompanion.insert(assetId: item.id, decision: 1, decidedAtMs: now)]);
    });
  }

  /// Reverts a swipe decision (keep or trash).
  Future<void> undo(String assetId) => restore([assetId]);

  /// Removes ids from the app trash and forgets their decision.
  Future<void> restore(List<String> ids) async {
    await db.batch((b) {
      b.deleteWhere(db.trashItems, (t) => t.assetId.isIn(ids));
      b.deleteWhere(db.decisions, (d) => d.assetId.isIn(ids));
    });
  }

  /// Deletes [ids] from the device (system confirmation dialog, in chunks)
  /// and forgets every deleted asset locally. Returns what was really deleted.
  Future<DeleteOutcome> deleteForever(MediaSource media, List<String> ids, {int chunk = 200}) async {
    final deleted = <String>[];
    var cancelled = false;
    for (var i = 0; i < ids.length && !cancelled; i += chunk) {
      final part = ids.sublist(i, i + chunk > ids.length ? ids.length : i + chunk);
      final r = await media.deleteAssets(part);
      deleted.addAll(r.deletedIds);
      cancelled = r.cancelled;
    }
    var bytes = 0;
    if (deleted.isNotEmpty) {
      final rows = await (db.select(db.trashItems)..where((t) => t.assetId.isIn(deleted))).get();
      bytes = rows.fold(0, (s, r) => s + r.sizeBytes);
      // assets cascade to hashes, groups members, trash items and decisions
      await (db.delete(db.assets)..where((a) => a.id.isIn(deleted))).go();
    }
    return DeleteOutcome(deleted: deleted.length, bytes: bytes, cancelled: cancelled);
  }

  Future<List<TrashEntry>> trashed() async {
    final rows = await db.customSelect('''
      SELECT t.asset_id AS id, t.size_bytes AS size, t.expires_at_ms AS exp, a.media_type AS mt, a.duration_ms AS dur
      FROM trash_items t JOIN assets a ON a.id = t.asset_id
      ORDER BY t.trashed_at_ms DESC
    ''').get();
    return [
      for (final r in rows)
        TrashEntry(id: r.read<String>('id'), sizeBytes: r.read<int>('size'), isVideo: r.read<int>('mt') == 1, expiresAtMs: r.read<int>('exp'), durationMs: r.read<int?>('dur')),
    ];
  }
}
