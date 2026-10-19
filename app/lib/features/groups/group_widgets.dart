import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../index/group_service.dart';
import '../../providers.dart';

/// "1 file" / "3 files".
String filesLabel(int n) => n == 1 ? '1 file' : '$n files';

String formatBytes(int b) {
  const u = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i < 2 ? 0 : 1)} ${u[i]}';
}

/// Real photo thumbnail (JPEG from the platform layer), cached by Riverpod.
class ThumbImage extends ConsumerWidget {
  const ThumbImage({super.key, required this.id, this.side = 256, this.fit = BoxFit.cover});
  final String id;
  final int side;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(thumbProvider((id: id, side: side)));
    return async.when(
      data: (bytes) => bytes == null
          ? const ColoredBox(color: SweeepColors.trackUsed)
          : Image.memory(
              bytes,
              fit: fit,
              gaplessPlayback: true,
              width: double.infinity,
              height: double.infinity,
              frameBuilder: (context, child, frame, sync) => sync ? child : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 220), curve: Curves.easeOut, child: child),
            ),
      loading: () => const ColoredBox(color: SweeepColors.trackDim),
      error: (_, __) => const ColoredBox(color: SweeepColors.trackUsed),
    );
  }
}

/// Dark translucent pill used over photos. No live blur on purpose: a
/// BackdropFilter per card is what made scrolling drop frames.
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.child, this.height = 32, this.padding = const EdgeInsets.symmetric(horizontal: 12)});
  final Widget child;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SweeepColors.background.withValues(alpha: .66),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: child,
      );
}

class LimePill extends StatelessWidget {
  const LimePill(this.label, {super.key, this.color = SweeepColors.keep});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: const TextStyle(color: SweeepColors.onAccent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
      );
}

/// A group drawn as a stack of frames: the best photo on top, two other
/// members fanned out underneath (-6 deg / +4 deg), with a count badge.
class GroupStack extends StatelessWidget {
  const GroupStack({super.key, required this.group, this.radius = 22, this.thumbSide = 256, this.showBest = false});
  final GroupView group;
  final double radius;
  final int thumbSide;
  final bool showBest;

  @override
  Widget build(BuildContext context) {
    final others = group.others;
    Widget layer(String id, double angle, Offset shift, double opacity) => Transform.translate(
          offset: shift,
          child: Transform.rotate(
            angle: angle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.white.withValues(alpha: .16)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(fit: StackFit.expand, children: [
                  ThumbImage(id: id, side: thumbSide),
                  // cards sit on a solid background, so darkening == fading
                  ColoredBox(color: SweeepColors.background.withValues(alpha: 1 - opacity)),
                ]),
              ),
            ),
          ),
        );

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (others.length > 1) layer(others[1].assetId, -6 * 3.14159 / 180, const Offset(-5, -3), .75),
        if (others.isNotEmpty) layer(others[0].assetId, 4 * 3.14159 / 180, const Offset(5, -2), .9),
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: .12)), borderRadius: BorderRadius.circular(radius)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ThumbImage(id: group.bestId, side: thumbSide),
                if (showBest) const Positioned(left: 10, top: 10, child: LimePill('BEST')),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: GlassPill(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('×${group.members.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('save ${formatBytes(group.savingsBytes)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String kindTitle(GroupKind k) => k == GroupKind.duplicate ? 'Duplicates' : 'Similar photos';

/// Wraps a tappable card with a small press-down scale, so taps feel physical.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.child, this.label});
  final VoidCallback onTap;

  /// Spoken description for screen readers (nothing changes visually).
  final String? label;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? .95 : 1, duration: const Duration(milliseconds: 120), curve: Curves.easeOut, child: widget.child),
      ));
}
