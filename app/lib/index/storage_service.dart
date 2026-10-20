import '../data/database.dart';
import 'home_service.dart';

/// The one-tap clean-up rules under the storage map. Each one is a pure SQL
/// condition over `assets` (alias `a`); none of them needs anything but the
/// index. "Chat leftovers" means forwards and memes: small recompressed
/// photos that came through a messenger and have sat there for a while.
enum QuickWin { oldScreenshots, blurry, chatLeftovers, longRecordings, duplicates }

const _day = Duration.millisecondsPerDay;

/// Never touches what is already in the app trash or was kept on purpose.
const quickWinGuard = 'a.id NOT IN (SELECT asset_id FROM trash_items) AND a.id NOT IN (SELECT asset_id FROM decisions WHERE decision = 0)';

/// Extra files of a group kind (0 exact, 1 similar): everything except the best.
String groupExtras(int kind) => '''a.id IN (
    SELECT gm.asset_id FROM group_members gm JOIN groups g ON g.id = gm.group_id
    WHERE g.kind = $kind AND gm.asset_id != g.best_asset_id)''';

/// The condition for one rule, at time [nowMs].
String quickWinWhere(QuickWin w, int nowMs) => switch (w) {
      QuickWin.oldScreenshots => 'a.media_type = 0 AND a.is_screenshot = 1 AND a.created_at_ms < ${nowMs - 90 * _day}',
      QuickWin.blurry => '''a.media_type = 0 AND a.is_screenshot = 0 AND a.id IN (
          SELECT asset_id FROM hashes
          WHERE (laplacian_var IS NOT NULL AND laplacian_var < ${HomeService.blurBelow})
             OR (median_brightness IS NOT NULL AND median_brightness < ${HomeService.darkBelow}))''',
      QuickWin.chatLeftovers => 'a.media_type = 0 AND a.chat_source IS NOT NULL AND a.size_bytes < 600000 AND a.created_at_ms < ${nowMs - 30 * _day}',
      QuickWin.longRecordings => 'a.media_type = 1 AND a.is_screen_recording = 1 AND a.duration_ms > 60000 AND a.created_at_ms < ${nowMs - 30 * _day}',
      QuickWin.duplicates => groupExtras(0),
    };

/// Everything the app would call safe to clear: all five rules plus the extras
/// of similar groups, minus what was kept or trashed.
String safeWhere(int nowMs) => '($quickWinGuard) AND (${[for (final w in QuickWin.values) '(${quickWinWhere(w, nowMs)})'].join(' OR ')} OR ${groupExtras(1)})';

enum StorageCut { months, types, sources }

/// One block of the map. [key] is stable ('2026-08', 'earlier', 'videos',
/// 'whatsapp', ...); the screen turns it into a label.
class StorageTile {
  const StorageTile({required this.key, required this.count, required this.bytes, required this.reclaim});
  final String key;
  final int count;
  final int bytes;

  /// Part of [bytes] that is safe to clear.
  final int reclaim;

  double get share => bytes == 0 ? 0 : reclaim / bytes;
}

class QuickWinStat {
  const QuickWinStat({required this.win, required this.count, required this.bytes});
  final QuickWin win;
  final int count;
  final int bytes;
}

class StorageData {
  const StorageData({required this.totalBytes, required this.safeBytes, required this.cuts, required this.wins});
  final int totalBytes;
  final int safeBytes;
  final Map<StorageCut, List<StorageTile>> cuts;
  final List<QuickWinStat> wins;

  int get winsBytes => wins.fold(0, (s, w) => s + w.bytes);
}

/// Read-only numbers behind the Storage map and its Quick wins.
class StorageService {
  StorageService(this.db);
  final SweeepDatabase db;

  /// Newest months shown as their own block; older ones fold into "earlier".
  static const monthTiles = 7;

  static const _monthExpr = "strftime('%Y-%m', a.created_at_ms / 1000, 'unixepoch', 'localtime')";

  static const _typeExpr = '''CASE
      WHEN a.chat_source IS NOT NULL THEN 'chat'
      WHEN a.is_screenshot = 1 THEN 'screenshots'
      WHEN a.is_screen_recording = 1 THEN 'recordings'
      WHEN a.media_type = 1 THEN 'videos'
      ELSE 'photos' END''';

  static const _sourceExpr = '''CASE
      WHEN a.chat_source IS NOT NULL THEN a.chat_source
      WHEN a.is_screenshot = 1 THEN 'screenshots'
      WHEN lower(a.bucket) = 'camera' THEN 'camera'
      WHEN lower(a.bucket) LIKE 'download%' THEN 'downloads'
      WHEN lower(a.bucket) LIKE '%instagram%' THEN 'instagram'
      ELSE 'other' END''';

  Future<StorageData> load({DateTime? now}) async {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final safe = safeWhere(t);
    final total = await db.customSelect('SELECT COALESCE(SUM(a.size_bytes), 0) AS b FROM assets a WHERE a.id NOT IN (SELECT asset_id FROM trash_items)').getSingle();
    final safeRow = await db.customSelect('SELECT COALESCE(SUM(a.size_bytes), 0) AS b FROM assets a WHERE $safe').getSingle();

    Future<List<StorageTile>> cut(String expr) async {
      final rows = await db.customSelect('''
        SELECT $expr AS k, COUNT(*) AS n, SUM(a.size_bytes) AS b,
               SUM(CASE WHEN $safe THEN a.size_bytes ELSE 0 END) AS r
        FROM assets a WHERE a.id NOT IN (SELECT asset_id FROM trash_items)
        GROUP BY k
      ''').get();
      return [for (final r in rows) StorageTile(key: r.read<String>('k'), count: r.read<int>('n'), bytes: r.read<int>('b'), reclaim: r.read<int>('r'))];
    }

    final months = await cut(_monthExpr)
      ..sort((a, b) => b.key.compareTo(a.key));
    final shown = months.take(monthTiles).toList();
    final older = months.skip(monthTiles).toList();
    if (older.isNotEmpty) {
      shown.add(StorageTile(
        key: 'earlier',
        count: older.fold(0, (s, e) => s + e.count),
        bytes: older.fold(0, (s, e) => s + e.bytes),
        reclaim: older.fold(0, (s, e) => s + e.reclaim),
      ));
    }

    final wins = <QuickWinStat>[];
    for (final w in QuickWin.values) {
      final r = await db.customSelect('SELECT COUNT(*) AS n, COALESCE(SUM(a.size_bytes), 0) AS b FROM assets a WHERE ($quickWinGuard) AND (${quickWinWhere(w, t)})').getSingle();
      wins.add(QuickWinStat(win: w, count: r.read<int>('n'), bytes: r.read<int>('b')));
    }

    return StorageData(
      totalBytes: total.read<int>('b'),
      safeBytes: safeRow.read<int>('b'),
      cuts: {
        StorageCut.months: shown,
        StorageCut.types: await cut(_typeExpr),
        StorageCut.sources: await cut(_sourceExpr),
      },
      wins: wins,
    );
  }
}
