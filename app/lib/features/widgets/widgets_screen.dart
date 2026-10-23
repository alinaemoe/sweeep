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

const _muted = Color(0xFF8A8F9E);

/// Test builds (`--dart-define=WIDGETS_EMPTY=true`) preview the state before any data exists.
const _empty = bool.fromEnvironment('WIDGETS_EMPTY');

/// Test builds (`--dart-define=WIDGETS_SAMPLE=true`) write the preview images the system widget picker shows.
const _sample = bool.fromEnvironment('WIDGETS_SAMPLE');

/// What one launcher row of the home screen is, in dp.
const _rowH = 106.0;

/// Home screen widgets: the three widgets drawn with the real renderer and real
/// numbers; tapping one asks the launcher to place it.
class WidgetsScreen extends ConsumerStatefulWidget {
  const WidgetsScreen({super.key});

  @override
  ConsumerState<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends ConsumerState<WidgetsScreen> {
  bool _howTo = false;
  int _stamp = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    // the previews show what the widgets show right now
    await WidgetSync(ref.read(databaseProvider)).refresh();
    if (!mounted) return;
    setState(() => _stamp++);
    if (_sample) await HomeWidgets.dumpSamples();
  }

  /// The widgets themselves are the controls, as in the prototype: tap one to have the launcher place it.
  Future<void> _add(String kind) async {
    final ok = await HomeWidgets.pin(kind);
    if (!mounted) return;
    if (!ok) setState(() => _howTo = true);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final tile = (w - 40 - 16) / 2;
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
            _label(l10n.widgetToday, top: 24),
            Rise(
              delay: const Duration(milliseconds: 100),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: _Preview(
                      key: ValueKey('t$_stamp'),
                      kind: 'today',
                      w: w - 40,
                      h: _rowH,
                      onTap: () => _add('today'))),
            ),
            _label(l10n.widgetOneMin, top: 26),
            Rise(
              delay: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(children: [
                  _Preview(
                      key: ValueKey('m$_stamp'),
                      kind: 'minute',
                      w: tile,
                      h: _rowH,
                      onTap: () => _add('minute')),
                  const SizedBox(width: 16),
                  _Preview(
                      key: ValueKey('c$_stamp'),
                      kind: 'canfree',
                      w: tile,
                      h: _rowH,
                      onTap: () => _add('canfree')),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: CustomPaint(
                painter: _DashedBox(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                      _howTo
                          ? '${l10n.widgetsNote}\n\n${l10n.widgetHowTo}'
                          : l10n.widgetsNote,
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

  Widget _label(String t, {required double top}) => Padding(
        padding: EdgeInsets.fromLTRB(20, top, 20, 0),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _muted)),
      );
}

/// The widget as the launcher will draw it, from the Kotlin renderer.
class _Preview extends StatefulWidget {
  const _Preview(
      {super.key,
      required this.kind,
      required this.w,
      required this.h,
      required this.onTap});
  final String kind;
  final double w;
  final double h;
  final VoidCallback onTap;

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
  Widget build(BuildContext context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
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
      ));
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
