import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/jelly.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/review_service.dart';
import '../../index/session_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../swipe/swipe_screen.dart';
import 'session_screen.dart';

/// Session done (D13): CLEAAAN, what went to the trash and what stayed, the
/// streak and how far the month got. The note at the bottom says honestly
/// that nothing left the phone yet.
class SessionDoneScreen extends ConsumerStatefulWidget {
  const SessionDoneScreen({super.key, required this.result});
  final SessionResult result;

  @override
  ConsumerState<SessionDoneScreen> createState() => _SessionDoneScreenState();
}

class _SessionDoneScreenState extends ConsumerState<SessionDoneScreen> with TickerProviderStateMixin {
  late final AnimationController _count = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final AnimationController _rise = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final AnimationController _spark = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  late final AnimationController _flame = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    // the trash grew, so everything that shows it has to refresh
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(timelineProvider);
    ref.invalidate(storageProvider);
  }

  @override
  void dispose() {
    _count.dispose();
    _rise.dispose();
    _wave.dispose();
    _spark.dispose();
    _flame.dispose();
    super.dispose();
  }

  Future<void> _another() async {
    if (_busy) return;
    setState(() => _busy = true);
    final svc = ref.read(sessionServiceProvider);
    final o = await svc.overview();
    final plan = await svc.plan(widget.result.goal);
    if (!mounted) return;
    if (plan.items.isEmpty) {
      setState(() => _busy = false);
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => SwipeScreen.session(plan: plan, goal: widget.result.goal, before: o.streak, targetPercent: o.target?.percent ?? 100)));
  }

  String _time(Duration d) => d.inSeconds >= 60 ? l10n.doneTimeMS(d.inMinutes, d.inSeconds % 60) : l10n.doneTimeS(math.max(1, d.inSeconds));

  Widget _rise_(double delay, Widget child) => AnimatedBuilder(
        animation: _rise,
        builder: (_, c) {
          final t = Curves.easeOut.transform(((_rise.value * 1400 - delay) / 600).clamp(0.0, 1.0));
          return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: c));
        },
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Stack(children: [
        GlowOrb(left: width / 2 - 160, top: 60, width: 320, height: 320, color: SweeepColors.trash.withValues(alpha: .14), blur: 80),
        SafeArea(
          child: Stack(children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 130),
              children: [
                Center(child: _Word(wave: _wave)),
                const SizedBox(height: 14),
                Text(l10n.doneSwept(l10n.photosCount(r.swept), _time(r.duration)), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: _rise_(200, _trashCard(r))),
                  const SizedBox(width: 12),
                  Expanded(child: _rise_(300, _keptCard(r))),
                ]),
                const SizedBox(height: 12),
                _rise_(400, _streakCard(r)),
                if (r.monthKey != null) ...[const SizedBox(height: 12), _rise_(500, _monthCard(r))],
                const SizedBox(height: 12),
                CustomPaint(
                  painter: _DashedPainter(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text(l10n.doneNote, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall, height: 1.45)),
                  ),
                ),
              ],
            ),
            // sparks burst out from under the word
            Positioned(
              left: 0,
              right: 0,
              top: 120,
              child: IgnorePointer(child: SizedBox(height: 1, child: _Sparks(t: _spark))),
            ),
          ]),
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
            child: Row(children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(96, 52),
                  foregroundColor: SweeepColors.text,
                  side: BorderSide(color: Colors.white.withValues(alpha: .12)),
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.doneDone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(child: PillButton(height: 52, label: l10n.doneAnother(r.goal), onPressed: _busy ? null : _another)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _statCard({required Color border, required String label, required Widget value, required String sub}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: border.withValues(alpha: .35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: SweeepColors.textMutedSmall)),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 4),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
        ]),
      );

  Widget _trashCard(SessionResult r) {
    final units = l10n.byteUnits.split(',');
    var v = r.bytes.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    final unit = units[math.max(i, 2)];
    final shown = i < 2 ? r.bytes / (1024 * 1024) : v;
    return _statCard(
      border: SweeepColors.trash,
      label: l10n.doneInTrash,
      value: AnimatedBuilder(
        animation: _count,
        builder: (_, __) {
          final k = Curves.easeOutCubic.transform(_count.value);
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(fmtNum(shown * k, digits: shown < 100 ? 1 : 0), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1, color: SweeepColors.trash)),
          );
        },
      ),
      sub: l10n.doneInTrashSub(unit, l10n.filesCount(r.trashed)),
    );
  }

  Widget _keptCard(SessionResult r) => _statCard(
        border: SweeepColors.keep,
        label: l10n.doneKept,
        value: AnimatedBuilder(
          animation: _count,
          builder: (_, __) => Text(fmtNum((r.kept * Curves.easeOutCubic.transform(_count.value)).round()), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1, color: SweeepColors.keep)),
        ),
        sub: l10n.donePhotosStay,
      );

  Widget _streakCard(SessionResult r) {
    final after = r.streakAfter;
    final sub = after.current > r.streakBefore.current
        ? (r.streakBefore.current == 0 ? l10n.doneStreakNew(after.best) : l10n.doneStreakUp(after.best))
        : l10n.doneStreakSame(after.best);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: SweeepColors.cardBorder)),
      child: Row(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1600),
          curve: const Interval(.56, 1, curve: Curves.elasticOut),
          builder: (_, s, child) => Opacity(opacity: s.clamp(0.0, 1.0), child: Transform.scale(scale: .4 + .6 * s, child: child)),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: SweeepColors.brand.withValues(alpha: .16)),
            child: Flame(loop: _flame, size: 34),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.doneStreak(after.current), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8, height: 1)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
          ]),
        ),
      ]),
    );
  }

  Widget _monthCard(SessionResult r) {
    final month = monthTitle(r.monthKey!);
    final sessions = r.monthLeft == 0 ? 0 : (r.monthLeft / r.goal).ceil();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: SweeepColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(month, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          Text(l10n.doneMonthProgress(r.percentBefore, r.percentAfter), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, k, __) => Stack(children: [
                const Positioned.fill(child: ColoredBox(color: SweeepColors.trackUsed)),
                FractionallySizedBox(widthFactor: (r.percentAfter / 100 * k).clamp(0.0, 1.0), child: ColoredBox(color: SweeepColors.brand.withValues(alpha: .45))),
                FractionallySizedBox(widthFactor: (r.percentBefore / 100 * k).clamp(0.0, 1.0), child: const ColoredBox(color: SweeepColors.brand)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          r.monthLeft == 0 ? l10n.doneMonthDone(month) : l10n.doneLeft(l10n.photosCount(r.monthLeft), month) + l10n.doneMoreSessions(sessions),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall, height: 1.4),
        ),
      ]),
    );
  }
}

/// CLEAAAN: every letter hops twice.
class _Word extends StatelessWidget {
  const _Word({required this.wave});
  final AnimationController wave;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: wave,
        builder: (_, __) {
          const word = 'CLEAAAN';
          final t = wave.value * 1500;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < word.length; i++)
                Builder(builder: (_) {
                  final local = t - i * 70;
                  final p = local <= 0 || local >= 1360 ? 0.0 : ((local % 680) / 680);
                  final pose = local <= 0 || local >= 1360 ? (dy: 0.0, sy: 1.0) : jellySample(jellyHop, p);
                  return Jelly(dy: pose.dy, sy: pose.sy, child: Text(word[i], style: const TextStyle(fontSize: 58, height: 1, fontWeight: FontWeight.w800, letterSpacing: -2, color: SweeepColors.trash)));
                }),
            ],
          );
        },
      );
}

class _Sparks extends StatelessWidget {
  const _Sparks({required this.t});
  final Animation<double> t;

  static const _colors = [SweeepColors.trash, SweeepColors.brand, SweeepColors.keep];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: t,
        builder: (_, __) => Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          for (var i = 0; i < 14; i++)
            Builder(builder: (_) {
              final a = i / 14 * math.pi * 2;
              final r = 90.0 + (i % 3) * 30;
              final delay = (.1 + (i % 4) * .05) * 1000;
              final k = ((t.value * 1400 - delay) / 1100).clamp(0.0, 1.0);
              final e = Curves.easeOut.transform(k);
              return Positioned(
                left: MediaQuery.sizeOf(context).width / 2 - 4 + math.cos(a) * r * e,
                top: -4 + math.sin(a) * r * .6 * e,
                child: Opacity(opacity: (1 - k).clamp(0.0, 1.0), child: Transform.scale(scale: 1 - .8 * k, child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _colors[i % 3])))),
              );
            }),
        ]),
      );
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .16);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
