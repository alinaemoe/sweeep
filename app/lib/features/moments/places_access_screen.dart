import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../../platform/places.dart';
import '../../providers.dart';

const _muted = Color(0xFF8A8F9E);
const _soft = Color(0xFFA9AEBB);

/// Before Android asks for the photo location: what is read, what is not, and how to
/// turn it off, in the style of the Usage access screen. Pops with true when places are on.
class PlacesAccessScreen extends ConsumerStatefulWidget {
  const PlacesAccessScreen({super.key});

  @override
  ConsumerState<PlacesAccessScreen> createState() => _PlacesAccessScreenState();
}

class _PlacesAccessScreenState extends ConsumerState<PlacesAccessScreen> with TickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  bool _busy = false;

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await Places.request();
    await ref.read(momentsServiceProvider).setPlaces(ok);
    if (mounted) Navigator.of(context).pop(ok);
  }

  Future<void> _skip() async {
    await ref.read(momentsServiceProvider).setPlaces(false);
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Stack(children: [
        GlowOrb(left: w / 2 - 150, top: 70, width: 300, height: 300, color: SweeepColors.brand.withValues(alpha: .18), blur: 80),
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
                                child: Transform.scale(scale: .8 + .7 * t, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SweeepColors.brand.withValues(alpha: .6), width: 2)))),
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: SweeepColors.card, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .1))),
                              child: const Icon(Icons.place_outlined, size: 46, color: SweeepColors.brand),
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
                    Text(l10n.placesTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.1)),
                    const SizedBox(height: 10),
                    Text(l10n.placesSub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _soft, height: 1.45)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                Rise(delay: const Duration(milliseconds: 100), dy: 16, child: _Card(label: l10n.usageReadLabel, color: SweeepColors.keep, text: l10n.placesReadText)),
                const SizedBox(height: 10),
                Rise(delay: const Duration(milliseconds: 200), dy: 16, child: _Card(label: l10n.usageNeverLabel, color: SweeepColors.trash, text: l10n.placesNeverText)),
                const SizedBox(height: 10),
                Rise(delay: const Duration(milliseconds: 300), dy: 16, child: _Card(label: l10n.usageCanLabel, color: SweeepColors.brand, text: l10n.placesCanText)),
              ]),
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
              onTap: _skip,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: SweeepColors.card, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .06))),
                child: const Icon(Icons.chevron_left_rounded, size: 22, color: SweeepColors.text),
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
                decoration: BoxDecoration(color: SweeepColors.card.withValues(alpha: .88), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .08))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _allow,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: SweeepColors.brand.withValues(alpha: .28), blurRadius: 24)]),
                      child: Text(l10n.placesAllow, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SweeepColors.onAccent)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _skip,
                    child: SizedBox(height: 36, child: Center(child: Text(l10n.placesSkip, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _muted)))),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.color, required this.text});
  final String label;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: color)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SweeepColors.text, height: 1.4)),
        ]),
      );
}
