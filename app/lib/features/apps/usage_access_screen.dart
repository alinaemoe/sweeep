import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../../platform/apps.dart';
import 'apps_icons.dart';
import 'apps_screen.dart';

const _muted = Color(0xFF8A8F9E);
const _soft = Color(0xFFA9AEBB);

/// Usage access (D26): an honest explanation before the Android special-access
/// screen. The real system switch is opened by the button; coming back with the
/// access granted flips the lock to a check.
class UsageAccessScreen extends StatefulWidget {
  const UsageAccessScreen({super.key});

  @override
  State<UsageAccessScreen> createState() => _UsageAccessScreenState();
}

class _UsageAccessScreenState extends State<UsageAccessScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ring.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final g = await AppsPlatform.usageGranted();
    if (!mounted || g == _granted) return;
    setState(() => _granted = g);
    if (g) _pop.forward(from: 0);
  }

  void _see({required bool usage}) => Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => AppsScreen(usage: usage)));

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final tint = _granted ? SweeepColors.keep : SweeepColors.brand;
    return Scaffold(
      body: Stack(children: [
        // glow: 300 circle, centred, top 70, blur 80
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: tint.withValues(alpha: _granted ? .14 : .18)),
          duration: const Duration(milliseconds: 600),
          builder: (_, c, __) => GlowOrb(
              left: w / 2 - 150,
              top: 70,
              width: 300,
              height: 300,
              color: c!,
              blur: 80),
        ),
        // everything under the back button scrolls, so a short phone can still reach the third card
        ListView(
          padding: const EdgeInsets.only(bottom: 160),
          physics: const ClampingScrollPhysics(),
          children: [
            SizedBox(
              height: 394,
              child: Stack(children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 112,
                  child: Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(clipBehavior: Clip.none, children: [
                        AnimatedBuilder(
                          animation: _ring,
                          builder: (_, __) {
                            final t = Curves.easeOut.transform(_ring.value);
                            return Positioned.fill(
                              child: Opacity(
                                opacity: .7 * (1 - t),
                                child: Transform.scale(
                                  scale: .8 + .7 * t,
                                  child: Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: tint.withValues(alpha: .6),
                                              width: 2))),
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: SweeepColors.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: .1))),
                              child: _granted
                                  ? AnimatedBuilder(
                                      animation: _pop,
                                      builder: (_, __) {
                                        final t = _pop.value;
                                        final s = t < .6
                                            ? .4 +
                                                .75 *
                                                    Curves.easeOut
                                                        .transform(t / .6)
                                            : 1.15 -
                                                .15 *
                                                    Curves.easeOut.transform(
                                                        (t - .6) / .4);
                                        final o = t < .6
                                            ? Curves.easeOut.transform(t / .6)
                                            : 1.0;
                                        return Opacity(
                                            opacity: o,
                                            child: Transform.scale(
                                                scale: s,
                                                child: CheckIcon(
                                                    size: 46,
                                                    color: tint,
                                                    stroke: 2.4)));
                                      },
                                    )
                                  : LockIcon(color: tint),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  right: 30,
                  top: 262,
                  child: Column(children: [
                    Text(_granted ? l10n.usageDoneTitle : l10n.usageTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.1)),
                    const SizedBox(height: 10),
                    Text(_granted ? l10n.usageDoneSub : l10n.usageSub,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _soft,
                            height: 1.45)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedOpacity(
                opacity: _granted ? 0 : 1,
                duration: const Duration(milliseconds: 400),
                child: Column(children: [
                  Rise(
                      delay: const Duration(milliseconds: 100),
                      dy: 16,
                      child: _InfoCard(
                          label: l10n.usageReadLabel,
                          color: SweeepColors.keep,
                          text: l10n.usageReadText)),
                  const SizedBox(height: 10),
                  Rise(
                      delay: const Duration(milliseconds: 200),
                      dy: 16,
                      child: _InfoCard(
                          label: l10n.usageNeverLabel,
                          color: SweeepColors.trash,
                          text: l10n.usageNeverText)),
                  const SizedBox(height: 10),
                  Rise(
                      delay: const Duration(milliseconds: 300),
                      dy: 16,
                      child: _InfoCard(
                          label: l10n.usageCanLabel,
                          color: SweeepColors.brand,
                          text: l10n.usageCanText)),
                ]),
              ),
            ),
          ],
        ),
        Positioned(
          left: 20,
          top: 52,
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
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .06))),
                child: const Icon(Icons.chevron_left_rounded,
                    size: 22, color: SweeepColors.text),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 22,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: SweeepColors.card.withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .08))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _Primary(
                      label: _granted ? l10n.usageSee : l10n.usageOpen,
                      onTap: _granted
                          ? () => _see(usage: true)
                          : AppsPlatform.openUsageSettings),
                  if (!_granted) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _see(usage: false),
                      child: SizedBox(
                          height: 36,
                          child: Center(
                              child: Text(l10n.usageSkip,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _muted)))),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.label, required this.color, required this.text});
  final String label;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
            color: SweeepColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: color)),
          const SizedBox(height: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SweeepColors.text,
                  height: 1.4)),
        ]),
      );
}

class _Primary extends StatelessWidget {
  const _Primary({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: SweeepColors.brand,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                    color: SweeepColors.brand.withValues(alpha: .28),
                    blurRadius: 24)
              ]),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SweeepColors.onAccent)),
        ),
      );
}
