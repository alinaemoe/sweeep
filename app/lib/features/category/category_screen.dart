import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../index/review_service.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart';
import '../swipe/swipe_screen.dart';

String categoryTitle(CategoryKind k) => switch (k) {
      CategoryKind.videos => 'Videos',
      CategoryKind.screenshots => 'Screenshots',
      CategoryKind.chat => 'Chat media',
    };

String _sourceName(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Grid of one category (videos, screenshots, chat media). Tap to select,
/// then move the selection to the app trash. Nothing leaves the device here.
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.kind});
  final CategoryKind kind;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<CategoryItem>? _items;
  List<String> _sources = const [];
  String? _source; // chat filter, null = all
  late bool _bySize = widget.kind == CategoryKind.videos;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.kind == CategoryKind.chat) {
      ref.read(reviewServiceProvider).chatSources().then((s) {
        if (mounted) setState(() => _sources = s);
      });
    }
  }

  Future<void> _load() async {
    final items = await ref.read(reviewServiceProvider).category(widget.kind, chatSource: _source, bySize: _bySize);
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
    await svc.trashMany(items);
    _selected.clear();
    _refreshOutside();
    await _load();
    if (!mounted) return;
    final ids = items.map((i) => i.id).toList();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${items.length} moved to trash'),
        action: SnackBarAction(
          label: 'Undo',
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.chevron_left_rounded),
                    style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
                  ),
                  const Spacer(),
                  if (widget.kind == CategoryKind.screenshots)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SwipeScreen(source: SwipeSource.screenshots))).then((_) => _load()),
                      style: TextButton.styleFrom(foregroundColor: SweeepColors.brand, minimumSize: const Size(48, 44)),
                      child: const Text('Swipe', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  TextButton(
                    onPressed: items == null || items.isEmpty ? null : () => setState(() => allSelected ? _selected.clear() : _selected.addAll(items.map((e) => e.id))),
                    style: TextButton.styleFrom(foregroundColor: SweeepColors.brand, minimumSize: const Size(48, 44)),
                    child: Text(allSelected ? 'Clear' : 'Select all', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(categoryTitle(widget.kind), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(items == null ? '' : '${items.length} files · ${formatBytes(total)}', style: const TextStyle(fontSize: 14, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  children: [
                    _Chip('Newest', !_bySize, () => _sort(false)),
                    const SizedBox(width: 8),
                    _Chip('Largest', _bySize, () => _sort(true)),
                    if (widget.kind == CategoryKind.chat && _sources.length > 1) ...[
                      const SizedBox(width: 16),
                      _Chip('All apps', _source == null, () => _filter(null)),
                      for (final s in _sources) ...[const SizedBox(width: 8), _Chip(_sourceName(s), _source == s, () => _filter(s))],
                    ],
                  ],
                ),
              ),
              Expanded(
                child: items == null
                    ? const Center(child: CircularProgressIndicator(color: SweeepColors.brand))
                    : items.isEmpty
                        ? const Center(child: Text('Nothing here.', style: TextStyle(color: SweeepColors.textMutedSmall, fontSize: 16)))
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
                    Text('${_selected.length} selected · ${formatBytes(selBytes)} · recoverable from the trash',
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _trash,
                        style: FilledButton.styleFrom(backgroundColor: SweeepColors.trash, foregroundColor: SweeepColors.onAccent, shape: const StadiumBorder()),
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text('Move ${_selected.length} to trash', maxLines: 1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
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

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? SweeepColors.brand.withValues(alpha: .16) : SweeepColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? SweeepColors.brand : SweeepColors.cardBorder),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? SweeepColors.brand : SweeepColors.textMutedSmall)),
        ),
      );
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
