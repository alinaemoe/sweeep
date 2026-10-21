import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/list_chrome.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/goal_service.dart';
import '../../index/review_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../category/category_screen.dart';
import '../groups/group_widgets.dart';

/// Test builds (`--dart-define=GOAL_DEMO=true`) count the goal in MB instead of
/// GB, so a small test library can show every state of the screen.
const _demo = bool.fromEnvironment('GOAL_DEMO');
const _unit = _demo ? 1024 * 1024 : 1024 * 1024 * 1024;

String _unitName() => l10n.byteUnits.split(',')[_demo ? 2 : 3];

/// 5.3 GB, or the plain size when it is tiny (a few MB or KB).
String goalSize(int bytes) => bytes < _unit * .1 ? formatBytes(bytes) : '${fmtNum(bytes / _unit, digits: 1)} ${_unitName()}';

String _ruleTitle(GoalRule r) => switch (r) {
      GoalRule.duplicates => l10n.qwDups,
      GoalRule.oldScreenshots => l10n.qwOldShots,
      GoalRule.blurry => l10n.qwBlurry,
      GoalRule.chatLeftovers => l10n.qwChat,
      GoalRule.longRecordings => l10n.qwRecs,
      GoalRule.similar => l10n.secSimilar,
    };

String _ruleSub(GoalRule r) => switch (r) {
      GoalRule.duplicates => l10n.goalSubDup,
      GoalRule.oldScreenshots => l10n.goalSubOldShots,
      GoalRule.blurry => l10n.goalSubBlurry,
      GoalRule.chatLeftovers => l10n.goalSubChat,
      GoalRule.longRecordings => l10n.goalSubRecs,
      GoalRule.similar => l10n.goalSubSimilar,
    };

/// Free by goal (D15): say how many GB you need; Sweeep takes the safest
/// groups of files first and stops once there is enough. The button opens a
/// list to confirm, never the trash directly.
class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  static const goals = [1, 3, 5, 8];
  int _goal = 5;

  Future<void> _review(GoalPlan plan) async {
    final items = plan.pickedItems(_goal * _unit);
    if (items.isEmpty) return;
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CategoryScreen(kind: CategoryKind.quickWin, preset: items)));
    ref.invalidate(goalPlanProvider);
    ref.invalidate(storageProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(trashSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(goalPlanProvider);
    final plan = async.value;
    final goalBytes = _goal * _unit;
    final on = plan?.pick(goalBytes) ?? const <bool>[];
    final picked = plan?.pickedBytes(goalBytes) ?? 0;
    final total = plan?.totalBytes ?? 0;
    final enough = picked >= goalBytes;
    return Scaffold(
      body: Stack(children: [
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 170),
            children: [
              const ListBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.goalLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: SweeepColors.textMutedSmall)),
                  const SizedBox(height: 4),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$_goal', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800, letterSpacing: -3, height: .95)),
                    const SizedBox(width: 8),
                    Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(_unitName(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: SweeepColors.brand))),
                  ]),
                  const SizedBox(height: 6),
                  Text(l10n.goalSub, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall, height: 1.35)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  for (final g in goals) ...[
                    _GoalChip(label: '$g ${_unitName()}', on: g == _goal, onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _goal = g);
                    }),
                    if (g != goals.last) const SizedBox(width: 8),
                  ],
                ]),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: SweeepColors.cardBorder)),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Expanded(child: Text(l10n.goalPicked(goalSize(picked)), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                    Text(
                      enough ? l10n.goalReached : l10n.goalAllFound(goalSize(total)),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: enough ? SweeepColors.brand : SweeepColors.trash),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (_, c) => ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        height: 10,
                        alignment: Alignment.centerLeft,
                        color: SweeepColors.trackUsed,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: const Cubic(.2, .8, .2, 1),
                          width: c.maxWidth * (goalBytes == 0 ? 0 : (picked / goalBytes).clamp(0.0, 1.0)),
                          height: 10,
                          decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Expanded(child: Text(l10n.goalWhatFirst, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5))),
                  Text(l10n.goalSafestTop, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
                ]),
              ),
              if (plan != null)
                for (var i = 0; i < plan.rows.length; i++) _RuleRow(row: plan.rows[i], on: on[i]),
              if (plan == null && async.isLoading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: SweeepColors.brand))),
              if (plan != null && plan.rows.isEmpty)
                Padding(padding: const EdgeInsets.all(28), child: Center(child: Text(l10n.nothingLeft, style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 16)))),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SweeepColors.card.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.goalNote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
              const SizedBox(height: 8),
              PillButton(height: 52, label: l10n.goalReview(goalSize(picked)), onPressed: plan == null || picked == 0 ? null : () => _review(plan)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                constraints: const BoxConstraints(minWidth: 62),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? SweeepColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? SweeepColors.brand : Colors.white.withValues(alpha: .12)),
                ),
                child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: on ? SweeepColors.onAccent : SweeepColors.text)),
              ),
            ),
          ),
        ),
      );
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.row, required this.on});
  final GoalRow row;
  final bool on;

  @override
  Widget build(BuildContext context) {
    const off = Color(0xFF2E3040);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: on ? 1 : .45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SweeepColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? SweeepColors.brand.withValues(alpha: .5) : Colors.white.withValues(alpha: .06)),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? SweeepColors.brand : Colors.transparent,
              border: on ? null : Border.all(color: Colors.white.withValues(alpha: .25), width: 1.5),
            ),
            child: Icon(Icons.check_rounded, size: 14, color: on ? SweeepColors.onAccent : Colors.transparent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_ruleTitle(row.rule), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -.2)),
              const SizedBox(height: 3),
              Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: SweeepColors.brand)),
                const SizedBox(width: 3),
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: row.level >= 2 ? SweeepColors.brand : off)),
                const SizedBox(width: 3),
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: row.level >= 3 ? SweeepColors.brand : off)),
                const SizedBox(width: 6),
                Expanded(child: Text(_ruleSub(row.rule), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall))),
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          Text(goalSize(row.bytes), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.3)),
        ]),
      ),
    );
  }
}

/// The way in, from the Storage map and from Tools.
class GoalEntryCard extends StatelessWidget {
  const GoalEntryCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: l10n.goalEntryTitle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: SweeepColors.cardBorder)),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: SweeepColors.brand.withValues(alpha: .16)),
                child: const Icon(Icons.flag_rounded, size: 22, color: SweeepColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.goalEntryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.3)),
                  const SizedBox(height: 2),
                  Text(l10n.goalEntrySub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: SweeepColors.textMutedSmall),
            ]),
          ),
        ),
      );
}
