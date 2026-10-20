import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../core/widgets.dart';
import '../../index/group_service.dart';
import '../../providers.dart';
import 'group_pager.dart';
import 'group_widgets.dart';

enum _Sort { saving, newest, copies }

/// "See all": grid of group stacks for one category, with sort chips and
/// multi-select ("Clean N groups" keeps the best photo of each).
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key, required this.kind});
  final GroupKind kind;

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  _Sort _sort = _Sort.saving;
  final Set<int> _picked = {};

  List<GroupView> _sorted(List<GroupView> groups) {
    final l = [...groups];
    switch (_sort) {
      case _Sort.saving:
        l.sort((a, b) => b.savingsBytes.compareTo(a.savingsBytes));
      case _Sort.newest:
        int newest(GroupView g) => g.members.fold<int>(0, (m, x) => x.createdAtMs > m ? x.createdAtMs : m);
        l.sort((a, b) => newest(b).compareTo(newest(a)));
      case _Sort.copies:
        l.sort((a, b) => b.members.length.compareTo(a.members.length));
    }
    return l;
  }

  void _toggle(int id) {
    HapticFeedback.selectionClick();
    setState(() => _picked.contains(id) ? _picked.remove(id) : _picked.add(id));
  }

  /// Everything but the best photo of each picked group goes to the app trash.
  Future<void> _clean(List<GroupView> groups) async {
    final chosen = groups.where((g) => _picked.contains(g.id)).toList();
    final list = [for (final g in chosen) ...g.others];
    if (list.isEmpty) return;
    HapticFeedback.mediumImpact();
    await ref.read(groupServiceProvider).trash(list);
    ref.invalidate(groupsProvider(widget.kind));
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    if (!mounted) return;
    setState(_picked.clear);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.movedToTrash(filesLabel(list.length)))));
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final async = ref.watch(groupsProvider(kind));
    final trash = ref.watch(trashSummaryProvider).value;
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SweeepColors.brand)),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: SweeepColors.trash))),
          data: (all) {
            final groups = _sorted(all);
            final ids = {for (final g in groups) g.id};
            _picked.retainAll(ids);
            final total = groups.fold<int>(0, (s, g) => s + g.savingsBytes);
            final picked = groups.where((g) => _picked.contains(g.id)).toList();
            final pickedSave = picked.fold<int>(0, (s, g) => s + g.savingsBytes);
            final allPicked = groups.isNotEmpty && _picked.length == groups.length;
            return Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: l10n.back,
                        style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, minimumSize: const Size(44, 44)),
                      ),
                      if (groups.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            HapticFeedback.selectionClick();
                            allPicked ? _picked.clear() : _picked.addAll(ids);
                          }),
                          style: TextButton.styleFrom(foregroundColor: SweeepColors.brand, minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 12)),
                          child: Text(allPicked ? l10n.clear : l10n.selectAll, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                    child: Text(kindTitle(kind), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      l10n.groupsSummary(l10n.groupsCount(groups.length), formatBytes(total)) +
                          (trash != null && trash.count > 0 ? l10n.groupsInTrash(trash.count, formatBytes(trash.bytes)) : ''),
                      style: const TextStyle(fontSize: 14, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Wrap(spacing: 8, children: [
                      _SortChip(l10n.sortSaving, _sort == _Sort.saving, () => setState(() => _sort = _Sort.saving)),
                      _SortChip(l10n.sortNewest, _sort == _Sort.newest, () => setState(() => _sort = _Sort.newest)),
                      _SortChip(l10n.sortCopies, _sort == _Sort.copies, () => setState(() => _sort = _Sort.copies)),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: groups.isEmpty
                        ? Center(child: Text(l10n.nothingLeft, style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 16)))
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(24, 14, 24, picked.isEmpty ? 24 : 140),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 22, childAspectRatio: .85),
                            itemCount: groups.length,
                            itemBuilder: (context, i) {
                              final g = groups[i];
                              final on = _picked.contains(g.id);
                              return Pressable(
                                label: l10n.groupSemantics(kindTitle(kind), g.members.length, on ? l10n.stateSelected : l10n.stateNotSelected),
                                onTap: () {
                                  if (_picked.isNotEmpty) {
                                    _toggle(g.id);
                                  } else {
                                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupPager(kind: kind, initialGroupId: g.id)));
                                  }
                                },
                                child: Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
                                  GroupStack(group: g),
                                  if (on)
                                    IgnorePointer(
                                      child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: SweeepColors.brand, width: 2))),
                                    ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _toggle(g.id),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: _Check(on: on),
                                      ),
                                    ),
                                  ),
                                ]),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // action bar slides in once something is selected
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: AnimatedSlide(
                  offset: picked.isEmpty ? const Offset(0, 1.4) : Offset.zero,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SweeepColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: .08)),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6))],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        l10n.groupsSelectedBar(l10n.groupsCount(picked.length)),
                        style: const TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      PillButton(
                        height: 52,
                        label: l10n.cleanGroups(l10n.groupsCount(picked.length), formatBytes(pickedSave)),
                        onPressed: picked.isEmpty ? null : () => _clean(groups),
                      ),
                    ]),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip(this.label, this.on, this.onTap);
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: on,
        label: l10n.semSort(label),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: on ? SweeepColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: on ? SweeepColors.brand : Colors.white.withValues(alpha: .12)),
            ),
            child: Center(widthFactor: 1, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w800 : FontWeight.w700, color: on ? SweeepColors.onAccent : SweeepColors.text))),
          ),
        ),
      );
}

class _Check extends StatelessWidget {
  const _Check({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? SweeepColors.brand : Colors.transparent,
          border: Border.all(color: on ? SweeepColors.brand : Colors.white.withValues(alpha: .5), width: 2),
        ),
        child: on ? const Icon(Icons.check_rounded, size: 15, color: SweeepColors.onAccent) : null,
      );
}
