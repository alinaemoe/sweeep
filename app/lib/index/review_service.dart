import '../data/database.dart';
import 'group_service.dart';
import 'home_service.dart';

enum SwipeSource { all, screenshots, blurry }

class SwipeItem {
  const SwipeItem({required this.id, required this.sizeBytes, required this.createdAtMs});
  final String id;
  final int sizeBytes;
  final int createdAtMs;
}

class TrashEntry {
  const TrashEntry({required this.id, required this.sizeBytes, required this.isVideo, this.durationMs});
  final String id;
  final int sizeBytes;
  final bool isVideo;
  final int? durationMs;
}

/// Swipe queue + app-trash operations. Nothing is deleted from the device
/// here: "trash" only records ids (soft trash, 30 days).
class ReviewService {
  ReviewService(this.db);
  final SweeepDatabase db;

  static const queueLimit = 500;

  /// Undecided photos for [source], newest first.
  Future<List<SwipeItem>> queue(SwipeSource source) async {
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
      ORDER BY a.created_at_ms DESC LIMIT $queueLimit
    ''').get();
    return [for (final r in rows) SwipeItem(id: r.read<String>('id'), sizeBytes: r.read<int>('size'), createdAtMs: r.read<int>('t'))];
  }

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

  Future<List<TrashEntry>> trashed() async {
    final rows = await db.customSelect('''
      SELECT t.asset_id AS id, t.size_bytes AS size, a.media_type AS mt, a.duration_ms AS dur
      FROM trash_items t JOIN assets a ON a.id = t.asset_id
      ORDER BY t.trashed_at_ms DESC
    ''').get();
    return [
      for (final r in rows)
        TrashEntry(id: r.read<String>('id'), sizeBytes: r.read<int>('size'), isVideo: r.read<int>('mt') == 1, durationMs: r.read<int?>('dur')),
    ];
  }
}
