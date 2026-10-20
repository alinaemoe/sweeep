import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../groups/group_widgets.dart';

/// One block to draw: its name, its size and the share of it you can clear.
class TreemapTile {
  const TreemapTile({required this.label, required this.bytes, required this.share, String? shortLabel}) : shortLabel = shortLabel ?? label;
  final String label;

  /// Used when the block is too narrow for [label].
  final String shortLabel;
  final int bytes;
  final double share;
}

/// Squarified layout of [sizes] (biggest first) inside [width] x [height].
List<Rect> squarify(List<num> sizes, double width, double height) {
  final total = sizes.fold<double>(0, (s, v) => s + v);
  if (total <= 0 || sizes.isEmpty) return const [];
  final nodes = [for (var i = 0; i < sizes.length; i++) (i: i, a: sizes[i] / total * width * height)];
  final out = List<Rect>.filled(sizes.length, Rect.zero);
  var x = 0.0, y = 0.0, w = width, h = height;
  var rest = nodes;

  double worst(List<({int i, double a})> row, double s) {
    final sum = row.fold<double>(0, (a, n) => a + n.a);
    var mx = 0.0, mn = double.infinity;
    for (final n in row) {
      if (n.a > mx) mx = n.a;
      if (n.a < mn) mn = n.a;
    }
    return [s * s * mx / (sum * sum), sum * sum / (s * s * mn)].reduce((a, b) => a > b ? a : b);
  }

  while (rest.isNotEmpty) {
    final s = w < h ? w : h;
    final row = [rest.first];
    var k = 1;
    while (k < rest.length && worst([...row, rest[k]], s) <= worst(row, s)) {
      row.add(rest[k]);
      k++;
    }
    rest = rest.sublist(row.length);
    final sum = row.fold<double>(0, (a, n) => a + n.a);
    if (w >= h) {
      final cw = sum / h;
      var cy = y;
      for (final n in row) {
        final ch = n.a / cw;
        out[n.i] = Rect.fromLTWH(x, cy, cw, ch);
        cy += ch;
      }
      x += cw;
      w -= cw;
    } else {
      final rh = sum / w;
      var cx = x;
      for (final n in row) {
        final cw = n.a / rh;
        out[n.i] = Rect.fromLTWH(cx, y, cw, rh);
        cx += cw;
      }
      y += rh;
      h -= rh;
    }
  }
  return out;
}

/// The storage map. Eight fixed slots, so when the cut changes every block
/// glides to its new place instead of being redrawn.
class Treemap extends StatelessWidget {
  const Treemap({super.key, required this.width, required this.height, required this.tiles, required this.selected, required this.onPick});
  final double width;
  final double height;
  final List<TreemapTile> tiles;
  final int selected;
  final ValueChanged<int> onPick;

  static const slots = 8;
  static const _ease = Cubic(.2, .8, .2, 1);

  @override
  Widget build(BuildContext context) {
    final shown = tiles.take(slots).toList();
    // every block stays big enough to read and tap, even next to a huge one
    final sum = shown.fold<int>(0, (a, t) => a + t.bytes);
    final floor = sum * .07;
    final rects = squarify([for (final t in shown) t.bytes < floor ? floor : t.bytes.toDouble()], width, height);
    return Stack(children: [
      for (var i = 0; i < slots; i++)
        AnimatedPositioned(
          key: ValueKey(i),
          duration: const Duration(milliseconds: 600),
          curve: _ease,
          left: i < rects.length ? rects[i].left : width / 2,
          top: i < rects.length ? rects[i].top : height / 2,
          width: i < rects.length ? rects[i].width : 0,
          height: i < rects.length ? rects[i].height : 0,
          child: i < shown.length ? _Block(rank: i, tile: shown[i], area: rects[i].width * rects[i].height, width: rects[i].width, selected: i == selected, onTap: () => onPick(i)) : const SizedBox.shrink(),
        ),
    ]);
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.rank, required this.tile, required this.area, required this.width, required this.selected, required this.onTap});
  final double width;
  final int rank;
  final TreemapTile tile;
  final double area;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final big = rank == 0;
    final bg = big ? SweeepColors.brand : SweeepColors.brand.withValues(alpha: rank < 3 ? .34 : .15);
    final fg = big ? SweeepColors.onAccent : SweeepColors.text;
    final narrow = width < 112;
    final sizeFs = area > 14000 ? 26.0 : (area > 6000 ? 18.0 : 14.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .7, end: 1),
      duration: Duration(milliseconds: 550 + rank * 60),
      curve: Interval(rank * 60 / (550 + rank * 60), 1, curve: const Cubic(.2, .8, .2, 1)),
      builder: (_, s, child) => Opacity(opacity: ((s - .7) / .3).clamp(0, 1), child: Transform.scale(scale: s, child: child)),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${tile.label}, ${formatBytes(tile.bytes)}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? SweeepColors.text : Colors.white.withValues(alpha: .08), width: selected ? 2 : 1),
              ),
              child: LayoutBuilder(builder: (_, c) {
                final label = Text(narrow ? tile.shortLabel : tile.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .2, color: fg));
                final size = FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatBytes(tile.bytes), maxLines: 1, style: TextStyle(fontSize: sizeFs, fontWeight: FontWeight.w800, letterSpacing: -.5, height: 1, color: fg)),
                );
                // a low, wide block has no room for three lines: name and size side by side
                if (c.maxHeight < 56) {
                  return Row(children: [Expanded(child: label), const SizedBox(width: 8), Text(formatBytes(tile.bytes), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg))]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  label,
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    size,
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .28), borderRadius: BorderRadius.circular(2)),
                      child: FractionallySizedBox(
                        widthFactor: tile.share.clamp(0, 1),
                        child: Container(decoration: BoxDecoration(color: SweeepColors.trash, borderRadius: BorderRadius.circular(2))),
                      ),
                    ),
                  ]),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }
}
