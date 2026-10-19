import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Cold-start intro: SW + three E's that stretch in and glow, then the letters
/// hop one by one and the screen dissolves into the app underneath.
class SweeepIntro extends StatefulWidget {
  const SweeepIntro({super.key, required this.onDone, required this.onReveal});
  final VoidCallback onDone;

  /// Called once, just before the dissolve starts: the app beneath may paint now.
  final VoidCallback onReveal;

  @override
  State<SweeepIntro> createState() => _SweeepIntroState();
}

class _SweeepIntroState extends State<SweeepIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_revealed && _c.value > .8) {
        _revealed = true;
        widget.onReveal();
      }
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    const letters = ['S', 'W', 'E', 'E', 'E', 'P'];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final fade = 1 - Curves.easeIn.transform(_seg(t, .9, 1));
        final glow = Curves.easeOut.transform(_seg(t, .15, .5)) * (.85 + .15 * math.sin(t * math.pi * 6));
        return IgnorePointer(
          ignoring: fade < .5,
          child: Opacity(
            opacity: fade,
            child: Material(
              type: MaterialType.transparency,
              child: ColoredBox(
              color: SweeepColors.background,
              child: Center(
                child: Transform.scale(
                  scale: 1 + .04 * Curves.easeIn.transform(_seg(t, .9, 1)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < letters.length; i++) _letter(letters[i], i, t, glow),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _letter(String ch, int i, double t, double glow) {
    final isE = ch == 'E';
    // arrival: S and W fade in first, each E stretches open one after another
    final start = isE ? .08 + (i - 2) * .09 : (i == 0 ? 0.0 : .04);
    final a = _seg(t, start, start + (isE ? .3 : .16));
    final grow = isE ? Curves.easeOutBack.transform(a) : Curves.easeOut.transform(a);
    // hop at the end, one letter after another
    final hop = _seg(t, .6 + i * .04, .6 + i * .04 + .2);
    final y = -26 * math.sin(math.pi * hop);
    final peak = math.sin(math.pi * hop);
    final color = isE ? Color.lerp(SweeepColors.brand, Colors.white, .5 * peak)! : Color.lerp(SweeepColors.text, SweeepColors.brand, .6 * peak)!;
    final style = TextStyle(
      fontSize: 60,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -2,
      color: color.withValues(alpha: a.clamp(0.0, 1.0)),
    );
    Widget text = Text(ch, style: style);
    if (isE) {
      // squeezed at first, stretched past full width, then settles
      final g = (glow * .55 + .25 * peak) * a;
      text = Align(
        alignment: Alignment.center,
        widthFactor: grow.clamp(0.0, 1.2),
        heightFactor: 1,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned(
            left: -34,
            right: -34,
            top: -20,
            bottom: -20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [SweeepColors.brand.withValues(alpha: g.clamp(0.0, 1.0)), SweeepColors.brand.withValues(alpha: 0)]),
              ),
            ),
          ),
          Transform.scale(scaleX: .15 + .85 * grow, child: text),
        ]),
      );
    }
    return Transform.translate(offset: Offset(0, y), child: text);
  }
}
