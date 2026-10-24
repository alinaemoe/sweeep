import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text_segment.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../core/widgets.dart';
import '../../index/review_service.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart';
import 'swipe_screen.dart';
import '../moments/moments_screen.dart';
import '../session/session_screen.dart';
import '../wrap/month_wrap_screen.dart';

String _num(int n) => fmtNum(n);

/// The Swipe tab: the whole library as a vertical feed of months (newest
/// first), each with a horizontal strip of its photos. A month opens the
/// swipe deck for just that month.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  bool _newestFirst = true;

  Future<void> _open(String month) async {
    HapticFeedback.selectionClick();
    // a finished month shows its wrap instead of an empty deck
    final done = ref.read(timelineProvider).value?.where((m) => m.key == month).firstOrNull?.done ?? false;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => done ? MonthWrapScreen(monthKey: month) : SwipeScreen(source: SwipeSource.all, month: month)));
    if (!mounted) return;
    ref.invalidate(timelineProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(trashSummaryProvider);
  }

  Future<void> _openMoments() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MomentsScreen()));
    if (!mounted) return;
    ref.invalidate(timelineProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(trashSummaryProvider);
  }

  Future<void> _openSession() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SessionScreen()));
    if (!mounted) return;
    ref.invalidate(timelineProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(streakProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(timelineProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: SweeepColors.background,
      child: Stack(children: [
        const GlowOrb(left: -60, top: 40, width: 300, height: 240, color: Color(0x17B8A6FF), blur: 60),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SweeepColors.brand)),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: SweeepColors.trash))),
          data: (all) {
            if (all.isEmpty) {
              return Center(child: Text(l10n.tlNoPhotos, style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 16)));
            }
            final months = _newestFirst ? all : all.reversed.toList();
            final total = all.fold<int>(0, (s, m) => s + m.count);
            final swept = all.fold<int>(0, (s, m) => s + m.swept);
            // where to carry on: the newest month that still has photos to decide
            final next = all.cast<MonthSummary?>().firstWhere((m) => !m!.done, orElse: () => null);
            return Stack(children: [
              ListView.builder(
                padding: EdgeInsets.only(bottom: bottom + 190),
                itemCount: months.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                        child: Column(children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              GestureDetector(
                                onLongPress: !wrapDemo || all.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MonthWrapScreen(monthKey: all.first.key))),
                                child: Text(l10n.tlHeadline, style: const TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1)),
                              ),
                              const SizedBox(height: 6),
                              Text(l10n.tlSummary(l10n.photosCount(total), _num(swept)), style: const TextStyle(fontSize: 14, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Semantics(
                            button: true,
                            label: _newestFirst ? l10n.tlSemSort : l10n.tlSemSortOld,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _newestFirst = !_newestFirst),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .12))),
                                child: Text(_newestFirst ? l10n.tlNewestFirst : l10n.tlOldestFirst, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                          ]),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextSegment<bool>(
                              options: [(false, l10n.segMonths), (true, l10n.segMoments)],
                              value: false,
                              onChanged: (_) => _openMoments(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SessionEntry(onOpen: _openSession),
                        ]),
                      ),
                    );
                  }
                  final m = months[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: RepaintBoundary(child: _MonthSection(month: m, onOpen: () => _open(m.key))),
                  );
                },
              ),
              if (next != null)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: bottom + 12 + 62 + 12,
                  child: PillButton(label: l10n.tlContinueMonth(next.title), onPressed: () => _open(next.key)),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.month, required this.onOpen});
  final MonthSummary month;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final m = month;
    final started = m.swept > 0 && !m.done;
    final status = m.done ? l10n.tlAllSwept : (started ? l10n.tlNSwept(_num(m.swept)) : l10n.tlNotStarted);
    final more = m.count - m.tiles.length;
    final barColor = m.done ? SweeepColors.keep : SweeepColors.brand;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)),
              const SizedBox(height: 2),
              Text(l10n.tlMonthLine(l10n.photosCount(m.count), status), style: const TextStyle(fontSize: 13, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: m.done ? l10n.tlSemReview(m.title) : (started ? l10n.tlSemContinue(m.title) : l10n.tlSemSwipe(m.title)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: m.done ? SweeepColors.keep.withValues(alpha: .14) : (started ? SweeepColors.brand : Colors.transparent),
                  borderRadius: BorderRadius.circular(22),
                  border: !m.done && !started ? Border.all(color: SweeepColors.brand.withValues(alpha: .5)) : null,
                ),
                child: Text(
                  m.done ? l10n.tlDone : (started ? l10n.tlContinue : l10n.actionSwipe),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: m.done ? SweeepColors.keep : (started ? SweeepColors.onAccent : SweeepColors.brand)),
                ),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(minHeight: 5, value: m.count == 0 ? 0 : m.swept / m.count, color: barColor, backgroundColor: const Color(0xFF262833)),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 152,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          itemCount: m.tiles.length + (more > 0 ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            if (i == m.tiles.length) return _MoreTile(count: more, onTap: onOpen);
            final t = m.tiles[i];
            final d = DateTime.fromMillisecondsSinceEpoch(t.t);
            return Pressable(
              label: l10n.tlSemPhotoFrom(fmtDayMonth(d)),
              onTap: onOpen,
              child: Container(
                width: 108,
                height: 148,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .12))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Stack(fit: StackFit.expand, children: [
                    ThumbImage(id: t.id, side: 256),
                    // finished months are muted
                    if (m.done) ColoredBox(color: SweeepColors.background.withValues(alpha: .5)),
                    Positioned(left: 8, right: 8, bottom: 8, child: GlassPill(height: 26, padding: EdgeInsets.zero, child: Text(fmtDayMonth(d), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        label: l10n.tlSemMore(_num(count)),
        onTap: onTap,
        child: SizedBox(
          width: 108,
          height: 148,
          child: CustomPaint(
            painter: _DashedRRect(color: SweeepColors.brand.withValues(alpha: .5), radius: 22),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('+${_num(count)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
              const SizedBox(height: 4),
              Text(l10n.tlMore, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
            ]),
          ),
        ),
      );
}

class _DashedRRect extends CustomPainter {
  const _DashedRRect({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(.75));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, (d + 5).clamp(0, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color || old.radius != radius;
}

/// The way into Cleanup sessions: streak at a glance, one tap to open.
class _SessionEntry extends ConsumerWidget {
  const _SessionEntry({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider).value;
    final days = streak?.current ?? 0;
    return Semantics(
      button: true,
      label: l10n.sessTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: SweeepColors.cardBorder)),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: SweeepColors.brand.withValues(alpha: .16)),
              child: const Icon(Icons.local_fire_department_rounded, size: 24, color: SweeepColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.sessTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.3)),
                const SizedBox(height: 2),
                Text(days > 0 ? l10n.doneStreak(days) : l10n.sessEntryNoStreak, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: SweeepColors.textMutedSmall),
          ]),
        ),
      ),
    );
  }
}
