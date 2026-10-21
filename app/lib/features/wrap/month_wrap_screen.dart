import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/jelly.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/month_wrap_service.dart';
import '../../index/review_service.dart';
import '../../l10n/l10n.dart';
import '../../platform/image_saver.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart';
import '../swipe/swipe_screen.dart';

/// Test builds (`--dart-define=WRAP_DEMO=true`): long-press the Timeline headline
/// to open the wrap of the newest month, finished or not.
const wrapDemo = bool.fromEnvironment('WRAP_DEMO');

/// JUNE -> JUUUNE: the first vowel after the first letter is tripled, like the
/// stretched words everywhere else in the app.
String stretchMonth(String name) {
  const vowels = 'AEIOUYАЕЁИОУЫЭЮЯ';
  final up = name.toUpperCase();
  for (var i = 1; i < up.length; i++) {
    if (vowels.contains(up[i])) return up.substring(0, i) + up[i] * 3 + up.substring(i + 1);
  }
  return up;
}

/// Month wrap (D14): the one-time card after a month reaches 100% decided.
class MonthWrapScreen extends ConsumerStatefulWidget {
  const MonthWrapScreen({super.key, required this.monthKey});
  final String monthKey;

  @override
  ConsumerState<MonthWrapScreen> createState() => _MonthWrapScreenState();
}

class _MonthWrapScreenState extends ConsumerState<MonthWrapScreen> with SingleTickerProviderStateMixin {
  static const _totalMs = 3600.0; // the longest thing (the shine) ends at 3.6 s

  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  final _cardKey = GlobalKey();
  MonthWrapData? _data;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(monthWrapServiceProvider)
      ..markShown(widget.monthKey)
      ..data(widget.monthKey).then((d) {
        if (!mounted) return;
        setState(() => _data = d);
        HapticFeedback.mediumImpact();
        _t.forward();
      });
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// Progress 0..1 of an animation that starts at [delay] ms and lasts [dur] ms.
  double _seg(double delay, double dur, [Curve curve = Curves.linear]) => curve.transform(((_t.value * _totalMs - delay) / dur).clamp(0.0, 1.0));

  Future<void> _save() async {
    if (_saving || _data == null) return;
    setState(() => _saving = true);
    // draw the finished card, not a half counted one
    if (!_t.isCompleted) {
      _t.value = 1;
      await WidgetsBinding.instance.endOfFrame;
    }
    String? where;
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      where = await ImageSaver.savePng(bytes, 'sweeep-${widget.monthKey}.png');
    } catch (_) {
      where = null;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(where == null ? l10n.wrapSaveFailed : l10n.wrapSaved), margin: const EdgeInsets.fromLTRB(16, 0, 16, 104)));
  }

  void _next(MonthWrapData d) {
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    if (d.nextMonth != null) nav.push(MaterialPageRoute<void>(builder: (_) => SwipeScreen(source: SwipeSource.all, month: d.nextMonth)));
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final width = MediaQuery.sizeOf(context).width;
    final y = int.parse(widget.monthKey.substring(0, 4));
    final m = int.parse(widget.monthKey.substring(5));
    return Scaffold(
      body: Stack(children: [
        GlowOrb(left: width / 2 - 170, top: 80, width: 340, height: 340, color: SweeepColors.brand.withValues(alpha: .2), blur: 90),
        SafeArea(
          child: d == null
              ? const SizedBox.expand()
              : AnimatedBuilder(
                  animation: _t,
                  builder: (_, __) => ListView(
                    padding: const EdgeInsets.only(bottom: 120),
                    children: [
                      _header(),
                      const SizedBox(height: 18),
                      Text(l10n.wrapLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3, color: SweeepColors.textMutedSmall)),
                      const SizedBox(height: 6),
                      _word(stretchMonth(fmtMonthName(y, m))),
                      const SizedBox(height: 10),
                      Stack(clipBehavior: Clip.none, children: [
                        _card(d, y, m),
                        // sparks burst from the top edge of the card, under the word
                        Positioned(left: width / 2 - 4, top: -10, child: _sparks()),
                      ]),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Text(l10n.wrapNote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall, height: 1.45)),
                      ),
                    ],
                  ),
                ),
        ),
        if (d != null)
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
                Expanded(
                  flex: 10,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _save,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: SweeepColors.text,
                      side: BorderSide(color: Colors.white.withValues(alpha: .12)),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(l10n.wrapSave, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 14, child: PillButton(height: 52, label: d.nextMonth == null ? l10n.doneDone : l10n.wrapNext(monthTitle(d.nextMonth!)), onPressed: () => _next(d))),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.back,
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
          ),
          const Spacer(),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: SweeepColors.keep.withValues(alpha: .14), borderRadius: BorderRadius.circular(15)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_rounded, size: 14, color: SweeepColors.keep),
              const SizedBox(width: 6),
              Text(l10n.wrapSwept, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: SweeepColors.keep)),
            ]),
          ),
        ]),
      );

  /// The month word: each letter hops twice, 70 ms apart.
  Widget _word(String word) {
    const keys = <JellyKey>[(0, 0, 1), (.35, -12, 1.2), (.65, 3, .92), (1, 0, 1)];
    return SizedBox(
      height: 84,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < word.length; i++)
              Builder(builder: (_) {
                final local = _t.value * _totalMs - i * 70;
                final run = local > 0 && local < 1600;
                final pose = run ? jellySample(keys, (local % 800) / 800) : (dy: 0.0, sy: 1.0);
                return Jelly(dy: pose.dy, sy: pose.sy, child: Text(word[i], style: const TextStyle(fontSize: 62, height: 1, fontWeight: FontWeight.w800, letterSpacing: -2, color: SweeepColors.brand)));
              }),
          ]),
        ),
      ),
    );
  }

  Widget _sparks() {
    const colors = [SweeepColors.brand, SweeepColors.keep, SweeepColors.trash];
    return IgnorePointer(
      child: SizedBox(
        width: 8,
        height: 8,
        child: Stack(clipBehavior: Clip.none, children: [
          for (var i = 0; i < 16; i++)
            Builder(builder: (_) {
              final a = i / 16 * math.pi * 2;
              final r = 110.0 + (i % 3) * 30;
              final k = _seg((.1 + (i % 4) * .05) * 1000, 1200, Curves.easeOut);
              return Positioned(
                left: math.cos(a) * r * k,
                top: math.sin(a) * r * .45 * k,
                child: Opacity(opacity: (1 - k).clamp(0.0, 1.0), child: Transform.scale(scale: 1 - .8 * k, child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i % 3])))),
              );
            }),
        ]),
      ),
    );
  }

  Widget _card(MonthWrapData d, int y, int m) {
    final count = _seg(0, 1700, Curves.easeOutCubic);
    final units = l10n.byteUnits.split(',');
    final inGb = d.freedBytes >= 1024 * 1024 * 1024;
    final freed = inGb ? d.freedBytes / (1024 * 1024 * 1024) : d.freedBytes / (1024 * 1024);
    final rise = _seg(150, 700, const Cubic(.2, .8, .2, 1));
    final shine = _seg(1000, 2600, Curves.easeInOut);
    return Opacity(
      opacity: rise,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - rise)),
        child: RepaintBoundary(
          key: _cardKey,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: SweeepColors.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 48, offset: Offset(0, 24))],
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(fmtMonth(y, m), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.6)),
                        const SizedBox(height: 2),
                        Text(l10n.wrapLooked(l10n.photosCount((d.looked * count).round())), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(fmtNum(freed * count, digits: inGb ? 1 : 0), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1, color: SweeepColors.trash)),
                      const SizedBox(height: 2),
                      Text(l10n.wrapCleared(inGb ? units[3] : units[2]), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
                    ]),
                  ]),
                  if (d.best.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(l10n.wrapBest, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: SweeepColors.textMutedSmall)),
                    const SizedBox(height: 8),
                    _mosaic(d.best),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .08)))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _stat(fmtNum((d.kept * count).round()), l10n.wrapKept, SweeepColors.keep),
                      _stat(fmtNum((d.trashed * count).round()), l10n.wrapTrashed, SweeepColors.trash),
                      _stat(fmtNum(d.sessions), l10n.wrapSessions(d.sessions), SweeepColors.text),
                      _stat(l10n.sessDays(d.streak), l10n.wrapStreak, SweeepColors.brand, end: true),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text.rich(
                      TextSpan(style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -.3), children: [
                        TextSpan(text: 'SW'),
                        TextSpan(text: 'EEE', style: TextStyle(color: SweeepColors.brand)),
                        TextSpan(text: 'P'),
                      ]),
                    ),
                  ),
                ]),
              ),
              // the light sweeping across the card, once
              if (shine > 0 && shine < 1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (_, c) => Stack(children: [
                        Positioned(
                          left: -84 + 276 * shine,
                          top: 0,
                          bottom: 0,
                          width: 60,
                          child: Transform(
                            transform: Matrix4.skewX(-18 * math.pi / 180),
                            child: ColoredBox(color: Colors.white.withValues(alpha: .07)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color, {bool end = false}) => Column(
        crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
        ],
      );

  /// One big BEST tile (2x2) and up to five small ones, popping in one by one.
  Widget _mosaic(List<String> ids) {
    const bgs = [Color(0xFF2E3A59), Color(0xFF4A3A42), Color(0xFF2F4A45), Color(0xFF4A452F), Color(0xFF3A2F59), Color(0xFF2E4A59)];
    // grid cells: (column, row, spanCols, spanRows)
    const cells = [(0, 0, 2, 2), (2, 0, 1, 1), (2, 1, 1, 1), (0, 2, 1, 1), (1, 2, 1, 1), (2, 2, 1, 1)];
    final rows = ids.length >= 4 ? 3 : (ids.length >= 2 ? 2 : 2);
    return LayoutBuilder(
      builder: (_, c) {
        const gap = 8.0;
        final cell = (c.maxWidth - gap * 2) / 3;
        final small = 76.0;
        final h = rows == 3 ? 160 + gap + small : 160.0;
        double left(int col) => col * (cell + gap);
        double top(int row) => row * (small + gap);
        return SizedBox(
          height: h,
          child: Stack(children: [
            for (var i = 0; i < ids.length && i < 6; i++)
              Positioned(
                left: left(cells[i].$1),
                top: top(cells[i].$2),
                width: cells[i].$3 * cell + (cells[i].$3 - 1) * gap,
                height: cells[i].$4 * small + (cells[i].$4 - 1) * gap,
                child: _pop(i, _tile(ids[i], bgs[i], best: i == 0)),
              ),
          ]),
        );
      },
    );
  }

  /// The tile "pop": small and tilted, overshoots a little, settles.
  Widget _pop(int i, Widget child) {
    final p = ((_t.value * _totalMs - (500 + i * 90)) / 600).clamp(0.0, 1.0);
    const ease = Cubic(.2, .8, .2, 1);
    double scale, rot;
    if (p < .7) {
      final k = ease.transform(p / .7);
      scale = .6 + (1.06 - .6) * k;
      rot = (-4 + (1 - -4) * k) * math.pi / 180;
    } else {
      final k = ease.transform((p - .7) / .3);
      scale = 1.06 + (1 - 1.06) * k;
      rot = (1 - 1 * k) * math.pi / 180;
    }
    return Opacity(opacity: ease.transform(p), child: Transform.rotate(angle: rot, child: Transform.scale(scale: scale, child: child)));
  }

  Widget _tile(String id, Color bg, {required bool best}) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: best ? SweeepColors.keep : Colors.white.withValues(alpha: .1), width: best ? 2 : 1),
        ),
        child: Stack(fit: StackFit.expand, children: [
          ThumbImage(id: id, side: best ? 384 : 192),
          if (best)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SweeepColors.keep, borderRadius: BorderRadius.circular(10)),
                child: const Text('BEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8, color: SweeepColors.onAccent)),
              ),
            ),
        ]),
      );
}
