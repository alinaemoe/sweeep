import 'package:flutter/material.dart';

/// Lock from the prototype (24 grid): rect 5,11 14x9 r3 and a shackle, stroke 1.8.
class LockIcon extends StatelessWidget {
  const LockIcon({super.key, this.size = 46, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LockPainter(color));
}

class _LockPainter extends CustomPainter {
  const _LockPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(5 * k, 11 * k, 14 * k, 9 * k),
            Radius.circular(3 * k)),
        p);
    canvas.drawPath(
      Path()
        ..moveTo(8 * k, 11 * k)
        ..lineTo(8 * k, 8 * k)
        ..arcToPoint(Offset(16 * k, 8 * k), radius: Radius.circular(4 * k))
        ..lineTo(16 * k, 11 * k),
      p,
    );
  }

  @override
  bool shouldRepaint(_LockPainter old) => old.color != color;
}

/// Check mark "M5 12l5 5 9-10" at the given stroke width (24 grid).
class CheckIcon extends StatelessWidget {
  const CheckIcon(
      {super.key,
      required this.size,
      required this.color,
      required this.stroke});
  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size.square(size), painter: _CheckPainter(color, stroke));
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color, this.stroke);
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.drawPath(
      Path()
        ..moveTo(5 * k, 12 * k)
        ..lineTo(10 * k, 17 * k)
        ..lineTo(19 * k, 7 * k),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.color != color || old.stroke != stroke;
}
