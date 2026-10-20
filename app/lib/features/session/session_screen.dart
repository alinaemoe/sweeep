import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/review_service.dart';
import '../../index/session_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../swipe/swipe_screen.dart';
import 'reminder_sheet.dart';

/// Cleanup session (D12): pick a goal, see the streak, the week and how far
/// the oldest months are swept, then start.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> with TickerProviderStateMixin {
  int? _goal;
  bool _starting = false;

  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  late final AnimationController _rise = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _loop.dispose();
    _rise.dispose();
    super.dispose();
  }

  Future<void> _start(SessionOverview o, int goal) async {
    if (_starting) return;
    setState(() => _starting = true);
    final plan = await ref.read(sessionServiceProvider).plan(goal);
    if (!mounted) return;
    setState(() => _starting = false);
    if (plan.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sessNothing)));
      return;
    }
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SwipeScreen.session(plan: plan, goal: goal, before: o.streak, targetPercent: o.target?.percent ?? 100)));
    ref.invalidate(sessionOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sessionOverviewProvider);
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SweeepColors.brand)),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: SweeepColors.textMutedSmall))),
          data: _body,
        ),
      ),
    );
  }

  Widget _rise_(double delay, Widget child) => AnimatedBuilder(
        animation: _rise,
        builder: (_, c) {
          final t = Curves.easeOut.transform(((_rise.value * 900 - delay) / 600).clamp(0.0, 1.0));
          return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: c));
        },
        child: child,
      );

  Widget _body(SessionOverview o) {
    final goal = _goal ?? o.goal;
    final streak = o.streak;
    return Stack(children: [
      GlowOrb(left: MediaQuery.sizeOf(context).width / 2 - 150, top: 150, width: 300, height: 300, color: SweeepColors.brand.withValues(alpha: .16), blur: 80),
      ListView(
        padding: const EdgeInsets.only(bottom: 150),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.back,
                icon: const Icon(Icons.chevron_left_rounded),
                style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => showReminderSheet(context, ref),
                tooltip: l10n.remTitle,
                icon: const Icon(Icons.notifications_none_rounded, size: 20),
                style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
              ),
              const SizedBox(width: 8),
              _StreakPill(days: streak.current, loop: _loop),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(children: [
              Text(l10n.sessTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.1)),
              const SizedBox(height: 6),
              Text(l10n.sessSub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall, height: 1.35)),
            ]),
          ),
          const SizedBox(height: 22),
          Center(child: _Ring(goal: goal)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final g in SessionService.goals) ...[
              _GoalChip(label: '$g', on: g == goal, onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _goal = g);
                ref.read(sessionServiceProvider).setGoal(g);
              }),
              if (g != SessionService.goals.last) const SizedBox(width: 8),
            ],
          ]),
          _rise_(0, _weekCard(o)),
          _rise_(100, _monthsCard(o)),
        ],
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: 22,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SweeepColors.card.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (o.target != null)
              Text(l10n.sessStartsWith(monthTitle(o.target!.key)), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
            const SizedBox(height: 8),
            PillButton(height: 52, label: l10n.sessStart(l10n.photosCount(goal)), onPressed: _starting ? null : () => _start(o, goal)),
          ]),
        ),
      ),
    ]);
  }

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: SweeepColors.cardBorder)),
        child: child,
      );

  Widget _weekCard(SessionOverview o) => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l10n.sessWeek, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(l10n.sessBest(o.streak.best), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < 7; i++) _DayDot(letter: fmtWeekdayLetter(i), done: o.week[i], today: i == o.todayIndex, loop: _loop),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: (o.streak.freezeLeft ? SweeepColors.brand : SweeepColors.textMutedSmall).withValues(alpha: .5))),
              child: Text(l10n.sessFreeze, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: o.streak.freezeLeft ? SweeepColors.brand : SweeepColors.textMutedSmall)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(o.streak.freezeLeft ? l10n.sessFreezeSub : l10n.sessFreezeUsed, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall, height: 1.3))),
          ]),
        ]),
      );

  Widget _monthsCard(SessionOverview o) => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l10n.sessMonths, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(l10n.sessOldestFirst, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
          ]),
          const SizedBox(height: 12),
          for (final m in o.months)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                SizedBox(width: 74, child: Text(fmtMonthShort(int.parse(m.key.substring(0, 4)), int.parse(m.key.substring(5))), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: m.percent / 100),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: SweeepColors.trackUsed, color: m.percent == 100 ? SweeepColors.keep : SweeepColors.brand),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${m.percent}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: m.percent == 100 ? SweeepColors.keep : SweeepColors.brand)),
                ),
              ]),
            ),
        ]),
      );
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days, required this.loop});
  final int days;
  final AnimationController loop;

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white.withValues(alpha: .08))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flame(loop: loop, size: 16),
          const SizedBox(width: 6),
          Text(l10n.sessDays(days), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
        ]),
      );
}

/// The little streak flame that breathes.
class Flame extends StatelessWidget {
  const Flame({super.key, required this.loop, required this.size, this.color = SweeepColors.brand});
  final Animation<double> loop;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: loop,
        builder: (_, __) {
          final t = math.sin(loop.value * math.pi * 2);
          return Transform.rotate(angle: t * .05, child: Transform.scale(scale: 1.05 + .05 * t, child: Icon(Icons.local_fire_department_rounded, size: size + 2, color: color)));
        },
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.goal});
  final int goal;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        height: 220,
        child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: goal / 100),
            duration: const Duration(milliseconds: 800),
            curve: const Cubic(.2, .8, .2, 1),
            builder: (_, v, __) => CustomPaint(size: const Size(220, 220), painter: _RingPainter(v)),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$goal', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, letterSpacing: -3, height: 1)),
            const SizedBox(height: 4),
            Text(l10n.sessPhotosAbout(math.max(2, (goal / 12).round())), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
          ]),
        ]),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 94.0;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = SweeepColors.trackUsed;
    canvas.drawCircle(c, r, track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = SweeepColors.brand;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, math.pi * 2 * value.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
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
                constraints: const BoxConstraints(minWidth: 64),
                padding: const EdgeInsets.symmetric(horizontal: 18),
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

class _DayDot extends StatelessWidget {
  const _DayDot({required this.letter, required this.done, required this.today, required this.loop});
  final String letter;
  final bool done;
  final bool today;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) => Column(children: [
        AnimatedBuilder(
          animation: loop,
          builder: (_, child) {
            // today pulses until it is done
            final p = (today && !done) ? loop.value : 1.0;
            return Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? SweeepColors.brand : Colors.transparent,
                border: done ? null : Border.all(color: today ? SweeepColors.brand : Colors.white.withValues(alpha: .14), width: today ? 2 : 1),
                boxShadow: (today && !done) ? [BoxShadow(color: SweeepColors.brand.withValues(alpha: .5 * (1 - p)), blurRadius: 0, spreadRadius: 9 * p)] : null,
              ),
              child: child,
            );
          },
          child: done ? const Icon(Icons.check_rounded, size: 18, color: SweeepColors.onAccent) : null,
        ),
        const SizedBox(height: 6),
        Text(letter, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
      ]);
}
