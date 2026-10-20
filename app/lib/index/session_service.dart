import 'package:drift/drift.dart' show Variable;

import '../data/database.dart';
import 'review_service.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _monday(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

/// Where the streak stands. A day counts when at least one photo was decided
/// in it. Once a week one missed day is forgiven (the "freeze").
class StreakInfo {
  const StreakInfo({required this.current, required this.best, required this.todayDone, required this.freezeLeft});
  final int current;
  final int best;
  final bool todayDone;

  /// This week's freeze has not been needed yet.
  final bool freezeLeft;
}

/// Pure streak maths over the set of days that had a decision, as of [today].
StreakInfo computeStreak(Set<DateTime> daysIn, DateTime today) {
  final days = {for (final d in daysIn) _day(d)};
  final t = _day(today);
  final todayDone = days.contains(t);
  if (days.isEmpty) return const StreakInfo(current: 0, best: 0, todayDone: false, freezeLeft: true);
  final first = days.reduce((a, b) => a.isBefore(b) ? a : b);
  final usedWeeks = <DateTime>{};
  var run = 0;
  var best = 0;
  // today is still open until midnight, so an empty today never breaks the run
  final last = todayDone ? t : t.subtract(const Duration(days: 1));
  for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
    if (days.contains(d)) {
      run++;
      if (run > best) best = run;
    } else {
      final next = d.add(const Duration(days: 1));
      final week = _monday(d);
      final canBridge = run > 0 && !usedWeeks.contains(week) && (days.contains(next) || next == t);
      if (canBridge) {
        usedWeeks.add(week);
      } else {
        run = 0;
      }
    }
  }
  return StreakInfo(current: run, best: best, todayDone: todayDone, freezeLeft: !usedWeeks.contains(_monday(t)));
}

class MonthProgress {
  const MonthProgress({required this.key, required this.count, required this.swept});
  final String key; // 'YYYY-MM'
  final int count;
  final int swept;

  int get percent => count == 0 ? 100 : (swept * 100 / count).floor();
  int get left => count - swept;
}

class SessionOverview {
  const SessionOverview({required this.streak, required this.week, required this.todayIndex, required this.months, required this.target, required this.goal});
  final StreakInfo streak;

  /// Monday to Sunday of this week: a decision happened that day.
  final List<bool> week;
  final int todayIndex;

  /// Oldest months first: a short window around where the clean-up stands.
  final List<MonthProgress> months;

  /// The month the next session starts with (oldest one not fully swept).
  final MonthProgress? target;
  final int goal;
}

/// A deck for one session: lookalikes first, then the rest of the oldest
/// unfinished month, then the next month.
class SessionPlan {
  const SessionPlan({required this.items, required this.startMonth});
  final List<SwipeItem> items;
  final String? startMonth;
}

/// What the Session done screen shows after a run.
class SessionResult {
  const SessionResult({
    required this.swept,
    required this.trashed,
    required this.bytes,
    required this.duration,
    required this.goal,
    required this.streakBefore,
    required this.streakAfter,
    required this.monthKey,
    required this.percentBefore,
    required this.percentAfter,
    required this.monthLeft,
  });
  final int swept;
  final int trashed;
  final int bytes;
  final Duration duration;
  final int goal;
  final StreakInfo streakBefore;
  final StreakInfo streakAfter;

  /// The month the session started with, and how far it got.
  final String? monthKey;
  final int percentBefore;
  final int percentAfter;
  final int monthLeft;

  int get kept => swept - trashed;
}

/// Streak, week and month progress for the Cleanup session screens, built
/// only from `decisions`, plus the sessions table and a few saved choices.
class SessionService {
  SessionService(this.db);
  final SweeepDatabase db;

  static const goals = [25, 50, 100];
  static const _goalKey = 'session_goal';
  static const reminderOnKey = 'reminder_on';
  static const reminderMinutesKey = 'reminder_minutes';
  static const defaultReminderMinutes = 20 * 60;

  Future<String?> _pref(String key) async => (await (db.select(db.scanState)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setPref(String key, String value) => db.into(db.scanState).insertOnConflictUpdate(ScanStateCompanion.insert(key: key, value: value));

  Future<int> goal() async {
    final g = int.tryParse(await _pref(_goalKey) ?? '');
    return goals.contains(g) ? g! : 50;
  }

  Future<void> setGoal(int g) => _setPref(_goalKey, '$g');

  Future<bool> reminderOn() async => (await _pref(reminderOnKey)) == '1';

  Future<int> reminderMinutes() async => int.tryParse(await _pref(reminderMinutesKey) ?? '') ?? defaultReminderMinutes;

  Future<void> setReminder({required bool on, int? minutes}) async {
    await _setPref(reminderOnKey, on ? '1' : '0');
    if (minutes != null) await _setPref(reminderMinutesKey, '$minutes');
  }

  Future<Set<DateTime>> decisionDays() async {
    final rows = await db.customSelect("SELECT DISTINCT date(decided_at_ms / 1000, 'unixepoch', 'localtime') AS d FROM decisions").get();
    return {for (final r in rows) DateTime.parse(r.read<String>('d'))};
  }

  Future<StreakInfo> streak({DateTime? now}) async => computeStreak(await decisionDays(), now ?? DateTime.now());

  Future<SessionOverview> overview({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final days = await decisionDays();
    final mon = _monday(t);
    final months = (await ReviewService(db).months()).reversed.map((m) => MonthProgress(key: m.key, count: m.count, swept: m.swept)).toList();
    final firstOpen = months.indexWhere((m) => m.percent < 100);
    final from = firstOpen < 0 ? (months.length - 5).clamp(0, months.length) : (firstOpen - 2).clamp(0, months.length);
    return SessionOverview(
      streak: computeStreak(days, t),
      week: [for (var i = 0; i < 7; i++) days.contains(mon.add(Duration(days: i)))],
      todayIndex: t.weekday - 1,
      months: months.skip(from).take(5).toList(),
      target: firstOpen < 0 ? null : months[firstOpen],
      goal: await goal(),
    );
  }

  /// [goal] photos, oldest unfinished month first, lookalikes (duplicate and
  /// similar groups) ahead of the rest of that month.
  Future<SessionPlan> plan(int goal) async {
    final months = (await ReviewService(db).months()).reversed.where((m) => m.swept < m.count).toList();
    final items = <SwipeItem>[];
    String? start;
    for (final m in months) {
      if (items.length >= goal) break;
      start ??= m.key;
      final rows = await db.customSelect('''
        SELECT a.id AS id, a.size_bytes AS size, a.created_at_ms AS t,
               CASE WHEN a.id IN (SELECT asset_id FROM group_members) THEN 0 ELSE 1 END AS grp
        FROM assets a
        WHERE a.media_type = 0
          AND strftime('%Y-%m', a.created_at_ms / 1000, 'unixepoch', 'localtime') = ?
          AND a.id NOT IN (SELECT asset_id FROM trash_items)
          AND a.id NOT IN (SELECT asset_id FROM decisions)
        ORDER BY grp, a.created_at_ms
        LIMIT ${goal - items.length}
      ''', variables: [Variable.withString(m.key)]).get();
      for (final r in rows) {
        items.add(SwipeItem(id: r.read<String>('id'), sizeBytes: r.read<int>('size'), createdAtMs: r.read<int>('t')));
      }
    }
    return SessionPlan(items: items, startMonth: start);
  }

  /// Saves the run and gathers the numbers for the Session done screen.
  Future<SessionResult> finish({
    required DateTime started,
    required int goal,
    required int swept,
    required int trashed,
    required int bytes,
    required StreakInfo streakBefore,
    required String? monthKey,
    required int percentBefore,
  }) async {
    await record(started: started, goal: goal, swept: swept, trashed: trashed, bytes: bytes);
    final months = await ReviewService(db).months();
    final m = monthKey == null ? null : months.where((e) => e.key == monthKey).firstOrNull;
    return SessionResult(
      swept: swept,
      trashed: trashed,
      bytes: bytes,
      duration: DateTime.now().difference(started),
      goal: goal,
      streakBefore: streakBefore,
      streakAfter: await streak(),
      monthKey: monthKey,
      percentBefore: percentBefore,
      percentAfter: m == null ? 100 : MonthProgress(key: m.key, count: m.count, swept: m.swept).percent,
      monthLeft: m == null ? 0 : m.count - m.swept,
    );
  }

  Future<void> record({required DateTime started, required int goal, required int swept, required int trashed, required int bytes}) =>
      db.into(db.sessions).insert(SessionsCompanion.insert(
          startedMs: started.millisecondsSinceEpoch, endedMs: DateTime.now().millisecondsSinceEpoch, goal: goal, swept: swept, trashed: trashed, bytes: bytes));
}
