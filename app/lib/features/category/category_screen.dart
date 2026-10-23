import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/list_chrome.dart';
import '../../core/mode_switch.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../index/review_service.dart';
import '../../providers.dart';
import '../../index/storage_service.dart';
import '../groups/group_widgets.dart';
import '../storage/storage_labels.dart';
import '../swipe/swipe_screen.dart';

String categoryTitle(CategoryKind k) => switch (k) {
      CategoryKind.videos => l10n.secVideos,
      CategoryKind.screenRecordings => l10n.secScreenRecordings,
      CategoryKind.screenshots => l10n.secScreenshots,
      CategoryKind.chat => l10n.secChat,
      CategoryKind.quickWin => '',
    };

String _sourceName(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Grid of one category (videos, screenshots, chat media). Tap to select,
/// then move the selection to the app trash. Nothing leaves the device here.
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.kind, this.initialSource, this.win, this.preset});
  final CategoryKind kind;

  /// Quick win lists only: which rule picked these files.
  final QuickWin? win;

  /// A list somebody else picked (Free by goal): every file starts selected,
  /// the title says to check it, and there is no Swipe twin.
  final List<CategoryItem>? preset;

  /// Chat only: start with this app selected.
  final String? initialSource;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<CategoryItem>? _items;
  List<String> _sources = const [];
  late String? _source = widget.initialSource; // chat filter, null = all
  late bool _bySize = widget.kind == CategoryKind.videos || widget.kind == CategoryKind.screenRecordings || widget.kind == CategoryKind.quickWin;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) _selected.addAll(widget.preset!.map((e) => e.id));
    _load();
    if (widget.kind == CategoryKind.chat) {
      ref.read(reviewServiceProvider).chatSources().then((s) {
        if (mounted) setState(() => _sources = s);
      });
    }
  }

  Future<void> _load() async {
    if (widget.preset != null) {
      final items = await ref.read(reviewServiceProvider).itemsByIds([for (final e in widget.preset!) e.id]);
      if (!_bySize) items.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      if (mounted) setState(() => _items = items);
      return;
    }
    final items = await ref.read(reviewServiceProvider).category(widget.kind, chatSource: _source, bySize: _bySize, win: widget.win);
    if (mounted) setState(() => _items = items);
  }

  void _refreshOutside() {
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(groupsProvider);
  }

  Future<void> _trash() async {
    final items = _items!.where((i) => _selected.contains(i.id)).toList();
    if (items.isEmpty) return;
    final svc = ref.read(reviewServiceProvider);
    HapticFeedback.lightImpact();
    await svc.trashMany(items);
    _selected.clear();
    _refreshOutside();
    await _load();
    if (!mounted) return;
    final ids = items.map((i) => i.id).toList();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        persist: false,
        duration: const Duration(seconds: 4),
        content: Text(l10n.movedToTrash(filesLabel(items.length))),
        action: SnackBarAction(
          label: l10n.undo,
          textColor: SweeepColors.brand,
          onPressed: () async {
            await svc.restore(ids);
            _refreshOutside();
            await _load();
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final total = items?.fold<int>(0, (s, e) => s + e.sizeBytes) ?? 0;
    final selBytes = items?.where((e) => _selected.contains(e.id)).fold<int>(0, (s, e) => s + e.sizeBytes) ?? 0;
    final allSelected = items != null && items.isNotEmpty && _selected.length == items.length;

    return PopScope(
      onPopInvokedWithResult: (_, __) => _refreshOutside(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ListBar(
                trailing: widget.preset != null ? null : ModeSwitch<int>(
                  value: 0,
                  options: [
                    ModeOption(value: 0, label: l10n.modeGrid, icon: gridModeIcon),
                    ModeOption(value: 1, label: l10n.modeSwipe, icon: swipeModeIcon),
                  ],
                  onChanged: (_) => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                    builder: (_) => SwipeScreen(source: swipeSourceOf(widget.kind), chatSource: _source, win: widget.win),
                  )),
                ),
              ),
              ListTitle(title: widget.preset != null ? l10n.goalReviewTitle : (widget.win != null ? quickWinTitle(widget.win!) : categoryTitle(widget.kind)), subtitle: items == null ? '' : '${filesLabel(items.length)} · ${formatBytes(total)}'),
              ListToolbar(
                chips: [
                  SweeepChip(l10n.sortNewest, !_bySize, () => _sort(false)),
                  SweeepChip(l10n.sortLargest, _bySize, () => _sort(true)),
                  if (widget.kind == CategoryKind.chat && _sources.length > 1) ...[
                    SweeepChip(l10n.allApps, _source == null, () => _filter(null)),
                    for (final s in _sources) SweeepChip(_sourceName(s), _source == s, () => _filter(s)),
                  ],
                ],
                actionLabel: allSelected ? l10n.clear : l10n.selectAll,
                onAction: items == null || items.isEmpty ? null : () => setState(() => allSelected ? _selected.clear() : _selected.addAll(items.map((e) => e.id))),
              ),
              Expanded(
                child: items == null
                    ? const Center(child: CircularProgressIndicator(color: SweeepColors.brand))
                    : items.isEmpty
                        ? Center(child: Text(l10n.nothingHere, style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 16)))
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(20, 6, 20, _selected.isEmpty ? 24 : 130),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final e = items[i];
                              final on = _selected.contains(e.id);
                              return Pressable(
                                onTap: () => setState(() => on ? _selected.remove(e.id) : _selected.add(e.id)),
                                child: _Cell(item: e, selected: on),
                              );
                            },
                          ),
              ),
            ]),
            if (_selected.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: SweeepColors.card.withValues(alpha: .96), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .08))),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(l10n.catSelected(_selected.length, formatBytes(selBytes)),
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _trash,
                        style: FilledButton.styleFrom(backgroundColor: SweeepColors.trash, foregroundColor: SweeepColors.onAccent, shape: const StadiumBorder()),
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.moveNToTrash(_selected.length), maxLines: 1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  void _sort(bool bySize) {
    if (bySize == _bySize) return;
    setState(() => _bySize = bySize);
    _load();
  }

  void _filter(String? source) {
    if (source == _source) return;
    setState(() {
      _source = source;
      _selected.clear();
    });
    _load();
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.item, required this.selected});
  final CategoryItem item;
  final bool selected;

  String _len(int ms) {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Widget badge(String t, {bool left = true}) => Positioned(
          left: left ? 6 : null,
          right: left ? null : 6,
          bottom: 6,
          child: GlassPill(height: 20, padding: const EdgeInsets.symmetric(horizontal: 7), child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
        );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? SweeepColors.brand : Colors.transparent, width: 2)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          ThumbImage(id: item.id, side: 256),
          if (item.isVideo) ...[
            if (item.durationMs != null) badge(_len(item.durationMs!)),
            badge(formatBytes(item.sizeBytes), left: false),
          ] else
            badge(formatBytes(item.sizeBytes), left: false),
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? SweeepColors.brand : Colors.black.withValues(alpha: .25),
                border: selected ? null : Border.all(color: Colors.white.withValues(alpha: .5), width: 2),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 14, color: SweeepColors.onAccent) : null,
            ),
          ),
        ]),
      ),
    );
  }
}
