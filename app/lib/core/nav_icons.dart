import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'theme.dart';

/// Hub icon: four rounded squares (24 grid: rx 2, stroke 2, squares 6.5 at 4 and 13.5).
class HubIcon extends StatelessWidget {
  const HubIcon({super.key, this.size = 20, this.color = const Color(0xFFA9AEBB)});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _HubPainter(color));
}

class _HubPainter extends CustomPainter {
  const _HubPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeJoin = StrokeJoin.round;
    for (final o in const [(4.0, 4.0), (13.5, 4.0), (4.0, 13.5), (13.5, 13.5)]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.$1 * k, o.$2 * k, 6.5 * k, 6.5 * k), Radius.circular(2 * k)), p);
    }
  }

  @override
  bool shouldRepaint(_HubPainter old) => old.color != color;
}

/// Space icon: a circle r8 and a line from its top to the centre and on to the right.
class SpaceIcon extends StatelessWidget {
  const SpaceIcon({super.key, this.size = 22, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SpacePainter(color));
}

class _SpacePainter extends CustomPainter {
  const _SpacePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(12 * k, 12 * k), 8 * k, p);
    canvas.drawPath(
      Path()
        ..moveTo(12 * k, 4 * k)
        ..lineTo(12 * k, 12 * k)
        ..lineTo(20 * k, 12 * k),
      p,
    );
  }

  @override
  bool shouldRepaint(_SpacePainter old) => old.color != color;
}

/// The round Hub button of every tab header: 40x40, card fill, hairline border.
class HubButton extends StatelessWidget {
  const HubButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: l10n.tipHub,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SweeepColors.card, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .06))),
                child: const HubIcon(),
              ),
            ),
          ),
        ),
      );
}

/// "rise": opacity 0 and 14 down to rest, 0.5 s ease-out, after [delay].
class Rise extends StatefulWidget {
  const Rise({super.key, this.delay = Duration.zero, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeOut.transform(_c.value);
          return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child));
        },
        child: widget.child,
      );
}
