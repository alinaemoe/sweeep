import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../index/review_service.dart';
import '../../providers.dart';
import '../home/home_screen.dart';
import '../swipe/swipe_screen.dart';
import '../tools/tools_screen.dart';
import '../trash/trash_screen.dart';

/// The four tabs: Clean (Home), Swipe, Tools, Trash. Home stays alive in the
/// background (scroll position, scan progress); the others are rebuilt on each
/// visit so they always show fresh data.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _tab = 0;

  void _select(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    // whatever was changed on the previous tab must show up everywhere
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(groupsProvider);
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Home stays alive; it fades in/out instead of popping, so returning
        // to it animates just like leaving it.
        Positioned.fill(
          child: TickerMode(
            enabled: _tab == 0,
            child: IgnorePointer(
              ignoring: _tab != 0,
              child: AnimatedOpacity(
                opacity: _tab == 0 ? 1 : 0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                child: const HomeScreen(),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .02), end: Offset.zero).animate(anim), child: child),
            ),
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: switch (_tab) {
                0 => const SizedBox.shrink(),
                1 => const SwipeScreen(source: SwipeSource.all, embedded: true),
                2 => const ToolsScreen(),
                _ => const TrashScreen(embedded: true),
              },
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
          child: SweeepNavBar(index: _tab, onChanged: _select),
        ),
      ]),
    );
  }
}

/// Floating pill bar. The selected item grows into a lavender pill with its
/// label; the change animates width and colour so the pill seems to slide.
class SweeepNavBar extends StatelessWidget {
  const SweeepNavBar({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.auto_awesome_rounded, 'Clean'),
    (Icons.crop_portrait_rounded, 'Swipe'),
    (Icons.volume_up_outlined, 'Tools'),
    (Icons.delete_outline_rounded, 'Trash'),
  ];

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: SweeepColors.card,
            borderRadius: BorderRadius.circular(31),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++) _NavItem(icon: _items[i].$1, label: _items[i].$2, selected: i == index, onTap: () => onChanged(i)),
            ],
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: 46,
            width: selected ? 112 : 52,
            decoration: BoxDecoration(
              color: selected ? SweeepColors.brand.withValues(alpha: .16) : Colors.transparent,
              borderRadius: BorderRadius.circular(23),
            ),
            child: ClipRect(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: selected ? SweeepColors.brand : SweeepColors.textMutedSmall),
                  duration: const Duration(milliseconds: 260),
                  builder: (_, c, __) => Icon(icon, size: 22, color: c),
                ),
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(label, maxLines: 1, softWrap: false, style: const TextStyle(color: SweeepColors.brand, fontSize: 14, fontWeight: FontWeight.w700)),
                          )
                        : const SizedBox(width: 0, height: 0),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}
