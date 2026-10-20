import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../core/widgets.dart';
import '../../index/group_service.dart';
import '../../providers.dart';
import 'group_widgets.dart';
import 'groups_screen.dart';

/// Group review: swipe sideways through groups of one category. Every photo
/// of a group is either KEEP or TRASH (the suggested BEST PICK is only a
/// starting point, it can be trashed too, or any other photo can be kept).
///
/// - tap a small photo: look at it big (compare)
/// - tap the big photo, or hold a small one: flip KEEP / TRASH
/// - pull the big photo down: trash the whole group
/// - the main button commits; Undo brings it back (the app trash is soft)
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
  final Map<int, Map<String, bool>> _choice = {}; // group id -> photo id -> kept (only what the user changed)
  final Map<int, String> _focus = {}; // group id -> photo shown big
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

  /// Exact duplicates: keep the best, trash the identical copies. Similar
  /// photos: keep everything, lookalikes are a judgment call.
  bool _defaultKept(GroupView g, String id) => g.kind == GroupKind.duplicate ? id == g.bestId : true;

  bool _isKept(GroupView g, String id) => _choice[g.id]?[id] ?? _defaultKept(g, id);

  String _focusOf(GroupView g) => _focus[g.id] ?? g.bestId;

  List<GroupMember> _toTrash(GroupView g) => g.members.where((m) => !_isKept(g, m.assetId)).toList();

  void _toggle(GroupView g, String id) {
    HapticFeedback.selectionClick();
    setState(() => (_choice[g.id] ??= {})[id] = !_isKept(g, id));
  }

  void _invalidate() {
    ref.invalidate(groupsProvider(widget.kind));
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(timelineProvider);
  }

  /// Applies the group's choices: trashed photos go to the app trash, kept
  /// ones are marked as reviewed. [all] trashes everything, the suggested
  /// best too.
  Future<void> _commit(GroupView g, {bool all = false}) async {
    final trash = all ? g.members : _toTrash(g);
    final keep = all ? <GroupMember>[] : g.members.where((m) => _isKept(g, m.assetId)).toList();
    final svc = ref.read(groupServiceProvider);
    if (trash.isNotEmpty) {
      HapticFeedback.lightImpact();
      await svc.trash(trash);
    }
    if (keep.isNotEmpty) await svc.markKept(keep);
    _invalidate();
    if (!mounted) return;
    if (trash.isNotEmpty) {
      final ids = [for (final m in [...trash, ...keep]) m.assetId];
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          content: Text(l10n.movedToTrash(filesLabel(trash.length))),
          action: SnackBarAction(
            label: l10n.undo,
            textColor: SweeepColors.brand,
            onPressed: () async {
              await ref.read(reviewServiceProvider).restore(ids);
              if (mounted) setState(() => _choice.remove(g.id));
              _invalidate();
            },
          ),
        ));
    }
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
      return Scaffold(body: SafeArea(child: Center(child: Text(l10n.pagerNothing, style: Theme.of(context).textTheme.titleMedium))));
    }
    final current = groups[_page.clamp(0, groups.length - 1)];
    final toTrash = _toTrash(current);
    final saving = toTrash.fold<int>(0, (s, m) => s + m.sizeBytes);
    final allTrash = toTrash.length == current.members.length;
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
                    tooltip: l10n.back,
                    style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, minimumSize: const Size(44, 44)),
                  ),
                  Column(children: [
                    Text(kindTitle(widget.kind), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(l10n.pagerGroupOf(_page + 1, groups.length), style: const TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
                  ]),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => GroupsScreen(kind: widget.kind))),
                    icon: const Icon(Icons.grid_view_rounded, size: 20),
                    tooltip: l10n.tipAllGroups,
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
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: _KeepWord(),
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
                    focusId: _focusOf(groups[i]),
                    isKept: (id) => _isKept(groups[i], id),
                    onFocus: (id) => setState(() => _focus[groups[i].id] = id),
                    onToggle: (id) => _toggle(groups[i], id),
                    onTrashAll: () => _commit(groups[i], all: true),
                  ),
                ),
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
                    child: Text(l10n.skip, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PillButton(
                      height: 54,
                      color: allTrash ? SweeepColors.trash : SweeepColors.brand,
                      label: toTrash.isEmpty
                          ? l10n.pagerKeepAll
                          : (allTrash ? l10n.pagerTrashAllN(toTrash.length, formatBytes(saving)) : l10n.pagerTrashN(toTrash.length, formatBytes(saving))),
                      onPressed: () => _commit(current),
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
  Widget build(BuildContext context) => const Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1),
          children: [
            TextSpan(text: 'KEE'),
            TextSpan(text: 'EEP', style: TextStyle(color: SweeepColors.keep)),
            TextSpan(text: ' ONE'),
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

class _GroupPage extends StatefulWidget {
  const _GroupPage({required this.group, required this.focusId, required this.isKept, required this.onFocus, required this.onToggle, required this.onTrashAll});
  final GroupView group;
  final String focusId;
  final bool Function(String id) isKept;
  final void Function(String id) onFocus;
  final void Function(String id) onToggle;
  final VoidCallback onTrashAll;

  @override
  State<_GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<_GroupPage> {
  static const _commitAt = 110.0;
  double _pull = 0; // how far the big photo is pulled down
  bool _armed = false;

  void _pullUpdate(DragUpdateDetails d) {
    setState(() => _pull = (_pull + d.delta.dy).clamp(0.0, 320.0));
    final armed = _pull > _commitAt;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.mediumImpact();
    }
  }

  void _pullEnd(DragEndDetails d) {
    final go = _pull > _commitAt || (d.primaryVelocity ?? 0) > 1100;
    setState(() {
      _pull = 0;
      _armed = false;
    });
    if (go) widget.onTrashAll();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final focus = g.members.firstWhere((m) => m.assetId == widget.focusId, orElse: () => g.best);
    final kept = widget.isKept(focus.assetId);
    final isBest = focus.assetId == g.bestId;
    final c = kept ? SweeepColors.keep : SweeepColors.trash;
    final why = g.kind == GroupKind.duplicate ? l10n.whyOldest : l10n.whySharpest;
    final pullT = (_pull / _commitAt).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onToggle(focus.assetId),
              onVerticalDragUpdate: _pullUpdate,
              onVerticalDragEnd: _pullEnd,
              child: Transform.translate(
                offset: Offset(0, _pull * .55),
                child: Semantics(
                  button: true,
                  label: kept ? l10n.semKeptCopy : l10n.semTrashCopy,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: c, width: 2),
                      boxShadow: [BoxShadow(color: c.withValues(alpha: .18), blurRadius: 32)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ThumbImage(id: focus.assetId, side: 720, fit: BoxFit.cover),
                          // trashed: tinted red, like on the Swipe card
                          IgnorePointer(child: AnimatedContainer(duration: const Duration(milliseconds: 180), color: SweeepColors.trash.withValues(alpha: kept ? 0 : .2))),
                          if (_pull > 0) IgnorePointer(child: ColoredBox(color: SweeepColors.trash.withValues(alpha: .45 * pullT))),
                          if (_pull > 8)
                            Center(
                              child: Opacity(
                                opacity: pullT,
                                child: Transform.rotate(angle: -8 * 3.14159 / 180, child: _BigStamp(l10n.stampTrashAll)),
                              ),
                            ),
                          if (isBest) Positioned(left: 14, top: 14, child: LimePill(l10n.pillBestPick)),
                          Positioned(right: 14, top: 14, child: LimePill(kept ? l10n.pillKeep : l10n.pillTrash, color: c)),
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
                                  Text(isBest ? '$why · ${focus.width}×${focus.height}' : '${focus.width}×${focus.height}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  Text(formatBytes(focus.sizeBytes), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SweeepColors.textMutedSmall)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: g.members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final m = g.members[i];
                final k = widget.isKept(m.assetId);
                final tc = k ? SweeepColors.keep : SweeepColors.trash;
                final here = m.assetId == focus.assetId;
                return Semantics(
                  button: true,
                  selected: here,
                  label: k ? l10n.semKeptCopy : l10n.semTrashCopy,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onFocus(m.assetId);
                    },
                    onLongPress: () => widget.onToggle(m.assetId),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        // the photo shown big gets a white ring
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: here ? SweeepColors.text : Colors.transparent, width: 2)),
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: tc, width: 2)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ThumbImage(id: m.assetId, side: 256),
                                if (!k) Container(color: SweeepColors.trash.withValues(alpha: .22)),
                                Positioned(left: 6, bottom: 6, child: LimePill(k ? l10n.pillKeep : l10n.pillTrash, color: tc)),
                                if (m.assetId == g.bestId) const Positioned(left: 6, top: 6, child: Icon(Icons.star_rounded, size: 18, color: SweeepColors.keep)),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: GlassPill(height: 20, padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(formatBytes(m.sizeBytes), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                                ),
                              ],
                            ),
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
          Text(l10n.pagerTip,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BigStamp extends StatelessWidget {
  const _BigStamp(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: SweeepColors.text, width: 3), borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2, color: SweeepColors.text)),
      );
}
