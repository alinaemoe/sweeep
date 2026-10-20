import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/jelly.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart';

/// Full-screen progress for long scans (first run or lots of new photos):
/// the SCAAANNING word, the oval with the percentage, the four stages, three
/// live counters and Pause. Short rescans stay inside the Home oval.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _wave.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(libraryProvider);
    final pct = (s.progress * 100).floor().clamp(0, 100);
    final total = s.stats?.total ?? 0;
    final doneFiles = total == 0 ? s.processed : math.min(total, s.alreadyHashed + s.analysisDone);
    final groups = s.groupsBuilt != null && !s.busy ? s.groupsBuilt!.exactGroups + s.groupsBuilt!.similarGroups : (s.similar?.groups ?? 0);
    final found = s.groupsBuilt != null && !s.busy ? s.groupsBuilt!.exactSavings + s.groupsBuilt!.similarSavings : (s.similar?.savingsBytes ?? 0);
    final phase = s.phase;
    final bottom = MediaQuery.paddingOf(context).bottom;

    String stepValue(int step) {
      if (step < phase) return step == 0 ? fmtNum(total) : l10n.scanStatusDone;
      if (step > phase) return l10n.scanStatusNext;
      return switch (step) {
        0 => fmtNum(s.processed),
        1 => '${(s.analysisTotal <= 0 ? 100 : (s.analysisDone * 100 / s.analysisTotal)).floor()}%',
        2 => '${(s.verifyTotal <= 0 ? 0 : (s.verifyDone * 100 / s.verifyTotal)).floor()}%',
        _ => '…',
      };
    }

    return ColoredBox(
      color: SweeepColors.background,
      child: Stack(children: [
        const GlowOrb(left: 50, top: 200, width: 290, height: 260, color: Color(0x1AB8A6FF), blur: 70),
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 150),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              const SizedBox(height: 12),
              SizedBox(height: 56, child: Align(alignment: Alignment.bottomCenter, child: _ScanWord(controller: _wave, paused: s.paused))),
              const SizedBox(height: 16),
              _Oval(progress: s.progress, pct: pct, caption: l10n.scanOfFiles(fmtNum(doneFiles), fmtNum(total))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: SweeepColors.cardBorder)),
                child: Column(children: [
                  for (var i = 0; i < 4; i++)
                    _StepRow(
                      label: [l10n.scanStepRead, l10n.scanStepFinger, l10n.scanStepCompare, l10n.scanStepGroup][i],
                      value: stepValue(i),
                      state: i < phase ? _StepState.done : (i == phase ? _StepState.active : _StepState.pending),
                      pulse: s.paused ? null : _pulse,
                      last: i == 3,
                    ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _Counter(value: fmtNum(groups), label: l10n.scanCountGroups)),
                const SizedBox(width: 8),
                Expanded(child: _Counter(value: fmtNum(s.stats?.screenshots ?? 0), label: l10n.scanCountShots)),
                const SizedBox(width: 8),
                Expanded(child: _Counter(value: formatBytes(found), label: l10n.scanCountFound, accent: true)),
              ]),
            ]),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: bottom + 24,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: SweeepColors.textMutedSmall),
              const SizedBox(width: 6),
              Flexible(child: Text(s.paused ? l10n.scanPausedNote : l10n.scanPrivacy, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            if (s.paused)
              Row(children: [
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => ref.read(libraryProvider.notifier).dismissScan(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: SweeepColors.card,
                      foregroundColor: SweeepColors.text,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      side: BorderSide(color: Colors.white.withValues(alpha: .12)),
                    ),
                    child: Text(l10n.scanLater, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: l10n.scanResume,
                    height: 54,
                    onPressed: s.busy
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            ref.read(libraryProvider.notifier).sync();
                          },
                  ),
                ),
              ])
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(libraryProvider.notifier).pause();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: SweeepColors.card,
                    foregroundColor: SweeepColors.text,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: Colors.white.withValues(alpha: .12)),
                  ),
                  child: Text(l10n.scanPause, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// SCAAANNING, every letter hopping with the jelly wave (the three A's lavender).
class _ScanWord extends StatelessWidget {
  const _ScanWord({required this.controller, required this.paused});
  final AnimationController controller;
  final bool paused;

  static const _word = 'SCAAANNING';

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (var i = 0; i < _word.length; i++) _letter(i)],
          ),
        ),
      );

  Widget _letter(int i) {
    const period = 2400;
    final ms = controller.value * period - i * 80;
    final p = (((ms % period) + period) % period) / period;
    final pose = paused ? (dy: 0.0, sy: 1.0) : jellySample(jellyLoop, p);
    final c = (i >= 2 && i <= 4) ? SweeepColors.brand : SweeepColors.text;
    return Jelly(dy: pose.dy, sy: pose.sy, child: Text(_word[i], style: TextStyle(fontSize: 40, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1, color: c)));
  }
}

class _Oval extends StatelessWidget {
  const _Oval({required this.progress, required this.pct, required this.caption});
  final double progress;
  final int pct;
  final String caption;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = w * .6;
        return Semantics(
          label: '$pct%, $caption',
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(alignment: Alignment.center, children: [
              RepaintBoundary(child: CustomPaint(size: Size(w, h), painter: _RingPainter(progress))),
              ExcludeSemantics(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('$pct', style: const TextStyle(fontSize: 76, height: 1, fontWeight: FontWeight.w800, letterSpacing: -3)),
                    const SizedBox(width: 4),
                    const Text('%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SweeepColors.brand)),
                  ]),
                  const SizedBox(height: 6),
                  Text(caption, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: SweeepColors.textMutedSmall)),
                ]),
              ),
            ]),
          ),
        );
      });
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromLTWH(stroke / 2 + 2, stroke / 2 + 2, size.width - stroke - 4, size.height - stroke - 4);
    // starts at the top and runs clockwise, like the Home oval
    final path = Path()..addArc(rect, -math.pi / 2, 2 * math.pi);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1F212B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final metric = path.computeMetrics().first;
    final arc = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
    // soft glow: a wider translucent pass under the arc (no blur filter, so it stays cheap)
    canvas.drawPath(
      arc,
      Paint()
        ..color = SweeepColors.brand.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      arc,
      Paint()
        ..color = SweeepColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

enum _StepState { done, active, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.value, required this.state, required this.pulse, required this.last});
  final String label;
  final String value;
  final _StepState state;
  final Animation<double>? pulse;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final pending = state == _StepState.pending;
    return Semantics(
      label: '$label, $value',
      child: ExcludeSemantics(
        child: Container(
          height: 48,
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .06)))),
          child: Row(children: [
            _dot(),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: pending ? SweeepColors.textMutedSmall : SweeepColors.text))),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: state == _StepState.active ? FontWeight.w700 : FontWeight.w600, color: state == _StepState.active ? SweeepColors.brand : SweeepColors.textMutedSmall),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dot() => switch (state) {
        _StepState.done => Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: SweeepColors.brand),
            child: const Icon(Icons.check_rounded, size: 14, color: SweeepColors.onAccent),
          ),
        _StepState.active => Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SweeepColors.brand, width: 2)),
            child: pulse == null
                ? const _Core(opacity: 1)
                : AnimatedBuilder(animation: pulse!, builder: (_, __) => _Core(opacity: 1 - .65 * Curves.easeInOut.transform(pulse!.value))),
          ),
        _StepState.pending => Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SweeepColors.trackUsed, width: 2)),
          ),
      };
}

class _Core extends StatelessWidget {
  const _Core({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: SweeepColors.brand.withValues(alpha: opacity)));
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label, this.accent = false});
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: SweeepColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, maxLines: 1, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent ? SweeepColors.brand : SweeepColors.text))),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
        ]),
      );
}
