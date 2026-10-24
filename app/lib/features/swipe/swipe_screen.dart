import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/jelly.dart';
import '../../core/mode_switch.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../core/widgets.dart';
import '../../index/review_service.dart';
import '../../providers.dart';
import '../../index/session_service.dart';
import '../../index/storage_service.dart';
import '../session/session_done_screen.dart';
import '../wrap/month_wrap_screen.dart';
import '../category/category_screen.dart';
import '../storage/storage_labels.dart';
import '../groups/group_widgets.dart';
import 'video_layer.dart';
import '../trash/trash_screen.dart';

String sourceTitle(SwipeSource s) => switch (s) {
      SwipeSource.all => l10n.srcAll,
      SwipeSource.screenshots => l10n.secScreenshots,
      SwipeSource.screenRecordings => l10n.secScreenRecordings,
      SwipeSource.videos => l10n.secVideos,
      SwipeSource.chat => l10n.secChat,
      SwipeSource.blurry => l10n.secBlurry,
      SwipeSource.quickWin => '',
      SwipeSource.event => '',
    };

/// Tinder-style review: drag left = trash, right = keep. The SWIIIIPE word
/// stretches with the drag, CLEAAAN waves after a trash.
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key, required this.source, this.embedded = false, this.month, this.chatSource, this.startId, this.win, this.eventId, this.eventTitle})
      : plan = null,
        goal = 0,
        before = null,
        targetPercent = 100;

  /// A Cleanup session: a ready deck of [goal] photos; reaching the goal
  /// opens the Session done screen.
  const SwipeScreen.session({super.key, required SessionPlan this.plan, required this.goal, required StreakInfo this.before, required this.targetPercent})
      : source = SwipeSource.all,
        embedded = false,
        month = null,
        chatSource = null,
        startId = null,
        win = null,
        eventId = null,
        eventTitle = null;

  final SwipeSource source;
  final SessionPlan? plan;
  final int goal;
  final StreakInfo? before;
  final int targetPercent;

  /// 'YYYY-MM': swipe just that month (from the Timeline).
  final String? month;

  /// Chat deck only: just this app.
  final String? chatSource;

  /// Start on this item (a tapped tile).
  final String? startId;

  /// Quick win decks only: which rule picked these files.
  final QuickWin? win;

  /// Moments: the event to sweep, and its name for the header.
  final int? eventId;
  final String? eventTitle;

  /// Shown as a tab of the app shell (no back button, room for the nav bar).
  final bool embedded;

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
  bool _hint = false; // first-run gesture hint

  // Cleanup session bookkeeping
  final _started = DateTime.now();
  int _swept = 0;
  int _trashedN = 0;
  int _trashedBytes = 0;
  bool get _inSession => widget.plan != null;

  /// action: 0 keep, 1 trash, 2 later
  final _history = <({SwipeItem item, int action})>[];

  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 230));
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1120));

  @override
  void initState() {
    super.initState();
    final svc = ref.read(reviewServiceProvider);
    if (_inSession) {
      svc.swipeHintSeen().then((seen) {
        if (mounted) {
          setState(() {
            _queue = [...widget.plan!.items];
            _hint = !seen && _queue!.isNotEmpty;
          });
        }
      });
      return;
    }
    svc.queue(widget.source, month: widget.month, chatSource: widget.chatSource, startId: widget.startId, win: widget.win, eventId: widget.eventId).then((q) async {
      final seen = await svc.swipeHintSeen();
      if (mounted) {
        setState(() {
          _queue = q;
          _hint = !seen && q.isNotEmpty;
        });
      }
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
        _history.add((item: item, action: trash ? 1 : 0));
        _swept++;
        if (trash) {
          _trashedN++;
          _trashedBytes += item.sizeBytes;
        }
        _i++;
        _dx = 0;
        _dy = 0;
        _armed = false;
        _busy = false;
      });
      HapticFeedback.lightImpact();
      if (trash) _wave.forward(from: 0);
      final done = _inSession && (_swept >= widget.goal || _i >= _queue!.length);
      write.then((_) async {
        if (!mounted) return;
        ref.invalidate(trashSummaryProvider);
        // that was the last photo of a month: its wrap, once
        final wrap = await ref.read(monthWrapServiceProvider).pendingFor(item.createdAtMs);
        if (!mounted) return;
        if (done) {
          await _finishSession(wrapMonth: wrap);
        } else if (wrap != null) {
          ref.invalidate(timelineProvider);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MonthWrapScreen(monthKey: wrap)));
        }
      });
    });
  }

  /// Swipe up: skip this photo for now. Nothing is recorded; it goes to the
  /// end of the queue.
  void _later() {
    final item = _current;
    if (item == null || _busy) return;
    _busy = true;
    final height = MediaQuery.sizeOf(context).height;
    _animateTo(_dx * .3, -height * .8, Curves.easeInQuad, 260, () {
      if (!mounted) return;
      setState(() {
        _queue!
          ..removeAt(_i)
          ..add(item);
        _history.add((item: item, action: 2));
        _dx = 0;
        _dy = 0;
        _armed = false;
        _busy = false;
      });
      HapticFeedback.lightImpact();
    });
  }

  Future<void> _undo() async {
    if (_history.isEmpty || _busy) return;
    final last = _history.removeLast();
    if (last.action == 2) {
      setState(() {
        _queue!
          ..remove(last.item)
          ..insert(_i, last.item);
      });
      return;
    }
    await ref.read(reviewServiceProvider).undo(last.item.id);
    ref.invalidate(trashSummaryProvider);
    if (mounted) {
      setState(() {
        _i--;
        _swept--;
        if (last.action == 1) {
          _trashedN--;
          _trashedBytes -= last.item.sizeBytes;
        }
      });
    }
  }

  Future<void> _finishSession({String? wrapMonth}) async {
    final r = await ref.read(sessionServiceProvider).finish(
          started: _started,
          goal: widget.goal,
          swept: _swept,
          trashed: _trashedN,
          bytes: _trashedBytes,
          streakBefore: widget.before!,
          monthKey: widget.plan!.startMonth,
          percentBefore: widget.targetPercent,
        );
    if (!mounted) return;
    ref.invalidate(sessionOverviewProvider);
    final nav = Navigator.of(context);
    nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => SessionDoneScreen(result: r)));
    // a month finished in this session: its wrap opens over the summary
    if (wrapMonth != null) nav.push(MaterialPageRoute<void>(builder: (_) => MonthWrapScreen(monthKey: wrapMonth)));
  }

  void _dismissHint() {
    if (!_hint) return;
    setState(() => _hint = false);
    ref.read(reviewServiceProvider).markSwipeHintSeen();
  }

  void _onDrag(DragUpdateDetails d) {
    if (_busy) return;
    _dismissHint();
    setState(() {
      _dx += d.delta.dx;
      _dy += d.delta.dy * .5;
    });
    final armed = _dx.abs() > 90 || _isUp;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.selectionClick();
    }
  }

  /// A clearly vertical upward drag means decide later.
  bool get _isUp => _dy < -55 && _dy.abs() > _dx.abs() * 1.3;

  void _onEnd(DragEndDetails d) {
    if (_busy) return;
    final v = d.velocity.pixelsPerSecond.dx;
    final vy = d.velocity.pixelsPerSecond.dy;
    if (_isUp || (vy < -1100 && vy.abs() > v.abs() * 1.5)) {
      _later();
    } else if (_dx < -90 || v < -900) {
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
          GlowOrb(left: -80, top: 120, width: 260, height: 260, color: glow.withValues(alpha: glowAlpha), blur: 70),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  SizedBox(
                    width: categoryOfSwipe(widget.source) != null && !widget.embedded ? 72 : 44,
                    child: widget.embedded
                        ? const SizedBox(height: 44)
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: l10n.back,
                    icon: const Icon(Icons.chevron_left_rounded),
                    style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
                  )),
                  ),
                  Expanded(
                    child: Column(children: [
                      Text(widget.eventTitle ?? (widget.month != null ? monthTitle(widget.month!) : (_inSession ? l10n.sessTitle : (widget.win != null ? quickWinTitle(widget.win!) : sourceTitle(widget.source)))), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(q == null ? '' : (_inSession ? l10n.sessProgress(math.min(_swept, widget.goal), math.min(widget.goal, q.length)) : l10n.swipeOf(math.min(_i + 1, q.length), q.length)), style: const TextStyle(fontSize: 12, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  if (categoryOfSwipe(widget.source) != null && !widget.embedded)
                    ModeSwitch<int>(
                      value: 1,
                      options: [
                        ModeOption(value: 0, label: l10n.modeGrid, icon: gridModeIcon),
                        ModeOption(value: 1, label: l10n.modeSwipe, icon: swipeModeIcon),
                      ],
                      onChanged: (_) => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                        builder: (_) => CategoryScreen(kind: categoryOfSwipe(widget.source)!, initialSource: widget.chatSource, win: widget.win),
                      )),
                    )
                  else
                    const SizedBox(width: 44, height: 44),
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
                            leave: math.max(_dx.abs() / (MediaQuery.sizeOf(context).width * .55), -_dy / 260).clamp(0.0, 1.0),
                            later: _isUp,
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
                      tooltip: l10n.tipTrash,
                      icon: const Icon(Icons.close_rounded, size: 28),
                      style: IconButton.styleFrom(
                        foregroundColor: SweeepColors.trash,
                        backgroundColor: SweeepColors.trash.withValues(alpha: .1),
                        side: const BorderSide(color: SweeepColors.trash),
                        fixedSize: const Size(60, 60),
                      ),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      onPressed: _history.isEmpty ? null : _undo,
                      tooltip: l10n.undo,
                      icon: const Icon(Icons.undo_rounded, size: 20),
                      style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, disabledForegroundColor: SweeepColors.trackUsed, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
                    ),
                    const SizedBox(width: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: neonGlow(SweeepColors.keep, strength: .8)),
                      child: IconButton(
                        onPressed: () => _decide(false),
                        tooltip: l10n.tipKeep,
                        icon: const Icon(Icons.check_rounded, size: 28),
                        style: IconButton.styleFrom(foregroundColor: SweeepColors.onAccent, backgroundColor: SweeepColors.keep, fixedSize: const Size(60, 60)),
                      ),
                    ),
                  ]),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, widget.embedded ? 90 : 12),
                child: _TrashBar(
                  count: summary?.count ?? 0,
                  bytes: summary?.bytes ?? 0,
                  progress: q == null || q.isEmpty ? 0 : _i / q.length,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrashScreen())).then((_) => _refreshOutside()),
                ),
              ),
            ]),
          ),
          if (_hint) _Hint(onDismiss: _dismissHint),
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
                  // 700 ms hop per letter, letters 70 ms apart (prototype D2)
                  final p = ((wave.value * 1120 - i * 70) / 700).clamp(0.0, 1.0);
                  final pose = waving ? jellySample(jellyHop, p) : (dy: 0.0, sy: 1.0);
                  return Jelly(
                    dy: pose.dy,
                    sy: pose.sy,
                    child: Text(word[i], style: TextStyle(fontSize: 46, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1, color: waving ? SweeepColors.trash : color)),
                  );
                }),
            ],
          );
        },
      );
}

class _Deck extends StatelessWidget {
  const _Deck({required this.item, required this.next, required this.dx, required this.dy, required this.leave, required this.later, required this.onDrag, required this.onEnd});
  final SwipeItem item;
  final SwipeItem? next;
  final double dx;
  final double dy;
  final double leave; // 0..1 how far the front card has left
  final bool later;
  final void Function(DragUpdateDetails) onDrag;
  final void Function(DragEndDetails) onEnd;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(item.createdAtMs);
    final trashA = (-dx / 90).clamp(0.0, 1.0);
    final keepA = (dx / 90).clamp(0.0, 1.0);
    // The card behind grows to full size as the front one leaves, so the
    // hand-over at the end of the fling is seamless.
    final p = Curves.easeOut.transform(leave);
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
                  if (item.isVideo) Positioned.fill(child: VideoLayer(key: ValueKey('video-${item.id}'), id: item.id)),
                  Positioned(left: 0, right: 0, top: 26, child: Center(child: Opacity(opacity: later ? (-dy / 90).clamp(0.0, 1.0) : 0, child: _Stamp(l10n.stampLater, SweeepColors.brand)))),
                    Positioned(right: 22, top: 26, child: Opacity(opacity: trashA, child: Transform.rotate(angle: 10 * math.pi / 180, child: _Stamp(l10n.stampTrash, SweeepColors.trash)))),
                  Positioned(left: 22, top: 26, child: Opacity(opacity: keepA, child: Transform.rotate(angle: -10 * math.pi / 180, child: _Stamp(l10n.stampKeep, SweeepColors.keep)))),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: GlassPill(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(item.isVideo && item.durationMs != null ? '${fmtDate(d)} · ${_videoLen(item.durationMs!)}' : fmtDate(d), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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

String _videoLen(int ms) {
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
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
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .7), border: Border.all(color: color, width: 3), borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ));
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
                  TextSpan(text: l10n.swipeInTrash(filesLabel(count)), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
            Text(empty ? l10n.swipeDoneNothing : l10n.swipeDoneAll, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(l10n.swipeDoneHint, textAlign: TextAlign.center, style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 15)),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: neonGlow(SweeepColors.brand)),
              child: FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(backgroundColor: SweeepColors.brand, foregroundColor: SweeepColors.onAccent, minimumSize: const Size(160, 52), shape: const StadiumBorder()),
              child: Text(l10n.back, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            ),
          ]),
        ),
      );
}

/// First-run overlay: a little hand shows the three gestures.
class _Hint extends StatefulWidget {
  const _Hint({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  State<_Hint> createState() => _HintState();
}

class _HintState extends State<_Hint> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onDismiss,
          child: ColoredBox(
            color: SweeepColors.background.withValues(alpha: .82),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                // hand path: centre, left, centre, right, centre, up
                final t = _c.value * 6;
                final seg = t.floor() % 6;
                final f = Curves.easeInOutCubic.transform(t - t.floor());
                const pts = [Offset(0, 0), Offset(-1, 0), Offset(0, 0), Offset(1, 0), Offset(0, 0), Offset(0, -1)];
                final a = pts[seg], b = pts[(seg + 1) % 6];
                final pos = Offset.lerp(a, b, f)!;
                final color = pos.dx < -.2 ? SweeepColors.trash : (pos.dx > .2 ? SweeepColors.keep : (pos.dy < -.2 ? SweeepColors.brand : SweeepColors.text));
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(l10n.hintTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 260,
                      height: 220,
                      child: Stack(alignment: Alignment.center, children: [
                        Positioned(left: 0, child: _Tip(Icons.arrow_back_rounded, l10n.hintTrash, SweeepColors.trash)),
                        Positioned(right: 0, child: _Tip(Icons.arrow_forward_rounded, l10n.hintKeep, SweeepColors.keep)),
                        Positioned(top: 0, child: _Tip(Icons.arrow_upward_rounded, l10n.hintLater, SweeepColors.brand)),
                        Transform.translate(
                          offset: Offset(pos.dx * 60, 24 + pos.dy * 50),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .18), border: Border.all(color: color, width: 2)),
                            child: Icon(Icons.touch_app_rounded, size: 36, color: color),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.hintTap, style: const TextStyle(fontSize: 14, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                  ]),
                );
              },
            ),
          ),
        ),
      );
}

class _Tip extends StatelessWidget {
  const _Tip(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ]);
}
