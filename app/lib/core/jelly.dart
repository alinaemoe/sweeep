import 'package:flutter/material.dart';

/// One key of a squash-and-stretch cycle: at progress [t] the glyph is moved
/// by [dy] pixels and stretched vertically by [sy].
typedef JellyKey = (double t, double dy, double sy);

/// The "jelly hop" from the design prototype (D2 swipe): up and stretched,
/// a small squashed landing, then rest. Plays once per letter.
const jellyHop = <JellyKey>[(0, 0, 1), (.35, -16, 1.25), (.65, 4, .9), (1, 0, 1)];

/// The looping wave of the CLEAAAN / SCANNING words (D3 trash, D4 scan).
const jellyLoop = <JellyKey>[(0, 0, 1), (.12, -14, 1.25), (.24, 3, .92), (.4, 0, 1), (1, 0, 1)];

/// Samples [keys] at progress [p] (0..1). Between two keys the motion eases
/// in and out, like CSS `ease-in-out` keyframes.
({double dy, double sy}) jellySample(List<JellyKey> keys, double p) {
  final x = p.clamp(0.0, 1.0);
  for (var i = 0; i < keys.length - 1; i++) {
    final a = keys[i], b = keys[i + 1];
    if (x <= b.$1) {
      final span = b.$1 - a.$1;
      final f = span == 0 ? 1.0 : Curves.easeInOut.transform((x - a.$1) / span);
      return (dy: a.$2 + (b.$2 - a.$2) * f, sy: a.$3 + (b.$3 - a.$3) * f);
    }
  }
  return (dy: keys.last.$2, sy: keys.last.$3);
}

/// Applies a jelly pose to [child]: translate first, then stretch around the
/// centre of the glyph box (same order as `translateY() scaleY()` in CSS).
class Jelly extends StatelessWidget {
  const Jelly({super.key, required this.dy, required this.sy, required this.child});
  final double dy;
  final double sy;
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: Offset(0, dy),
        child: Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(1, sy, 1), child: child),
      );
}
