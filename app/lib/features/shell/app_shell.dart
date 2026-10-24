import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mode_switch.dart';
import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../index/widget_sync.dart';
import '../../platform/widgets.dart';
import '../../providers.dart';
import '../swipe/swipe_screen.dart';
import '../session/reminder_sheet.dart';
import '../home/home_screen.dart';
import '../swipe/timeline_screen.dart';
import '../space/space_screen.dart';
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

  @override
  void initState() {
    super.initState();
    // put the daily reminder back (new language, new boot, new alarm)
    applyReminder(ref.read(sessionServiceProvider));
    // keep the weekly report's per-day totals and the phone storage reading current
    ref.read(weekSummaryProvider.future).ignore();
    // home screen widgets: fresh numbers now, and the tap that opened the app
    WidgetSync(ref.read(databaseProvider)).refresh().catchError((_) {});
    // events and their places, a little later so the first screens stay quick
    Future<void>.delayed(const Duration(seconds: 25), () => ref.read(momentsServiceProvider).refresh().catchError((_) {}));
    HomeWidgets.onAction(_widgetAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _widgetAction());
  }

  /// A widget was tapped: open the Space tab or start a Cleanup session.
  Future<void> _widgetAction() async {
    final action = await HomeWidgets.takeAction();
    if (action == null || action == 'open' || !mounted) return;
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    if (action == 'space') {
      ref.read(shellTabProvider.notifier).set(2);
      return;
    }
    if (!action.startsWith('session:')) return;
    final goal = int.tryParse(action.substring(8)) ?? 25;
    final svc = ref.read(sessionServiceProvider);
    final o = await ref.read(sessionOverviewProvider.future);
    final plan = await svc.plan(goal);
    if (!mounted) return;
    if (plan.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sessNothing)));
      return;
    }
    await nav.push(MaterialPageRoute<void>(builder: (_) => SwipeScreen.session(plan: plan, goal: goal, before: o.streak, targetPercent: o.target?.percent ?? 100)));
    ref.invalidate(sessionOverviewProvider);
  }

  void _select(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    // whatever was changed on the previous tab must show up everywhere
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(groupsProvider);
    ref.invalidate(timelineProvider);
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    // the tab can also change from elsewhere (the Home oval opens Space)
    ref.listen(shellTabProvider, (_, i) => _select(i));
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
                1 => const TimelineScreen(),
                2 => const SpaceScreen(),
                _ => const TrashScreen(embedded: true),
              },
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: SweeepNavBar(index: _tab, onChanged: (i) => ref.read(shellTabProvider.notifier).set(i)),
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

  static List<(Widget Function(Color), String)> get _items => [
        ((c) => Icon(Icons.auto_awesome_rounded, size: 22, color: c), l10n.navClean),
        ((c) => SwipeStackIcon(color: c), l10n.navSwipe),
        ((c) => SpaceIcon(color: c), l10n.navSpace),
        ((c) => Icon(Icons.delete_outline_rounded, size: 22, color: c), l10n.navTrash),
      ];

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: SweeepColors.card.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(31),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++) _NavItem(icon: _items[i].$1, label: _items[i].$2, selected: i == index, onTap: () => onChanged(i)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final Widget Function(Color) icon;
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
                  tween: ColorTween(end: selected ? SweeepColors.brand : const Color(0xFFA9AEBB)),
                  duration: const Duration(milliseconds: 260),
                  builder: (_, c, __) => icon(c ?? const Color(0xFFA9AEBB)),
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
