import 'package:flutter/material.dart';

import 'theme.dart';

/// One segment of a [ModeSwitch].
class ModeOption<T> {
  const ModeOption({required this.value, required this.label, required this.icon});
  final T value;
  final String label;

  /// Icon builder; gets the colour that fits the segment's state.
  final Widget Function(Color color) icon;
}

/// The little pill at the top of list screens to flip between ways of looking
/// at the same thing: Grid / Swipe, Grid / Months / Swipe. The lavender
/// highlight slides to the chosen segment.
class ModeSwitch<T> extends StatelessWidget {
  const ModeSwitch({super.key, required this.options, required this.value, required this.onChanged});
  final List<ModeOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == value);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(23), border: Border.all(color: SweeepColors.cardBorder)),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / options.length;
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: w * (index < 0 ? 0 : index),
            width: w,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SweeepColors.brand,
                borderRadius: BorderRadius.circular(19),
                boxShadow: neonShadow,
              ),
            ),
          ),
          Row(children: [
            for (final o in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: o.value == value,
                  label: o.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (o.value != value) onChanged(o.value);
                    },
                    child: Center(
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: o.value == value ? SweeepColors.onAccent : SweeepColors.textMutedSmall),
                        duration: const Duration(milliseconds: 220),
                        builder: (_, color, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                          o.icon(color ?? SweeepColors.textMutedSmall),
                          const SizedBox(width: 7),
                          Flexible(child: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: o.value == value ? FontWeight.w800 : FontWeight.w700, color: color))),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      }),
    );
  }

  static final neonShadow = [BoxShadow(color: SweeepColors.brand.withValues(alpha: .32), blurRadius: 14)];
}

/// Grid icon for [ModeSwitch] segments.
Widget gridModeIcon(Color c) => Icon(Icons.grid_view_rounded, size: 18, color: c);

/// Calendar icon for the Months segment.
Widget monthsModeIcon(Color c) => Icon(Icons.calendar_month_rounded, size: 18, color: c);

/// Swipe segment icon: two cards, one peeking out from behind the other.
Widget swipeModeIcon(Color c) => SwipeStackIcon(color: c);

/// Two cards, one peeking out from behind the other: the Swipe tab and mode.
class SwipeStackIcon extends StatelessWidget {
  const SwipeStackIcon({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(width: 22, height: 22, child: CustomPaint(painter: _StackPainter(color)));
}

class _StackPainter extends CustomPainter {
  const _StackPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final front = RRect.fromRectAndRadius(const Rect.fromLTWH(2.5, 6.5, 11.5, 14), const Radius.circular(3));
    final back = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 2, 11.5, 14), const Radius.circular(3));
    // the front card hides the part of the back card that is behind it
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(front.inflate(.9))));
    canvas.drawRRect(back, stroke..color = color.withValues(alpha: .7));
    canvas.restore();
    canvas.drawRRect(front, stroke..color = color);
  }

  @override
  bool shouldRepaint(_StackPainter old) => old.color != color;
}
