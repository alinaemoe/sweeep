import 'package:drift/drift.dart' show Variable;

import '../data/database.dart';
import 'session_service.dart';

/// Everything the Month wrap card shows for one finished month.
class MonthWrapData {
  const MonthWrapData({
    required this.monthKey,
    required this.looked,
    required this.kept,
    required this.trashed,
    required this.freedBytes,
    required this.best,
    required this.sessions,
    required this.streak,
    required this.nextMonth,
  });

  final String monthKey; // 'YYYY-MM'
  final int looked;
  final int kept;
  final int trashed;
  final int freedBytes;

  /// Asset ids of the sharpest kept photos, one per group of lookalikes (at most 6).
  final List<String> best;
  final int sessions;
  final int streak;

  /// The next month that still has photos to decide, or null.
  final String? nextMonth;
}

/// Month wrap: when a month reaches 100% decided, show a one-time summary.
/// Reads only `decisions`, `trash_items`, `assets`, `hashes` and `sessions`.
class MonthWrapService {
  MonthWrapService(this.db);
  final SweeepDatabase db;

  static String keyOf(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  }

  static (int, int) _range(String key) {
    final y = int.parse(key.substring(0, 4));
    final m = int.parse(key.substring(5));
    return (DateTime(y, m).millisecondsSinceEpoch, DateTime(y, m + 1).millisecondsSinceEpoch);
  }

  static const _decided = '(a.id IN (SELECT asset_id FROM decisions) OR a.id IN (SELECT asset_id FROM trash_items))';
  static const _trashedExpr = '(a.id IN (SELECT asset_id FROM trash_items) OR a.id IN (SELECT asset_id FROM decisions WHERE decision = 1))';

  String _shownKey(String key) => 'wrap_shown_$key';

  Future<bool> shown(String key) async => (await (db.select(db.scanState)..where((s) => s.key.equals(_shownKey(key)))).getSingleOrNull()) != null;

  Future<void> markShown(String key) => db.into(db.scanState).insertOnConflictUpdate(ScanStateCompanion.insert(key: _shownKey(key), value: '1'));

  /// How many photos the month has and how many are decided.
  Future<(int, int)> progress(String key) async {
    final (from, to) = _range(key);
    final r = await db.customSelect('''
      SELECT COUNT(*) AS n, COALESCE(SUM(CASE WHEN $_decided THEN 1 ELSE 0 END), 0) AS d
      FROM assets a WHERE a.media_type = 0 AND a.created_at_ms >= ? AND a.created_at_ms < ?
    ''', variables: [Variable.withInt(from), Variable.withInt(to)]).getSingle();
    return (r.read<int>('n'), r.read<int>('d'));
  }

  /// After a decision on a photo made at [createdAtMs]: the month key if that
  /// month just reached 100% and its wrap was not shown yet.
  Future<String?> pendingFor(int createdAtMs) async {
    final key = keyOf(createdAtMs);
    final (n, d) = await progress(key);
    if (n == 0 || d < n) return null;
    return await shown(key) ? null : key;
  }

  Future<MonthWrapData> data(String key) async {
    final (from, to) = _range(key);
    final range = [Variable.withInt(from), Variable.withInt(to)];
    final r = await db.customSelect('''
      SELECT
        COALESCE(SUM(CASE WHEN $_decided THEN 1 ELSE 0 END), 0) AS looked,
        COALESCE(SUM(CASE WHEN a.id IN (SELECT asset_id FROM decisions WHERE decision = 0) AND a.id NOT IN (SELECT asset_id FROM trash_items) THEN 1 ELSE 0 END), 0) AS kept,
        COALESCE(SUM(CASE WHEN $_trashedExpr THEN 1 ELSE 0 END), 0) AS trashed,
        COALESCE(SUM(CASE WHEN $_trashedExpr THEN a.size_bytes ELSE 0 END), 0) AS freed
      FROM assets a WHERE a.media_type = 0 AND a.created_at_ms >= ? AND a.created_at_ms < ?
    ''', variables: range).getSingle();

    // sharpest kept photos first; only one of each group of lookalikes
    final rows = await db.customSelect('''
      SELECT a.id AS id, (SELECT MIN(gm.group_id) FROM group_members gm WHERE gm.asset_id = a.id) AS grp
      FROM assets a JOIN hashes h ON h.asset_id = a.id
      WHERE a.media_type = 0 AND a.created_at_ms >= ? AND a.created_at_ms < ?
        AND a.id IN (SELECT asset_id FROM decisions WHERE decision = 0)
        AND a.id NOT IN (SELECT asset_id FROM trash_items)
        AND h.laplacian_var IS NOT NULL
      ORDER BY h.laplacian_var DESC LIMIT 80
    ''', variables: range).get();
    final best = <String>[];
    final seen = <int>{};
    for (final row in rows) {
      final g = row.read<int?>('grp');
      if (g != null && !seen.add(g)) continue;
      best.add(row.read<String>('id'));
      if (best.length == 6) break;
    }

    // sessions that ran while this month's photos were being decided
    final span = await db.customSelect('''
      SELECT MIN(d.decided_at_ms) AS lo, MAX(d.decided_at_ms) AS hi
      FROM decisions d JOIN assets a ON a.id = d.asset_id
      WHERE a.media_type = 0 AND a.created_at_ms >= ? AND a.created_at_ms < ?
    ''', variables: range).getSingle();
    final lo = span.read<int?>('lo');
    final hi = span.read<int?>('hi');
    var sessions = 0;
    if (lo != null && hi != null) {
      final c = await db.customSelect('SELECT COUNT(*) AS n FROM sessions WHERE ended_ms >= ? AND started_ms <= ?', variables: [Variable.withInt(lo), Variable.withInt(hi)]).getSingle();
      sessions = c.read<int>('n');
      // plain swiping counts too: every day this month was swiped on is one sitting
      final days = await db.customSelect('''
        SELECT COUNT(DISTINCT date(d.decided_at_ms / 1000, 'unixepoch', 'localtime')) AS n
        FROM decisions d JOIN assets a ON a.id = d.asset_id
        WHERE a.media_type = 0 AND a.created_at_ms >= ? AND a.created_at_ms < ?
      ''', variables: range).getSingle();
      final n = days.read<int>('n');
      if (n > sessions) sessions = n;
    }

    return MonthWrapData(
      monthKey: key,
      looked: r.read<int>('looked'),
      kept: r.read<int>('kept'),
      trashed: r.read<int>('trashed'),
      freedBytes: r.read<int>('freed'),
      best: best,
      sessions: sessions,
      streak: (await SessionService(db).streak()).current,
      nextMonth: await nextUnswept(key),
    );
  }

  /// The first month after [key] (oldest first) that still has undecided photos.
  Future<String?> nextUnswept(String key) async {
    final rows = await db.customSelect('''
      SELECT strftime('%Y-%m', a.created_at_ms / 1000, 'unixepoch', 'localtime') AS m
      FROM assets a
      WHERE a.media_type = 0 AND NOT $_decided
      GROUP BY m ORDER BY m
    ''').get();
    for (final r in rows) {
      final m = r.read<String>('m');
      if (m.compareTo(key) > 0) return m;
    }
    return null;
  }
}
