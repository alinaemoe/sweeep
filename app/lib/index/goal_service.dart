import '../data/database.dart';
import 'review_service.dart';
import 'storage_service.dart';

/// The rules behind "Free by goal", safest first. The order is the order of
/// the list on the screen and the order files are taken in.
enum GoalRule { duplicates, oldScreenshots, blurry, chatLeftovers, longRecordings, similar }

/// How sure we are that clearing it is fine: 3 = identical or plainly stale,
/// 2 = very likely, 1 = a choice (the best one of a group always stays).
int goalLevel(GoalRule r) => switch (r) {
      GoalRule.duplicates || GoalRule.oldScreenshots => 3,
      GoalRule.blurry || GoalRule.chatLeftovers || GoalRule.longRecordings => 2,
      GoalRule.similar => 1,
    };

class GoalRow {
  const GoalRow({required this.rule, required this.items});
  final GoalRule rule;

  /// Files only this rule claims: a file that an earlier rule already took is not counted twice.
  final List<CategoryItem> items;

  int get count => items.length;
  int get bytes => items.fold(0, (s, e) => s + e.sizeBytes);
  int get level => goalLevel(rule);
}

class GoalPlan {
  const GoalPlan(this.rows);
  final List<GoalRow> rows;

  int get totalBytes => rows.fold(0, (s, r) => s + r.bytes);

  /// Which rows go into a goal of [goalBytes]: take rows from the top while
  /// what is picked so far is still short of the goal. The row that crosses
  /// the line is taken whole.
  List<bool> pick(int goalBytes) {
    var sum = 0;
    return [
      for (final r in rows)
        () {
          final on = sum < goalBytes;
          if (on) sum += r.bytes;
          return on;
        }(),
    ];
  }

  int pickedBytes(int goalBytes) {
    final on = pick(goalBytes);
    var sum = 0;
    for (var i = 0; i < rows.length; i++) {
      if (on[i]) sum += rows[i].bytes;
    }
    return sum;
  }

  /// The files of the picked rows.
  List<CategoryItem> pickedItems(int goalBytes) {
    final on = pick(goalBytes);
    return [
      for (var i = 0; i < rows.length; i++)
        if (on[i]) ...rows[i].items,
    ];
  }
}

/// Builds the plan for "I need N GB": every rule from Quick wins plus the
/// extras of similar groups, safest first, each file counted once.
class GoalService {
  GoalService(this.db);
  final SweeepDatabase db;

  String _where(GoalRule r, int nowMs) => switch (r) {
        GoalRule.duplicates => quickWinWhere(QuickWin.duplicates, nowMs),
        GoalRule.oldScreenshots => quickWinWhere(QuickWin.oldScreenshots, nowMs),
        GoalRule.blurry => quickWinWhere(QuickWin.blurry, nowMs),
        GoalRule.chatLeftovers => quickWinWhere(QuickWin.chatLeftovers, nowMs),
        GoalRule.longRecordings => quickWinWhere(QuickWin.longRecordings, nowMs),
        GoalRule.similar => groupExtras(1),
      };

  Future<GoalPlan> load({DateTime? now}) async {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final taken = <String>{};
    final rows = <GoalRow>[];
    for (final rule in GoalRule.values) {
      final res = await db.customSelect('''
        SELECT a.id AS id, a.size_bytes AS size, a.created_at_ms AS t, a.media_type AS mt, a.duration_ms AS dur, a.chat_source AS cs
        FROM assets a WHERE ($quickWinGuard) AND (${_where(rule, t)})
        ORDER BY a.size_bytes DESC
      ''').get();
      final items = <CategoryItem>[];
      for (final r in res) {
        final id = r.read<String>('id');
        if (!taken.add(id)) continue;
        items.add(CategoryItem(
          id: id,
          sizeBytes: r.read<int>('size'),
          createdAtMs: r.read<int>('t'),
          isVideo: r.read<int>('mt') == 1,
          durationMs: r.read<int?>('dur'),
          chatSource: r.read<String?>('cs'),
        ));
      }
      if (items.isNotEmpty) rows.add(GoalRow(rule: rule, items: items));
    }
    return GoalPlan(rows);
  }
}
