import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/group_service.dart';
import '../../providers.dart';
import 'group_widgets.dart';
import 'groups_screen.dart';

/// Group review: swipe sideways through groups of one category, keep the
/// best photo, tap copies to flip TRASH / KEEP, then trash the rest.
/// Trashing is soft (app trash); nothing leaves the device yet.
class GroupPager extends ConsumerStatefulWidget {
  const GroupPager({super.key, required this.kind, this.initialIndex = 0, this.initialGroupId});
  final GroupKind kind;
  final int initialIndex;

  /// Opens on this group (wins over [initialIndex]); used by the sorted grid.
  final int? initialGroupId;

  @override
  ConsumerState<GroupPager> createState() => _GroupPagerState();
}

class _GroupPagerState extends ConsumerState<GroupPager> {
  List<GroupView>? _groups; // snapshot, so trashing doesn't reshuffle the pages
  // neighbouring cards peek in from both sides
  late PageController _controller = PageController(initialPage: widget.initialIndex, viewportFraction: .9);
  final Map<int, Set<String>> _flipped = {}; // group id -> copies the user flipped from their default
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    ref.read(groupServiceProvider).groups(widget.kind).then((g) {
      if (!mounted) return;
      final at = widget.initialGroupId == null ? -1 : g.indexWhere((x) => x.id == widget.initialGroupId);
      if (at > 0) {
        _controller.dispose();
        _controller = PageController(initialPage: at, viewportFraction: .9);
        _page = at;
      }
      setState(() => _groups = g);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Exact duplicates default to TRASH (identical files). Similar photos
  /// default to KEEP: lookalikes are a judgment call, so the user opts in.
  bool _defaultTrash(GroupView g) => g.kind == GroupKind.duplicate;

  bool _isKept(GroupView g, String id) => (_flipped[g.id]?.contains(id) ?? false) == _defaultTrash(g);

  List<GroupMember> _toTrash(GroupView g) => g.others.where((m) => !_isKept(g, m.assetId)).toList();

  Future<void> _trash(GroupView g) async {
    final list = _toTrash(g);
    if (list.isNotEmpty) {
      HapticFeedback.lightImpact();
      await ref.read(groupServiceProvider).trash(list);
    }
    ref.invalidate(groupsProvider(widget.kind));
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    _next();
  }

  void _next() {
    final g = _groups!;
    if (_page >= g.length - 1) {
      Navigator.of(context).pop();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: SweeepColors.brand)));
    if (groups.isEmpty) {
      return Scaffold(body: SafeArea(child: Center(child: Text('Nothing to review.', style: Theme.of(context).textTheme.titleMedium))));
    }
    final current = groups[_page.clamp(0, groups.length - 1)];
    final toTrash = _toTrash(current);
    final saving = toTrash.fold<int>(0, (s, m) => s + m.sizeBytes);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back',
                    style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, minimumSize: const Size(44, 44)),
                  ),
                  Column(children: [
                    Text(kindTitle(widget.kind), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('Group ${_page + 1} of ${groups.length}', style: const TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
                  ]),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => GroupsScreen(kind: widget.kind))),
                    icon: const Icon(Icons.grid_view_rounded, size: 20),
                    tooltip: 'All groups',
                    style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, minimumSize: const Size(44, 44)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(minHeight: 4, value: (_page + 1) / groups.length, color: SweeepColors.brand, backgroundColor: SweeepColors.trackDim),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: const _KeepWord(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: groups.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _Peek(
                  controller: _controller,
                  index: i,
                  child: _GroupPage(
                  group: groups[i],
                  isKept: (id) => _isKept(groups[i], id),
                  onToggle: (id) => setState(() {
                    final k = _flipped.putIfAbsent(groups[i].id, () => <String>{});
                    k.contains(id) ? k.remove(id) : k.add(id);
                  }),
                )),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SweeepColors.card.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _next,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 54),
                      shape: const StadiumBorder(),
                      foregroundColor: SweeepColors.text,
                      side: BorderSide(color: Colors.white.withValues(alpha: .12)),
                    ),
                    child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PillButton(
                      height: 54,
                      label: toTrash.isEmpty ? 'Keep all · next' : 'Trash ${toTrash.length} · save ${formatBytes(saving)}',
                      onPressed: () => _trash(current),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// KEEEEP ONE headline, with the stretched lime letters.
class _KeepWord extends StatelessWidget {
  const _KeepWord();

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1),
          children: [
            const TextSpan(text: 'KEE'),
            const TextSpan(text: 'EEP', style: TextStyle(color: SweeepColors.keep)),
            const TextSpan(text: ' ONE'),
          ],
        ),
      );
}

/// Scales and dims pages that are not centred, so the neighbours read as
/// smaller cards peeking in from the sides.
class _Peek extends StatelessWidget {
  const _Peek({required this.controller, required this.index, required this.child});
  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          var d = 0.0;
          if (controller.hasClients && controller.position.haveDimensions) {
            d = ((controller.page ?? index.toDouble()) - index).abs().clamp(0.0, 1.0);
          }
          return Transform.scale(scale: 1 - .08 * d, child: child);
        },
      );
}

class _GroupPage extends StatelessWidget {
  const _GroupPage({required this.group, required this.isKept, required this.onToggle});
  final GroupView group;
  final bool Function(String id) isKept;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final best = group.best;
    final others = group.others;
    final why = group.kind == GroupKind.duplicate ? 'Oldest copy' : 'Sharpest';
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: SweeepColors.keep, width: 2),
                boxShadow: [BoxShadow(color: SweeepColors.keep.withValues(alpha: .18), blurRadius: 32)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ThumbImage(id: best.assetId, side: 720, fit: BoxFit.cover),
                    const Positioned(left: 14, top: 14, child: LimePill('BEST PICK')),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: GlassPill(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$why · ${best.width}×${best.height}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            Text(formatBytes(best.sizeBytes), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: others.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final m = others[i];
                final kept = isKept(m.assetId);
                final c = kept ? SweeepColors.keep : SweeepColors.trash;
                return Semantics(
                  button: true,
                  label: kept ? 'Keep this copy. Tap to trash it' : 'Trash this copy. Tap to keep it',
                  child: GestureDetector(
                    onTap: () => onToggle(m.assetId),
                    child: AspectRatio(
                      aspectRatio: 1.15,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: c, width: 2)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ThumbImage(id: m.assetId, side: 256),
                              if (!kept) Container(color: SweeepColors.trash.withValues(alpha: .18)),
                              Positioned(left: 8, bottom: 8, child: LimePill(kept ? 'KEEP' : 'TRASH', color: c)),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: GlassPill(height: 22, padding: const EdgeInsets.symmetric(horizontal: 7), child: Text(formatBytes(m.sizeBytes), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const Text('Tap a copy to flip it · swipe for the next group',
              style: TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
