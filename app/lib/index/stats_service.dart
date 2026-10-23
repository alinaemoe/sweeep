import 'package:drift/drift.dart';

import '../data/database.dart';
import 'session_service.dart' show computeStreak;

/// One day of the weekly report.
class DayStat {
  const DayStat({required this.day, this.swept = 0, this.kept = 0, this.clearedFiles = 0, this.clearedBytes = 0, this.sessions = 0});
  final DateTime day;
  final int swept;
  final int kept;
  final int clearedFiles;
  final int clearedBytes;

  /// Recorded Cleanup sessions that day.
  final int sessions;

  /// What the report calls a sitting: the recorded sessions, at least one on any day with swiping.
  int get sittings => sessions > 0 ? sessions : (swept > 0 ? 1 : 0);
}

enum WeekCategory { duplicates, similar, screenshots, blurry, other }

/// A Monday to Sunday week, ready to show.
class WeekReport {
  const WeekReport({
    required this.start,
    required this.days,
    required this.goal,
    required this.streak,
    required this.cats,
    required this.prevClearedBytes,
    required this.usedFrom,
    required this.usedTo,
    required this.isCurrent,
  });

  final DateTime start;
  final List<DayStat> days;
  final int goal;

  /// Days in a row up to the end of this week (or today).
  final int streak;
  final Map<WeekCategory, int> cats;

  /// Bytes cleared the week before; null when there is no earlier history at all.
  final int? prevClearedBytes;
  final int? usedFrom;
  final int? usedTo;
  final bool isCurrent;

  DateTime get end => start.add(const Duration(days: 6));
  int get swept => days.fold(0, (t, d) => t + d.swept);
  int get kept => days.fold(0, (t, d) => t + d.kept);
  int get clearedFiles => days.fold(0, (t, d) => t + d.clearedFiles);
  int get clearedBytes => days.fold(0, (t, d) => t + d.clearedBytes);
  int get goalsHit => days.where((d) => d.swept >= goal).length;
  int get maxDay => days.fold(0, (m, d) => d.swept > m ? d.swept : m);
}

/// Every week since the first recorded day. Pure: built from table rows.
class WeekBook {
  WeekBook._(this._rows, this.today, this.goal, this._usedNow);

  factory WeekBook.from(List<DailyStat> rows, {required DateTime today, required int goal, int? usedNow}) => WeekBook._(rows, DateTime(today.year, today.month, today.day), goal, usedNow);

  final List<DailyStat> _rows;
  final DateTime today;
  final int goal;
  final int? _usedNow;

  static DateTime monday(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  static DateTime _parse(String day) {
    final p = day.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  DateTime? get firstDay {
    DateTime? f;
    for (final r in _rows) {
      if (r.swept == 0 && r.sessions == 0 && r.clearedBytes == 0) continue;
      final d = _parse(r.day);
      if (f == null || d.isBefore(f)) f = d;
    }
    return f;
  }

  /// Weeks to page through, the current one included (at least 1).
  int get count {
    final f = firstDay;
    if (f == null) return 1;
    final n = (monday(today).difference(monday(f)).inDays / 7).round() + 1;
    return n < 1 ? 1 : n;
  }

  /// [back] = 0 is this week, 1 the week before, ...
  WeekReport week(int back) {
    final start = DateTime(monday(today).year, monday(today).month, monday(today).day - 7 * back);
    final byDay = {for (final r in _rows) r.day: r};
    String key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    DayStat dayOf(DateTime d) {
      final r = byDay[key(d)];
      if (r == null) return DayStat(day: d);
      return DayStat(day: d, swept: r.swept, kept: r.kept, clearedFiles: r.clearedFiles, clearedBytes: r.clearedBytes, sessions: r.sessions);
    }

    DateTime at(int i) => DateTime(start.year, start.month, start.day + i);
    final days = [for (var i = 0; i < 7; i++) dayOf(at(i))];
    final cats = {for (final c in WeekCategory.values) c: 0};
    for (final d in days) {
      final r = byDay[key(d.day)];
      if (r == null) continue;
      cats[WeekCategory.duplicates] = cats[WeekCategory.duplicates]! + r.catDups;
      cats[WeekCategory.similar] = cats[WeekCategory.similar]! + r.catSimilar;
      cats[WeekCategory.screenshots] = cats[WeekCategory.screenshots]! + r.catShots;
      cats[WeekCategory.blurry] = cats[WeekCategory.blurry]! + r.catBlurry;
      cats[WeekCategory.other] = cats[WeekCategory.other]! + r.catOther;
    }

    final sunday = at(6);
    final upTo = sunday.isAfter(today) ? today : sunday;
    final swept = {for (final r in _rows) if (r.swept > 0 && !_parse(r.day).isAfter(upTo)) _parse(r.day)};
    final streak = computeStreak(swept, upTo).current;

    final isCurrent = back == 0;
    final hasPrev = back < count - 1;
    final prevBytes = hasPrev ? week(back + 1).clearedBytes : null;

    // storage: the first value seen this week (or the last one before it) to the last one
    int? from;
    int? to;
    final sorted = [...byDay.values.where((r) => r.usedPct != null)]..sort((a, b) => a.day.compareTo(b.day));
    for (final r in sorted) {
      final d = _parse(r.day);
      if (d.isBefore(start)) {
        from = r.usedPct;
      } else if (!d.isAfter(sunday)) {
        from ??= r.usedPct;
        to = r.usedPct;
      }
    }
    if (isCurrent && _usedNow != null) to = _usedNow;
    return WeekReport(start: start, days: days, goal: goal, streak: streak, cats: cats, prevClearedBytes: prevBytes, usedFrom: from, usedTo: to, isCurrent: isCurrent);
  }
}

class StatsService {
  StatsService(this.db);
  final SweeepDatabase db;

  static String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Writes what the decisions say today into `daily_stats` (counts only grow),
  /// plus the phone storage seen now. Run before anything deletes files for good.
  Future<void> snapshot({DateTime? now, int? usedPct}) async {
    await db.customStatement(statsSnapshotSql);
    await db.customStatement(statsSessionsSql);
    if (usedPct != null) {
      await db.customInsert(
        'INSERT INTO daily_stats (day, used_pct) VALUES (?, ?) ON CONFLICT(day) DO UPDATE SET used_pct = excluded.used_pct',
        variables: [Variable.withString(dayKey(now ?? DateTime.now())), Variable.withInt(usedPct)],
      );
    }
  }

  Future<List<DailyStat>> rows() => db.select(db.dailyStats).get();

  Future<WeekBook> book({DateTime? now, required int goal, int? usedNow}) async => WeekBook.from(await rows(), today: now ?? DateTime.now(), goal: goal, usedNow: usedNow);

  /// Bytes sitting in the app trash right now.
  Future<int> waitingBytes() async {
    final r = await db.customSelect('SELECT COALESCE(SUM(size_bytes), 0) AS b FROM trash_items').getSingle();
    return r.read<int>('b');
  }
}
