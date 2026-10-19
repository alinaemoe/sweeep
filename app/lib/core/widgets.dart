import 'package:flutter/material.dart';

import 'theme.dart';

/// SW + three stretched, fading E's + P, as in the logo.
class SweeepWordmark extends StatelessWidget {
  const SweeepWordmark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -size / 28, color: SweeepColors.text);
    TextSpan e(double o) => TextSpan(text: 'E', style: TextStyle(color: SweeepColors.brand.withValues(alpha: o)));
    return Semantics(
      label: 'Sweeep',
      child: ExcludeSemantics(
        child: Text.rich(TextSpan(style: base, children: [
          const TextSpan(text: 'SW'),
          e(1),
          e(.7),
          e(.4),
          const TextSpan(text: 'P'),
        ])),
      ),
    );
  }
}

class SweeepCard extends StatelessWidget {
  const SweeepCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: SweeepColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SweeepColors.cardBorder),
        ),
        child: child,
      );
}

/// Soft neon glow under an accent button (prototype: 0 0 24px accent @ 28%).
List<BoxShadow> neonGlow(Color c, {double strength = 1}) => [
      BoxShadow(color: c.withValues(alpha: .34 * strength), blurRadius: 26, spreadRadius: 0),
      BoxShadow(color: c.withValues(alpha: .22 * strength), blurRadius: 9),
    ];

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onPressed, this.color = SweeepColors.brand, this.height = 56});
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(height / 2), boxShadow: onPressed == null ? null : neonGlow(color)),
        child: SizedBox(
        height: height,
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: SweeepColors.onAccent,
            shape: const StadiumBorder(),
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
        ),
      ));
}
