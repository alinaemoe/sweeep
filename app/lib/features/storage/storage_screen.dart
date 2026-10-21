import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/list_chrome.dart';
import '../../core/widgets.dart';
import '../../core/theme.dart';
import '../../index/review_service.dart';
import '../../index/group_service.dart';
import '../../index/storage_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../category/category_screen.dart';
import '../groups/group_widgets.dart';
import '../goal/goal_screen.dart';
import '../groups/groups_screen.dart';
import '../swipe/swipe_screen.dart';
import 'storage_labels.dart';
import 'treemap.dart';

/// Storage map (D11): one big "you can safely free" number, a treemap of the
/// library you can re-cut by months, types or sources, and Quick wins below.
class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  StorageCut _cut = StorageCut.months;
  int _sel = 0;

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    ref.invalidate(storageProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(trashSummaryProvider);
  }

  /// Where "Review this block" goes for the selected block.
  Widget _reviewFor(StorageCut cut, StorageTile t) {
    switch (cut) {
      case StorageCut.months:
        return SwipeScreen(source: SwipeSource.all, month: t.key == 'earlier' ? null : t.key);
      case StorageCut.types:
        return switch (t.key) {
          'videos' => const CategoryScreen(kind: CategoryKind.videos),
          'chat' => const CategoryScreen(kind: CategoryKind.chat),
          'screenshots' => const CategoryScreen(kind: CategoryKind.screenshots),
          'recordings' => const CategoryScreen(kind: CategoryKind.screenRecordings),
          _ => const SwipeScreen(source: SwipeSource.all),
        };
      case StorageCut.sources:
        return switch (t.key) {
          'screenshots' => const CategoryScreen(kind: CategoryKind.screenshots),
          'camera' || 'downloads' || 'instagram' || 'other' => const SwipeScreen(source: SwipeSource.all),
          _ => CategoryScreen(kind: CategoryKind.chat, initialSource: t.key),
        };
    }
  }

  void _clean(QuickWin w) {
    HapticFeedback.selectionClick();
    _open(w == QuickWin.duplicates ? const GroupsScreen(kind: GroupKind.duplicate) : CategoryScreen(kind: CategoryKind.quickWin, win: w));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storageProvider);
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SweeepColors.brand)),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: SweeepColors.textMutedSmall))),
          data: _body,
        ),
      ),
    );
  }

  Widget _body(StorageData d) {
    final tiles = [...d.cuts[_cut]!]..sort((a, b) => b.bytes.compareTo(a.bytes));
    final sel = tiles.isEmpty ? null : tiles[math.min(_sel, tiles.length - 1)];
    final shownMonths = d.cuts[StorageCut.months]!;
    final earlierSub = shownMonths.length > 1 && shownMonths.last.key == 'earlier' ? _earlierBefore(shownMonths) : '';
    final wins = d.wins.where((w) => w.count > 0).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        ListBar(trailing: Padding(padding: const EdgeInsets.only(right: 6), child: Text(l10n.storUpdated, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _FreeNumber(bytes: d.safeBytes, total: d.totalBytes),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            for (final c in StorageCut.values) ...[
              _CutChip(
                label: switch (c) { StorageCut.months => l10n.storCutMonths, StorageCut.types => l10n.storCutTypes, StorageCut.sources => l10n.storCutSources },
                on: c == _cut,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _cut = c;
                    _sel = 0;
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: SizedBox(
            height: 320,
            child: LayoutBuilder(
              builder: (_, c) => Treemap(
                width: c.maxWidth,
                height: 320,
                tiles: [for (final t in tiles) TreemapTile(label: tileLabel(_cut, t.key), shortLabel: tileShortLabel(_cut, t.key), bytes: t.bytes, share: t.share)],
                selected: _sel,
                onPick: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _sel = i);
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            Container(width: 18, height: 4, decoration: BoxDecoration(color: SweeepColors.trash, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(l10n.storLegend, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
          ]),
        ),
        if (sel != null)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: SweeepColors.cardBorder)),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tileLabel(_cut, sel.key), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.4)),
                    const SizedBox(height: 2),
                    Text(tileSub(_cut, sel, olderThan: earlierSub), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
                  ]),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatBytes(sel.bytes), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.6)),
                  Text(l10n.storClear(formatBytes(sel.reclaim)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: SweeepColors.trash)),
                ]),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 48, child: PillButton(height: 48, label: l10n.storReview, onPressed: () => _open(_reviewFor(_cut, sel)))),
            ]),
          ),
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: GoalEntryCard(onTap: () => _open(const GoalScreen()))),
        if (wins.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.storQuickTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.6)),
                  const SizedBox(height: 2),
                  Text(l10n.storQuickSub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
                ]),
              ),
              Text(l10n.storQuickTotal(formatBytes(d.winsBytes)), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
            ]),
          ),
          SizedBox(
            height: 212,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              itemCount: wins.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _WinCard(stat: wins[i], index: i, onClean: () => _clean(wins[i].win)),
            ),
          ),
        ],
      ],
    );
  }

  String _earlierBefore(List<StorageTile> months) {
    final newest = months.where((m) => m.key != 'earlier').map((m) => m.key).toList()..sort();
    if (newest.isEmpty) return '';
    final k = newest.first;
    return fmtMonthShort(int.parse(k.substring(0, 4)), int.parse(k.substring(5)));
  }
}

/// "YOU CAN SAFELY FREE", the number counting up from zero.
class _FreeNumber extends StatelessWidget {
  const _FreeNumber({required this.bytes, required this.total});
  final int bytes;
  final int total;

  @override
  Widget build(BuildContext context) {
    final units = l10n.byteUnits.split(',');
    var i = 0;
    var v = bytes.toDouble();
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    final unit = units[math.max(i, 2)];
    final target = i < 2 ? bytes / (1024 * 1024) : v;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.storSafeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: SweeepColors.textMutedSmall)),
      const SizedBox(height: 4),
      TweenAnimationBuilder<double>(
        key: ValueKey(bytes),
        tween: Tween(begin: 0, end: target),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeOutCubic,
        builder: (_, x, __) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtNum(x, digits: target >= 100 ? 0 : 1), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, letterSpacing: -3, height: .95)),
          const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(unit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SweeepColors.brand))),
        ]),
      ),
      const SizedBox(height: 6),
      Text(l10n.storOfTotal(formatBytes(total)), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
    ]);
  }
}

class _CutChip extends StatelessWidget {
  const _CutChip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? SweeepColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: on ? SweeepColors.brand : Colors.white.withValues(alpha: .12)),
                ),
                child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? SweeepColors.onAccent : SweeepColors.text)),
              ),
            ),
          ),
        ),
      );
}

IconData _winIcon(QuickWin w) => switch (w) {
      QuickWin.oldScreenshots => Icons.smartphone_rounded,
      QuickWin.blurry => Icons.blur_on_rounded,
      QuickWin.chatLeftovers => Icons.chat_bubble_outline_rounded,
      QuickWin.longRecordings => Icons.videocam_outlined,
      QuickWin.duplicates => Icons.content_copy_rounded,
    };

class _WinCard extends StatelessWidget {
  const _WinCard({required this.stat, required this.index, required this.onClean});
  final QuickWinStat stat;
  final int index;
  final VoidCallback onClean;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 600 + 100 * index),
        curve: Interval(index * 100 / (600 + 100 * index), 1, curve: const Cubic(.2, .8, .2, 1)),
        builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(40 * (1 - t), 0), child: child)),
        child: Container(
          width: 236,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: SweeepColors.cardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: SweeepColors.brand.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                child: Icon(_winIcon(stat.win), size: 22, color: SweeepColors.brand),
              ),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: SweeepColors.brand.withValues(alpha: .5))),
                child: Text(l10n.storSafe, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8, color: SweeepColors.brand)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(quickWinTitle(stat.win), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.3)),
            const SizedBox(height: 3),
            SizedBox(
              height: 32,
              child: Text(quickWinSub(stat.win), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall, height: 1.3)),
            ),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(formatBytes(stat.bytes), maxLines: 1, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1)),
                  ),
                  const SizedBox(height: 2),
                  Text(filesLabel(stat.count), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
                ]),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: '${l10n.storClean}: ${quickWinTitle(stat.win)}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClean,
                  child: Container(
                    height: 44,
                    constraints: const BoxConstraints(minWidth: 72),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: SweeepColors.trash, borderRadius: BorderRadius.circular(22)),
                    child: Text(l10n.storClean, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SweeepColors.onAccent)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      );
}
