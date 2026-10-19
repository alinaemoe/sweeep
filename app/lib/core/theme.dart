import 'package:flutter/material.dart';

/// Sweeep design tokens ("Obsidian + Lavender").
///
/// Role rules: [keep] (lime) is ONLY for "keep / best pick"; [brand]
/// (lavender) is every other brand accent; [trash] (coral) is deletion.
abstract final class SweeepColors {
  static const background = Color(0xFF0F1015);
  static const card = Color(0xFF181920);
  static const cardBorder = Color(0x0FFFFFFF); // white @ 6%
  static const trackDim = Color(0xFF1F212B);
  static const trackUsed = Color(0xFF3A3E4D);

  static const brand = Color(0xFFB8A6FF);
  static const keep = Color(0xFFD4F563);
  static const trash = Color(0xFFFF5A5A);

  static const text = Color(0xFFF2F3F7);
  static const textMuted = Color(0xFF8A8F9E);
  static const textMutedSmall = Color(0xFFA9AEBB); // >= 4.5:1 on card
  static const onAccent = Color(0xFF0F1015);
}

abstract final class SweeepTheme {
  static ThemeData dark() {
    final base = ThemeData(
      fontFamily: 'PlusJakartaSans',
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: SweeepColors.background,
      colorScheme: const ColorScheme.dark(
        primary: SweeepColors.brand,
        onPrimary: SweeepColors.onAccent,
        secondary: SweeepColors.keep,
        onSecondary: SweeepColors.onAccent,
        error: SweeepColors.trash,
        surface: SweeepColors.card,
        onSurface: SweeepColors.text,
      ),
    );
    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: SweeepPageTransitions(),
        TargetPlatform.iOS: SweeepPageTransitions(),
      }),
      textTheme: base.textTheme
          .apply(fontFamily: 'PlusJakartaSans', bodyColor: SweeepColors.text, displayColor: SweeepColors.text),
    );
  }
}

/// Swipe-word stretching: "SW" + n x "I" + "PE", n grows with the gesture.
/// n = 1 + floor(|dx| / 14), capped at 10.
int swipeWordIs(double dx) => 1 + (dx.abs() / 14).floor().clamp(0, 9).toInt();

String swipeWord(double dx) => 'SW${'I' * swipeWordIs(dx)}PE';

/// Every push looks the same: the new page fades in while rising a few pixels,
/// the page underneath dims slightly. Calm, no big movements.
class SweeepPageTransitions extends PageTransitionsBuilder {
  const SweeepPageTransitions();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final under = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: .6).animate(under),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .03), end: Offset.zero).animate(enter), child: child),
      ),
    );
  }
}
