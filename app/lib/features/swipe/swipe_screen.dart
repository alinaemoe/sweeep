import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../index/review_service.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart';
import '../trash/trash_screen.dart';

String sourceTitle(SwipeSource s) => switch (s) {
      SwipeSource.all => 'All photos',
      SwipeSource.screenshots => 'Screenshots',
      SwipeSource.blurry => 'Blurry & dark',
    };

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Tinder-style review: drag left = trash, right = keep. The SWIIIIPE word
/// stretches with the drag, CLEAAAN waves after a trash.
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key, required this.source});
  final SwipeSource source;

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> with TickerProviderStateMixin {
  List<SwipeItem>? _queue;
  int _i = 0;
  double _dx = 0;
  double _dy = 0;
  bool _armed = false;
  bool _busy = false;
  final _history = <({SwipeItem item, bool trashed})>[];

  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 230));
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    ref.read(reviewServiceProvider).queue(widget.source).then((q) {
      if (mounted) setState(() => _queue = q);
    });
  }

  @override
  void dispose() {
    _move.dispose();
    _wave.dispose();
    super.dispose();
  }

  SwipeItem? get _current => _queue != null && _i < _queue!.length ? _queue![_i] : null;

  void _refreshOutside() {
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(groupsProvider);
  }

  void _animateTo(double toX, double toY, Curve curve, int ms, VoidCallback done) {
    final fx = _dx, fy = _dy;
    _move
      ..reset()
      ..duration = Duration(milliseconds: ms);
    void tick() {
      final t = curve.transform(_move.value);
      setState(() {
        _dx = fx + (toX - fx) * t;
        _dy = fy + (toY - fy) * t;
      });
    }

    _move.addListener(tick);
    _move.forward().whenComplete(() {
      _move.removeListener(tick);
      done();
    });
  }

  void _decide(bool trash, {double velocity = 0}) {
    final item = _current;
    if (item == null || _busy) return;
    _busy = true;
    final width = MediaQuery.sizeOf(context).width;
    final svc = ref.read(reviewServiceProvider);
    // The DB write runs in the background so the next card never waits for it.
    final write = trash ? svc.trash(item) : svc.keep(item);
    final dir = trash ? -1.0 : 1.0;
    final ms = velocity.abs() > 1500 ? 200 : 280;
    _animateTo(dir * width * 1.25, _dy + 40, Curves.easeInQuad, ms, () {
      if (!mounted) return;
      // The card behind is already full size, so this swap is seamless.
      setState(() {
        _history.add((item: item, trashed: trash));
        _i++;
        _dx = 0;
        _dy = 0;
        _armed = false;
        _busy = false;
      });
      if (trash) _wave.forward(from: 0);
      write.then((_) {
        if (mounted) ref.invalidate(trashSummaryProvider);
      });
    });
  }

  Future<void> _undo() async {
    if (_history.isEmpty || _busy) return;
    final last = _history.removeLast();
    await ref.read(reviewServiceProvider).undo(last.item.id);
    ref.invalidate(trashSummaryProvider);
    if (mounted) setState(() => _i--);
  }

  void _onDrag(DragUpdateDetails d) {
    if (_busy) return;
    setState(() {
      _dx += d.delta.dx;
      _dy += d.delta.dy * .35;
    });
    final armed = _dx.abs() > 90;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.selectionClick();
    }
  }

  void _onEnd(DragEndDetails d) {
    if (_busy) return;
    final v = d.velocity.pixelsPerSecond.dx;
    if (_dx < -90 || v < -900) {
      _decide(true, velocity: v);
    } else if (_dx > 90 || v > 900) {
      _decide(false, velocity: v);
    } else {
      _busy = true;
      _armed = false;
      _animateTo(0, 0, Curves.easeOutBack, 380, () => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _queue;
    final item = _current;
    final summary = ref.watch(trashSummaryProvider).value;
    // Keep the next photos decoded so cards never pop in.
    if (q != null) {
      for (var k = _i; k < math.min(_i + 3, q.length); k++) {
        ref.watch(bigThumbProvider(q[k].id));
      }
    }
    final dragging = _dx.abs() > 12;
    final accent = _dx < -12 ? SweeepColors.trash : (_dx > 12 ? SweeepColors.keep : SweeepColors.text);
    final glow = _dx < -12 ? SweeepColors.trash : (_dx > 12 ? SweeepColors.keep : Colors.white);
    final glowAlpha = dragging ? .18 : .04;

    return PopScope(
      onPopInvokedWithResult: (_, __) => _refreshOutside(),
      child: Scaffold(
        body: Stack(children: [
          Positioned(left: -80, top: 120, child: IgnorePointer(child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle, color: glow.withValues(alpha: glowAlpha)),
          ))),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.chevron_left_rounded),
                    style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
                  ),
                  Expanded(
                    child: Column(children: [
                      Text(sourceTitle(widget.source), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(q == null ? '' : '${math.min(_i + 1, q.length)} of ${q.length}', style: const TextStyle(fontSize: 12, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  IconButton(
                    onPressed: _history.isEmpty ? null : _undo,
                    tooltip: 'Undo',
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, disabledForegroundColor: SweeepColors.trackUsed, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
                  ),
                ]),
              ),
              SizedBox(height: 64, child: Align(alignment: Alignment.bottomCenter, child: _Word(dx: _dx, wave: _wave, color: accent))),
              const SizedBox(height: 12),
              Expanded(
                child: q == null
                    ? const Center(child: CircularProgressIndicator(color: SweeepColors.brand))
                    : item == null
                        ? _Done(empty: q.isEmpty, onBack: () => Navigator.of(context).pop())
                        : _Deck(
                            item: item,
                            next: _i + 1 < q.length ? q[_i + 1] : null,
                            dx: _dx,
                            dy: _dy,
                            width: MediaQuery.sizeOf(context).width,
                            onDrag: _onDrag,
                            onEnd: _onEnd,
                          ),
              ),
              if (item != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                      onPressed: () => _decide(true),
                      tooltip: 'Move to trash',
                      icon: const Icon(Icons.close_rounded, size: 28),
                      style: IconButton.styleFrom(
                        foregroundColor: SweeepColors.trash,
                        backgroundColor: SweeepColors.trash.withValues(alpha: .1),
                        side: const BorderSide(color: SweeepColors.trash),
                        fixedSize: const Size(60, 60),
                      ),
                    ),
                    const SizedBox(width: 18),
                    IconButton(
                      onPressed: () => _decide(false),
                      tooltip: 'Keep',
                      icon: const Icon(Icons.check_rounded, size: 28),
                      style: IconButton.styleFrom(foregroundColor: SweeepColors.onAccent, backgroundColor: SweeepColors.keep, fixedSize: const Size(60, 60)),
                    ),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _TrashBar(
                  count: summary?.count ?? 0,
                  bytes: summary?.bytes ?? 0,
                  progress: q == null || q.isEmpty ? 0 : _i / q.length,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrashScreen())).then((_) => _refreshOutside()),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// SWIIIIPE (stretches with |dx|) or a waving CLEAAAN after a trash.
class _Word extends StatelessWidget {
  const _Word({required this.dx, required this.wave, required this.color});
  final double dx;
  final AnimationController wave;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: wave,
        builder: (context, _) {
          final waving = wave.isAnimating;
          final word = waving ? 'CLEAAAN' : swipeWord(dx);
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < word.length; i++)
                Builder(builder: (_) {
                  final p = ((wave.value * 1.6 - i * .08)).clamp(0.0, 1.0);
                  final y = waving ? -16 * math.sin(math.pi * p) : 0.0;
                  return Transform.translate(
                    offset: Offset(0, y),
                    child: Text(word[i], style: TextStyle(fontSize: 46, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1, color: waving ? SweeepColors.trash : color)),
                  );
                }),
            ],
          );
        },
      );
}

class _Deck extends StatelessWidget {
  const _Deck({required this.item, required this.next, required this.dx, required this.dy, required this.width, required this.onDrag, required this.onEnd});
  final SwipeItem item;
  final SwipeItem? next;
  final double dx;
  final double dy;
  final double width;
  final void Function(DragUpdateDetails) onDrag;
  final void Function(DragEndDetails) onEnd;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(item.createdAtMs);
    final trashA = (-dx / 90).clamp(0.0, 1.0);
    final keepA = (dx / 90).clamp(0.0, 1.0);
    // The card behind grows to full size as the front one leaves, so the
    // hand-over at the end of the fling is seamless.
    final p = Curves.easeOut.transform((dx.abs() / (width * .55)).clamp(0.0, 1.0));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          key: ValueKey('back-${next?.id}'),
          child: Transform.rotate(
            angle: -2 * (1 - p) * math.pi / 180,
            child: Transform.scale(
              scale: .94 + .06 * p,
              child: next == null
                  ? Container(decoration: BoxDecoration(color: const Color(0xFF1B1D27), borderRadius: BorderRadius.circular(30), border: Border.all(color: SweeepColors.cardBorder)))
                  : _Photo(id: next!.id),
            ),
          ),
        ),
        Positioned.fill(
          key: ValueKey('front-${item.id}'),
          child: GestureDetector(
            onPanUpdate: onDrag,
            onPanEnd: onEnd,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: dx / 18 * math.pi / 180,
                child: Stack(fit: StackFit.expand, children: [
                  DecoratedBox(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 20))]),
                    child: _Photo(id: item.id, tint: dx < 0 ? SweeepColors.trash.withValues(alpha: math.min(.35, -dx / 300)) : SweeepColors.keep.withValues(alpha: math.min(.3, dx / 300))),
                  ),
                  Positioned(right: 22, top: 26, child: Opacity(opacity: trashA, child: Transform.rotate(angle: 10 * math.pi / 180, child: const _Stamp('TO TRASH', SweeepColors.trash)))),
                  Positioned(left: 22, top: 26, child: Opacity(opacity: keepA, child: Transform.rotate(angle: -10 * math.pi / 180, child: const _Stamp('KEEP', SweeepColors.keep)))),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: GlassPill(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${d.day} ${_months[d.month - 1]} ${d.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(formatBytes(item.sizeBytes), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SweeepColors.textMuted)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Photo extends ConsumerWidget {
  const _Photo({required this.id, this.tint});
  final String id;
  final Color? tint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bigThumbProvider(id));
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: SweeepColors.card),
        async.when(
          data: (b) => b == null ? const SizedBox.shrink() : Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        if (tint != null) ColoredBox(color: tint!),
        DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .08)))),
      ]),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .7), border: Border.all(color: color, width: 3), borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1)),
      );
}

class _TrashBar extends StatelessWidget {
  const _TrashBar({required this.count, required this.bytes, required this.progress, required this.onTap});
  final int count;
  final int bytes;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: SweeepColors.card.withValues(alpha: .7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: BorderSide(color: Colors.white.withValues(alpha: .08))),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'In trash: $count files ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  TextSpan(text: '(${formatBytes(bytes)})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SweeepColors.textMuted)),
                ])),
                const Icon(Icons.keyboard_arrow_up_rounded, color: SweeepColors.textMuted),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: progress, minHeight: 6, color: SweeepColors.brand, backgroundColor: const Color(0xFF262833)),
              ),
            ]),
          ),
        ),
      );
}

class _Done extends StatelessWidget {
  const _Done({required this.empty, required this.onBack});
  final bool empty;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(empty ? 'Nothing to review' : 'All reviewed', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('You can restore anything from the trash.', textAlign: TextAlign.center, style: TextStyle(color: SweeepColors.textMutedSmall, fontSize: 15)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(backgroundColor: SweeepColors.brand, foregroundColor: SweeepColors.onAccent, minimumSize: const Size(160, 52), shape: const StadiumBorder()),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ]),
        ),
      );
}
