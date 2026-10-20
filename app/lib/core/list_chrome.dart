import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'theme.dart';

/// The shared top of every list screen, so Grid, Months and Swipe feel like one
/// family and controls never jump between them:
///
///   [ListBar]      back on the left, the mode switch on the right
///   title block    big title + one summary line, full width, nothing beside it
///   [ListToolbar]  chips on the left, one text action (Select all) on the right
class ListBar extends StatelessWidget {
  const ListBar({super.key, this.trailing});

  /// Usually a [ModeSwitch]; left empty when the screen has only one view.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 14, 0),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.back,
            icon: const Icon(Icons.chevron_left_rounded),
            style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Title and one muted line under it.
class ListTitle extends StatelessWidget {
  const ListTitle({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// Chips that scroll sideways and fade out before the pinned action, so a long
/// row never runs into it.
class ListToolbar extends StatelessWidget {
  const ListToolbar({super.key, required this.chips, this.actionLabel, this.onAction});
  final List<Widget> chips;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Row(children: [
          Expanded(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(colors: [Colors.white, Colors.white, Colors.transparent], stops: [0, .88, 1]).createShader(r),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => chips[i],
              ),
            ),
          ),
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 4),
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: SweeepColors.brand, minimumSize: const Size(48, 44), padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: Text(actionLabel!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      );
}

/// The one chip style for sort and filter rows.
class SweeepChip extends StatelessWidget {
  const SweeepChip(this.label, this.selected, this.onTap, {super.key, this.semantics});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: semantics ?? label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? SweeepColors.brand.withValues(alpha: .16) : SweeepColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? SweeepColors.brand : SweeepColors.cardBorder),
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? SweeepColors.brand : SweeepColors.textMutedSmall)),
          ),
        ),
      );
}
