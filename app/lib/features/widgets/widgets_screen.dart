import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/widget_sync.dart';
import '../../l10n/l10n.dart';
import '../../platform/widgets.dart';
import '../../providers.dart';
import '../apps/apps_icons.dart';

const _muted = Color(0xFF8A8F9E);

/// Test builds (`--dart-define=WIDGETS_EMPTY=true`) preview the state before any data exists.
const _empty = bool.fromEnvironment('WIDGETS_EMPTY');

/// Home screen widgets: the three widgets drawn with the real renderer and real
/// numbers, and a button that asks the launcher to place each one.
class WidgetsScreen extends ConsumerStatefulWidget {
  const WidgetsScreen({super.key});

  @override
  ConsumerState<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends ConsumerState<WidgetsScreen>
    with WidgetsBindingObserver {
  static const kinds = ['today', 'minute', 'canfree'];
  final Map<String, bool> _added = {};
  final Set<String> _howTo = {};
  int _stamp = 0;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepare();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _prepare() async {
    // the previews show what the widgets show right now
    await WidgetSync(ref.read(databaseProvider)).refresh();
    if (!mounted) return;
    setState(() => _stamp++);
    _check();
  }

  Future<void> _check() async {
    for (final k in kinds) {
      final v = await HomeWidgets.isAdded(k);
      if (!mounted) return;
      if (_added[k] != v) setState(() => _added[k] = v);
    }
  }

  Future<void> _add(String kind) async {
    final ok = await HomeWidgets.pin(kind);
    if (!mounted) return;
    if (!ok) {
      setState(() => _howTo.add(kind));
      return;
    }
    // the launcher confirms in its own dialog; look for the new widget for a few seconds
    var n = 0;
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 1), (t) {
      _check();
      if (++n >= 12 || (_added[kind] ?? false)) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Stack(children: [
        GlowOrb(
            right: -60,
            top: 40,
            width: 260,
            height: 260,
            color: SweeepColors.brand.withValues(alpha: .12),
            blur: 70),
        ListView(
          padding: const EdgeInsets.only(top: 52, bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: l10n.back,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: SweeepColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .06))),
                      child: const Icon(Icons.chevron_left_rounded,
                          size: 22, color: SweeepColors.text),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(l10n.widgetsTitle,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1)),
            ),
            _section(0, l10n.widgetToday, 'today', w - 40, 150, delay: 100),
            _section(1, l10n.widgetOneMin, 'minute', 150, 150, delay: 180),
            _section(2, l10n.widgetCanFree, 'canfree', 150, 150, delay: 260),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: CustomPaint(
                painter: _DashedBox(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.widgetsNote,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                          height: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _section(int i, String label, String kind, double pw, double ph,
      {required int delay}) {
    final added = _added[kind] ?? false;
    return Rise(
      delay: Duration(milliseconds: delay),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _muted)),
          const SizedBox(height: 10),
          _Preview(key: ValueKey('$kind$_stamp'), kind: kind, w: pw, h: ph),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: added ? null : () => _add(kind),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: added ? Colors.transparent : SweeepColors.brand,
                borderRadius: BorderRadius.circular(22),
                border: added
                    ? Border.all(color: Colors.white.withValues(alpha: .12))
                    : null,
                boxShadow: added
                    ? null
                    : [
                        BoxShadow(
                            color: SweeepColors.brand.withValues(alpha: .25),
                            blurRadius: 24)
                      ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (added) ...[
                  const CheckIcon(
                      size: 16, color: SweeepColors.brand, stroke: 3),
                  const SizedBox(width: 8)
                ],
                Text(added ? l10n.widgetAdded : l10n.widgetAdd,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: added
                            ? SweeepColors.brand
                            : SweeepColors.onAccent)),
              ]),
            ),
          ),
          if (_howTo.contains(kind))
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.widgetHowTo,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted))),
        ]),
      ),
    );
  }
}

/// The widget as the launcher will draw it, from the Kotlin renderer.
class _Preview extends StatefulWidget {
  const _Preview(
      {super.key, required this.kind, required this.w, required this.h});
  final String kind;
  final double w;
  final double h;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  Future<Uint8List?>? _png;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _png ??= HomeWidgets.preview(widget.kind,
        w: widget.w,
        h: widget.h,
        density: MediaQuery.devicePixelRatioOf(context),
        empty: _empty);
  }

  @override
  Widget build(BuildContext context) => Container(
        width: widget.w,
        height: widget.h,
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(32), boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .4),
              blurRadius: 36,
              offset: const Offset(0, 18))
        ]),
        child: FutureBuilder<Uint8List?>(
          future: _png,
          builder: (_, s) => s.data == null
              ? const SizedBox.shrink()
              : Image.memory(s.data!,
                  width: widget.w,
                  height: widget.h,
                  fit: BoxFit.fill,
                  gaplessPlayback: true),
        ),
      );
}

class _DashedBox extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24));
    final path = Path()..addRRect(rr);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => false;
}
