import 'dart:async';

import 'package:drift/drift.dart' show Variable;

import '../data/database.dart';
import '../l10n/l10n.dart';
import '../platform/widgets.dart';
import 'session_service.dart';
import 'storage_service.dart';

/// Writes the numbers of the home screen widgets: today's progress, the streak
/// and what can be freed. Texts are translated here, the widgets only draw them.
class WidgetSync {
  WidgetSync(this.db);
  final SweeepDatabase db;

  static Timer? _timer;
  static String? _canFreeNum;
  static String _canFreeUnit = 'GB';

  /// After a swipe, a finished session or a regroup; coalesces bursts.
  static void schedule(SweeepDatabase db, {bool canFree = false}) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800),
        () => WidgetSync(db).refresh(canFree: canFree).catchError((_) {}));
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> doneToday(DateTime now) async {
    final from = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final r = await db.customSelect(
        'SELECT COUNT(*) AS n FROM decisions WHERE decided_at_ms >= ?',
        variables: [Variable.withInt(from)]).getSingle();
    return r.read<int>('n');
  }

  Future<void> refresh({bool canFree = true, DateTime? now}) async {
    final t = now ?? DateTime.now();
    final svc = SessionService(db);
    final goal = await svc.goal();
    final done = await doneToday(t);
    final streak = (await svc.streak(now: t)).current;
    if (canFree || _canFreeNum == null) {
      final bytes = (await StorageService(db).load()).safeBytes;
      const gib = 1024 * 1024 * 1024;
      final u = l10n.byteUnits.split(',');
      if (bytes >= gib * .95) {
        _canFreeNum = fmtNum(bytes / gib, digits: 1);
        _canFreeUnit = u[3];
      } else {
        _canFreeNum = fmtNum(bytes / (1024 * 1024), digits: 0);
        _canFreeUnit = u[2];
      }
    }
    final left = (goal - done).clamp(0, goal);
    await HomeWidgets.save({
      'day': dayKey(t),
      'done': done,
      'goal': goal,
      'streak': streak,
      'canFreeNum': _canFreeNum,
      'canFreeUnit': _canFreeUnit,
      'tOf': l10n.wOfToday(goal),
      'tLeftNow':
          done == 0 ? l10n.wLeftStreak(left, streak + 1) : l10n.wLeftGoal(left),
      'tGoalReached': l10n.wGoalReached,
      'tLeftNew': l10n.wLeftStreak(goal, streak + 1),
      'tLeftNew0': l10n.wLeftStreak(goal, 1),
      'tStreak': l10n.weekStreak(streak),
      'tStreakZero': l10n.wStreakNone,
      'tContinue': l10n.wContinue,
      'tSwipe': l10n.wSwipeNow(25),
      'tAbout': l10n.wAbout(2),
      'tCanFree': l10n.wCanFree,
      'tTapMap': l10n.wTapMap,
      'tEmpty': l10n.wEmpty,
    });
  }
}
