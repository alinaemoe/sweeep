import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/group_service.dart';
import '../../index/home_service.dart';
import '../../providers.dart';
import '../groups/group_pager.dart';
import '../groups/group_widgets.dart';
import '../groups/groups_screen.dart';
import '../library/library_screen.dart';
import '../category/category_screen.dart';
import '../swipe/swipe_screen.dart';
import '../../index/review_service.dart';

/// Home: a pinned top bar, a "reclaimable" oval that collapses into a compact
/// chip while scrolling, and a feed of category carousels.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  static const _collapseAt = 160.0;
  final _scroll = ScrollController();

  /// Drives the bubbles running around the oval while the library is processed.
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  /// 1 = idle oval (reclaimable arc), 0 = scanning (progress ring + bubbles).
  /// Moving between the two is what makes the scan start and end smoothly:
  /// the ring collapses into the reclaimable segment, bubbles flow into it.
  late final AnimationController _mix = AnimationController(vsync: this, value: 0) // Home starts a sync right away
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && _mix.value == 1 && !_busy) _loop.stop();
    });
  Timer? _settleTimer;
  bool _busy = false;
  double _shown = 0; // eased progress shown on the ring, 0..1
  double _reclaimShown = 0; // eased reclaimable bytes, so the number counts up
  double _shareShown = 0; // eased reclaimable share of the library
  String _lastLabel = '';

  void _onBusy(bool busy) {
    _busy = busy;
    _settleTimer?.cancel();
    if (busy) {
      if (_mix.value == 1) _shown = 0;
      if (!_loop.isAnimating) _loop.repeat();
      _mix.animateTo(0, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    } else {
      // Wait a beat (stages hand over to each other), then fold the ring into the result.
      _settleTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted && !_busy) _mix.animateTo(1, duration: const Duration(milliseconds: 1800), curve: Curves.easeInOutCubic);
      });
    }
  }

  /// Overall scan progress 0..1 (read library 0-8%, hash 8-80%, compare 80-100%).
  static double _progressOf(LibraryState s) {
    double frac(int done, int total) => total <= 0 ? 1 : (done / total).clamp(0.0, 1.0);
    if (s.syncing) return .04;
    if (s.analyzing) return .08 + .72 * frac(s.alreadyHashed + s.analysisDone, s.alreadyHashed + s.analysisTotal);
    if (s.verifying) return .8 + .2 * (s.verifyTotal == 0 ? 0 : frac(s.verifyDone, s.verifyTotal));
    return 1;
  }

  static String _labelOf(LibraryState s) {
    if (s.syncing) return 'READING LIBRARY';
    if (s.analyzing) return 'ANALYZING ${_n(s.alreadyHashed + s.analysisDone)} OF ${_n(s.alreadyHashed + s.analysisTotal)}';
    return 'COMPARING FILES';
  }

  @override
  void initState() {
    super.initState();
    _busy = true;
    _loop.repeat();
    Future.microtask(() => ref.read(libraryProvider.notifier).sync());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _settleTimer?.cancel();
    _loop.dispose();
    _mix.dispose();
    super.dispose();
  }

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final lib = ref.watch(libraryProvider);
    final top = MediaQuery.paddingOf(context).top;
    final busy = lib.syncing || lib.analyzing || lib.verifying;
    ref.listen(libraryProvider.select((s) => s.syncing || s.analyzing || s.verifying), (_, b) => _onBusy(b));
    final data = home.value;
    // While busy follow the real progress; while settling run it to 100%.
    final target = busy ? _progressOf(lib) : 1.0;
    final scanLabel = busy ? _labelOf(lib) : _lastLabel;
    if (busy) _lastLabel = scanLabel;
    final reclaimNow = (data?.reclaimableBytes ?? 0).toDouble();
    final libBytes = data?.libraryBytes ?? 0;
    final shareNow = libBytes == 0 ? 0.0 : (reclaimNow / libBytes).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            left: -140,
            top: -60,
            child: IgnorePointer(
              child: SizedBox(
                width: 460,
                height: 420,
                child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0x1FB8A6FF), Color(0x00B8A6FF)]))),
              ),
            ),
          ),
          // Scrolling feed, under the pinned header.
          Positioned.fill(
            child: ListView(
              controller: _scroll,
              cacheExtent: 1400, // build and decode the lower carousels before they scroll in
              padding: EdgeInsets.fromLTRB(0, top + 64 + 260 - 6, 0, 120),
              children: [
                if (data == null && home.hasError)
                  Padding(padding: const EdgeInsets.all(20), child: Text('${home.error}', style: const TextStyle(color: SweeepColors.trash)))
                else if (data != null) ..._feed(data)
                else
                  const _FeedSkeleton(),
              ],
            ),
          ),
          // Header: opaque backdrop + wordmark + collapsing oval.
          AnimatedBuilder(
            animation: Listenable.merge([_scroll, _loop, _mix]),
            builder: (context, _) {
              final off = _scroll.hasClients ? _scroll.offset : 0.0;
              final t = (off / _collapseAt).clamp(0.0, 1.0);
              if (_mix.value == 1 && !_loop.isAnimating) {
                // idle: show real values at once
                _reclaimShown = reclaimNow;
                _shareShown = shareNow;
              } else {
                if (target > _shown) _shown += (target - _shown) * .06; // ease up toward the real progress, never back
                _reclaimShown += (reclaimNow - _reclaimShown) * .08;
                _shareShown += (shareNow - _shareShown) * .08;
              }
              return _Header(
                top: top,
                t: t,
                data: data,
                mix: _mix.value,
                reclaimShown: _reclaimShown,
                shareShown: _shareShown,
                progress: _shown,
                phase: _loop.value,
                scanLabel: scanLabel,
                onSettings: () => _push(const LibraryScreen()),
                onFree: data == null || data.reclaimableBytes == 0
                    ? null
                    : () => _push(GroupsScreen(kind: data.duplicates.isNotEmpty ? GroupKind.duplicate : GroupKind.similar)),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _feed(HomeData d) {
    final empty = d.chat.count == 0 && d.duplicates.isEmpty && d.similar.isEmpty && d.screenshots.count == 0 && d.videos.count == 0 && d.blurry.count == 0;
    if (empty) {
      return const [
        Padding(
          padding: EdgeInsets.all(28),
          child: Text('Nothing to clean yet. Pull in more photos or re-scan later.',
              textAlign: TextAlign.center, style: TextStyle(color: SweeepColors.textMutedSmall, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ];
    }
    return [
      if (d.duplicates.isNotEmpty) ...[
        _SectionHeader('Duplicates', '${_n(d.duplicates.length)} · ${formatBytes(d.duplicateBytes)}', 'See all', () => _push(const GroupsScreen(kind: GroupKind.duplicate))),
        _GroupCarousel(groups: d.duplicates, big: true, onOpen: (i) => _push(GroupPager(kind: GroupKind.duplicate, initialIndex: i))),
      ],
      if (d.similar.isNotEmpty) ...[
        _SectionHeader('Similar photos', '${_n(d.similar.length)} · ${formatBytes(d.similarBytes)}', 'See all', () => _push(const GroupsScreen(kind: GroupKind.similar))),
        _GroupCarousel(groups: d.similar, big: false, onOpen: (i) => _push(GroupPager(kind: GroupKind.similar, initialIndex: i))),
      ],
      if (d.screenshots.count > 0) ...[
        _SectionHeader('Screenshots', '${_n(d.screenshots.count)} · ${formatBytes(d.screenshots.bytes)}', 'See all', () => _push(const CategoryScreen(kind: CategoryKind.screenshots))),
        _TileRow(height: 130, items: d.screenshots.items, builder: (it) => _Tile(item: it, width: 74, height: 130, radius: 14)),
      ],
      if (d.videos.count > 0) ...[
        _SectionHeader('Videos', '${_n(d.videos.count)} · ${formatBytes(d.videos.bytes)}', 'See all', () => _push(const CategoryScreen(kind: CategoryKind.videos))),
        _TileRow(height: 96, items: d.videos.items, builder: (it) => _Tile(item: it, width: 140, height: 96, radius: 18, video: true)),
      ],
      if (d.chat.count > 0) ...[
        _SectionHeader('Chat media', '${_n(d.chat.count)} · ${formatBytes(d.chat.bytes)}', 'See all', () => _push(const CategoryScreen(kind: CategoryKind.chat))),
        _TileRow(height: 96, items: d.chat.items, builder: (it) => _Tile(item: it, width: 96, height: 96, radius: 18, video: it.durationMs != null)),
      ],
      if (d.blurry.count > 0) ...[
        _SectionHeader('Blurry & dark', '${_n(d.blurry.count)} · ${formatBytes(d.blurry.bytes)}', 'Swipe', () => _push(const SwipeScreen(source: SwipeSource.blurry))),
        _TileRow(height: 96, items: d.blurry.items, builder: (it) => _Tile(item: it, width: 96, height: 96, radius: 18)),
      ],
    ];
  }
}

String _n(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

({String value, String unit}) _splitBytes(int bytes) {
  const u = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  return (value: v.toStringAsFixed(i < 3 ? 0 : 1), unit: u[i]);
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.meta, this.action, this.onAction);
  final String title;
  final String meta;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  TextSpan(text: '  · $meta', style: const TextStyle(fontSize: 13, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: SweeepColors.brand, minimumSize: const Size(48, 44), padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

/// Fanned stacks of duplicate / similar groups.
class _GroupCarousel extends StatelessWidget {
  const _GroupCarousel({required this.groups, required this.big, required this.onOpen});
  final List<GroupView> groups;
  final bool big;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final w = big ? 150.0 : 104.0;
    final h = big ? 176.0 : 104.0;
    final shown = math.min(groups.length, 14);
    return SizedBox(
      height: h + 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        itemCount: shown,
        separatorBuilder: (_, __) => SizedBox(width: big ? 22 : 18),
        itemBuilder: (context, i) => Pressable(
          onTap: () => onOpen(i),
          label: '${groups[i].kind == GroupKind.duplicate ? 'Duplicate' : 'Similar'} group, ${groups[i].members.length} photos, saves ${formatBytes(groups[i].savingsBytes)}',
          child: SizedBox(
            width: w,
            height: h,
            child: big ? GroupStack(group: groups[i], showBest: true, thumbSide: 320) : _CompactStack(group: groups[i], radius: 18),
          ),
        ),
      ),
    );
  }
}

/// Small stack: fanned frames with just a count badge.
class _CompactStack extends StatelessWidget {
  const _CompactStack({required this.group, required this.radius});
  final GroupView group;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final others = group.others;
    Widget layer(String id, double deg, Offset shift, double op) => Transform.translate(
          offset: shift,
          child: Transform.rotate(
            angle: deg * math.pi / 180,
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: Border.all(color: Colors.white.withValues(alpha: .16))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(fit: StackFit.expand, children: [
                  ThumbImage(id: id, side: 200),
                  ColoredBox(color: SweeepColors.background.withValues(alpha: 1 - op)),
                ]),
              ),
            ),
          ),
        );
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (others.length > 1) layer(others[1].assetId, -6, const Offset(-4, -2), .75),
        if (others.isNotEmpty) layer(others[0].assetId, 4, const Offset(4, -2), .9),
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: .12)), borderRadius: BorderRadius.circular(radius)),
            child: Stack(fit: StackFit.expand, children: [
              ThumbImage(id: group.bestId, side: 200),
              Positioned(
                right: 8,
                bottom: 8,
                child: GlassPill(height: 22, padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('×${group.members.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.height, required this.items, required this.builder});
  final double height;
  final List<HomeItem> items;
  final Widget Function(HomeItem) builder;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height + 10,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => builder(items[i]),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.width, required this.height, required this.radius, this.video = false});
  final HomeItem item;
  final double width;
  final double height;
  final double radius;
  final bool video;

  String _len(int ms) {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget badge(String text, {bool left = false}) => Positioned(
          left: left ? 8 : null,
          right: left ? null : 8,
          bottom: 8,
          child: GlassPill(height: 20, padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
        );
    return Semantics(
      label: video ? 'Video${item.durationMs != null ? ', ${_len(item.durationMs!)}' : ''}, ${formatBytes(item.sizeBytes)}' : '${item.tag ?? 'Photo'}, ${formatBytes(item.sizeBytes)}',
      child: SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: Border.all(color: Colors.white.withValues(alpha: .12))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(fit: StackFit.expand, children: [
            ThumbImage(id: item.id, side: 200),
            if (video) ...[
              Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .55), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, size: 20, color: SweeepColors.text),
                ),
              ),
              if (item.durationMs != null) badge(_len(item.durationMs!), left: true),
              badge(formatBytes(item.sizeBytes)),
            ],
            if (item.tag != null) badge(item.tag!, left: true),
          ]),
        ),
      ),
    ));
  }
}

/// Pinned header. [t] = 0 expanded oval, 1 collapsed chip with inline CTA.
class _Header extends StatelessWidget {
  const _Header({
    required this.top,
    required this.t,
    required this.data,
    required this.mix,
    required this.reclaimShown,
    required this.shareShown,
    required this.progress,
    required this.phase,
    required this.scanLabel,
    required this.onSettings,
    required this.onFree,
  });
  final double top;
  final double t;
  final HomeData? data;

  /// 1 = result shown, 0 = scanning; in between the ring folds into the result.
  final double mix;
  final double reclaimShown;
  final double shareShown;
  final double progress;
  final double phase;
  final String scanLabel;
  final VoidCallback onSettings;
  final VoidCallback? onFree;

  @override
  Widget build(BuildContext context) {
    double lerp(double a, double b) => a + (b - a) * t;
    final width = MediaQuery.sizeOf(context).width - 40;
    final heroTop = top + 64;
    final heroH = lerp(260, 100);
    final reclaim = data?.reclaimableBytes ?? 0;
    final lib = data?.libraryBytes ?? 0;
    final reclaimBig = _splitBytes(reclaim);
    final shownBig = _splitBytes(reclaimShown.round());
    final scanning = mix < .5;
    // Cross-fade percent -> result in the middle of the fold.
    final textAlpha = (scanning ? 1 - mix * 2 : mix * 2 - 1).clamp(0.0, 1.0);
    final big = scanning ? (value: '${(progress * 100).round()}', unit: '%') : shownBig;
    final busy = scanning;
    final scale = lerp(1, .4);
    final ctaW = lerp(width, 182);
    final ctaH = lerp(48, 44);
    final ctaL = lerp(0, width - 182 - 0);
    final ctaT = lerp(212, 46);

    return Stack(children: [
      Positioned(left: 0, right: 0, top: 0, height: heroTop + heroH + 8, child: const ColoredBox(color: SweeepColors.background)),
      // soft fade instead of a hard cut where the feed slides under the header
      Positioned(
        left: 0,
        right: 0,
        top: heroTop + heroH + 8,
        height: 18,
        child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [SweeepColors.background, Color(0x000F1015)]))),
      ),
      Positioned(
        left: 20,
        right: 20,
        top: top + 12,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SweeepWordmark(),
            IconButton(
              onPressed: onSettings,
              tooltip: 'Library details',
              icon: const Icon(Icons.settings_outlined, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: SweeepColors.card,
                foregroundColor: SweeepColors.textMuted,
                side: const BorderSide(color: SweeepColors.cardBorder),
                fixedSize: const Size(40, 40),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 20,
        top: heroTop,
        width: width,
        height: heroH,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SweeepColors.card.withValues(alpha: math.min(1, t * 1.4)),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: .06 * math.min(1, t * 1.4))),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: width,
            height: 210,
            child: Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.translationValues(lerp(0, 8), lerp(0, 8), 0)..scaleByDouble(scale, scale, 1, 1),
              child: Stack(children: [
                Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _OvalPainter(share: shareShown, mix: mix, progress: progress, phase: phase)))),
                Center(
                  child: Opacity(
                    opacity: textAlpha,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(data == null && !busy ? '–' : big.value, style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w800, letterSpacing: -4, height: 1)),
                        const SizedBox(width: 6),
                        Text(big.unit, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SweeepColors.brand)),
                      ],
                    ),
                    Opacity(
                      opacity: math.max(0, 1 - t * 3),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          busy ? scanLabel : (data == null ? '' : 'RECLAIMABLE OF ${_fmtSize(lib)}'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: SweeepColors.textMutedSmall),
                        ),
                      ),
                    ),
                  ]),
                  ),
                ),
              ]),
            ),
          ),
          Positioned(
            left: 160,
            top: 20,
            child: Opacity(
              opacity: math.max(0, t * 3 - 2),
              child: Text(busy ? 'SCANNING' : 'RECLAIMABLE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: SweeepColors.textMutedSmall)),
            ),
          ),
          Positioned(
            left: ctaL,
            top: ctaT,
            width: ctaW,
            height: ctaH,
            child: FilledButton(
              onPressed: onFree,
              style: FilledButton.styleFrom(
                backgroundColor: SweeepColors.brand,
                foregroundColor: SweeepColors.onAccent,
                disabledBackgroundColor: SweeepColors.trackDim,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                padding: EdgeInsets.zero,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(reclaim == 0 ? (busy ? 'Scanning…' : 'All clean') : 'Free up ${reclaimBig.value} ${reclaimBig.unit}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

String _fmtSize(int bytes) {
  final s = _splitBytes(bytes);
  return '${s.value} ${s.unit}';
}

/// The three-layer ring: dim track, grey "everything else", glowing lavender
/// arc for the reclaimable share of the library.
class _OvalPainter extends CustomPainter {
  _OvalPainter({required this.share, required this.mix, required this.progress, required this.phase});
  final double share; // eased reclaimable share of the library
  final double mix; // 1 = result, 0 = scanning
  final double progress; // 0..1, eased scan progress
  final double phase; // 0..1 looping, drives the bubbles

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    final path = Path()..addOval(rect);
    final metric = path.computeMetrics().first;
    final len = metric.length;

    Paint stroke(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = c;

    canvas.drawPath(path, stroke(SweeepColors.trackDim)..strokeCap = StrokeCap.butt);
    Path arc(double from, double to) => metric.extractPath(len * from, len * to);
    // metric starts at 3 o'clock going clockwise; offset by a quarter so 0 = 12 o'clock.
    const start = 0.75;
    Path seg(double a, double b) {
      final s = (start + a) % 1, e = (start + b) % 1;
      if (e > s) return arc(s, e);
      return Path()
        ..addPath(arc(s, 1), Offset.zero)
        ..addPath(arc(0, e), Offset.zero);
    }

    // mix 0 = scanning, 1 = result. Everything below is a morph between the
    // two so the scan folds into the reclaimable arc instead of switching.
    final m = mix.clamp(0.0, 1.0);
    final glowW = math.max(share, .02);
    final segA = .6, segB = math.min(.6 + glowW * .9, .995);
    double lerp(double a, double b, double t) => a + (b - a) * t;

    // grey "everything else" arc grows in during the second half of the fold
    final restAlpha = ((m - .45) / .55).clamp(0.0, 1.0);
    final rest = (1 - share).clamp(0.0, 1.0) * .56;
    if (rest > 0 && restAlpha > 0) {
      canvas.drawPath(seg(0, rest), stroke(SweeepColors.trackUsed.withValues(alpha: restAlpha)));
    }

    // Lavender arc: the scan-progress ring (0 -> progress) collapses into the
    // reclaimable segment (segA -> segB); the start leads, the end follows.
    final fill = progress.clamp(0.0, 1.0);
    final a = lerp(0, segA, Curves.easeInOutCubic.transform(m));
    final b = math.min(lerp(fill, segB, m), .999);
    if (b - a > .004) {
      canvas.drawPath(seg(a, b), stroke(SweeepColors.brand.withValues(alpha: lerp(.3, .5, m)))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawPath(seg(a, b), stroke(SweeepColors.brand.withValues(alpha: lerp(.85, 1, m))));
    }

    // Bubbles run clockwise around the ring and, while folding, flow into the
    // segment (shrinking and fading) so nothing just disappears.
    if (m < 1) {
      const n = 7;
      final target = (start + (segA + segB) / 2) % 1.0;
      final flow = Curves.easeInOut.transform(m);
      for (var i = 0; i < n; i++) {
        final f0 = (start + phase + i / n) % 1.0;
        final t = (target + (i - (n - 1) / 2) * .008) % 1.0;
        final delta = ((t - f0) % 1.0 + 1.0) % 1.0; // clockwise distance to the segment
        final f = (f0 + delta * flow) % 1.0;
        final pos = metric.getTangentForOffset(len * f)?.position;
        if (pos == null) continue;
        final pulse = .5 + .5 * math.sin(2 * math.pi * (phase * 2 + i * .29));
        final life = 1 - flow;
        final r = (2.5 + 5.5 * pulse) * (.3 + .7 * life);
        final al = (.25 + .65 * pulse) * life;
        canvas.drawCircle(pos, r + 4, Paint()..color = SweeepColors.brand.withValues(alpha: al * .45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawCircle(pos, r, Paint()..color = Color.lerp(SweeepColors.brand, Colors.white, .35 * pulse)!.withValues(alpha: al));
      }
    }
  }

  @override
  bool shouldRepaint(_OvalPainter old) => old.share != share || old.mix != mix || old.progress != progress || old.phase != phase;
}

/// Placeholder shown while the library data loads: the same shapes as the
/// real carousels, softly pulsing.
class _FeedSkeleton extends StatefulWidget {
  const _FeedSkeleton();

  @override
  State<_FeedSkeleton> createState() => _FeedSkeletonState();
}

class _FeedSkeletonState extends State<_FeedSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final color = Color.lerp(SweeepColors.trackDim, const Color(0xFF2A2D3A), Curves.easeInOut.transform(_c.value))!;
          Widget block(double w, double h, double r) => Container(width: w, height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)));
          Widget title() => Padding(padding: const EdgeInsets.fromLTRB(20, 26, 20, 0), child: Align(alignment: Alignment.centerLeft, child: block(150, 18, 9)));
          Widget row(double w, double h, double r, int n, double gap, double top) => SizedBox(
                height: h + top,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(20, top, 20, 0),
                  itemCount: n,
                  separatorBuilder: (_, __) => SizedBox(width: gap),
                  itemBuilder: (_, __) => block(w, h, r),
                ),
              );
          return ExcludeSemantics(
            child: Column(children: [
              title(),
              row(150, 176, 22, 3, 22, 16),
              title(),
              row(104, 104, 18, 4, 18, 16),
              title(),
              row(74, 130, 14, 5, 10, 12),
              title(),
              row(140, 96, 18, 3, 10, 12),
            ]),
          );
        },
      );
}
