import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../index/review_service.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart';

/// App trash: everything the user marked, still on the device. Restore puts
/// items back; "Delete forever" needs the system delete flow (next phase).
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> with SingleTickerProviderStateMixin {
  final _selected = <String>{};
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final ids = _selected.toList();
    await ref.read(reviewServiceProvider).restore(ids);
    _selected.clear();
    ref.invalidate(trashListProvider);
    ref.invalidate(trashSummaryProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(groupsProvider);
    if (mounted) setState(() {});
  }

  void _deleteForever() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Permanent delete is coming soon. Your files are untouched.')));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(trashListProvider);
    final items = async.value ?? const <TrashEntry>[];
    final total = items.fold<int>(0, (s, e) => s + e.sizeBytes);
    final selBytes = items.where((e) => _selected.contains(e.id)).fold<int>(0, (s, e) => s + e.sizeBytes);
    final allSelected = items.isNotEmpty && _selected.length == items.length;

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                  icon: const Icon(Icons.chevron_left_rounded),
                  style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, fixedSize: const Size(44, 44), side: const BorderSide(color: SweeepColors.cardBorder)),
                ),
                TextButton(
                  onPressed: items.isEmpty ? null : () => setState(() => allSelected ? _selected.clear() : _selected.addAll(items.map((e) => e.id))),
                  style: TextButton.styleFrom(foregroundColor: SweeepColors.brand, minimumSize: const Size(48, 44)),
                  child: Text(allSelected ? 'Clear' : 'Select all', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            SizedBox(height: 76, child: Align(alignment: Alignment.bottomCenter, child: _CleanWord(controller: _wave))),
            const SizedBox(height: 10),
            Text(
              items.isEmpty ? 'Trash is empty' : '${items.length} files · ${formatBytes(total)} will be freed',
              style: const TextStyle(fontSize: 14, color: SweeepColors.textMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(async.isLoading ? '' : 'Swiped-away photos land here.', style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 15)))
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, _selected.isEmpty ? 24 : 150),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final e = items[i];
                        final on = _selected.contains(e.id);
                        return GestureDetector(
                          onTap: () => setState(() => on ? _selected.remove(e.id) : _selected.add(e.id)),
                          child: _Cell(entry: e, selected: on),
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
                  Text('${_selected.length} selected · ${formatBytes(selBytes)} · recoverable until you empty',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _restore,
                        style: OutlinedButton.styleFrom(foregroundColor: SweeepColors.brand, side: const BorderSide(color: SweeepColors.brand), minimumSize: const Size(0, 52), shape: const StadiumBorder()),
                        child: Text('Restore ${_selected.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _deleteForever,
                        style: FilledButton.styleFrom(backgroundColor: SweeepColors.trash, foregroundColor: SweeepColors.onAccent, minimumSize: const Size(0, 52), shape: const StadiumBorder()),
                        child: const Text('Delete forever', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.entry, required this.selected});
  final TrashEntry entry;
  final bool selected;

  String _len(int ms) {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? SweeepColors.brand : Colors.transparent, width: 2)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(fit: StackFit.expand, children: [
            ThumbImage(id: entry.id, side: 256),
            if (entry.isVideo && entry.durationMs != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .7), borderRadius: BorderRadius.circular(9)),
                  child: Text(_len(entry.durationMs!), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? SweeepColors.brand : Colors.transparent,
                  border: selected ? null : Border.all(color: Colors.white.withValues(alpha: .4), width: 2),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 14, color: SweeepColors.onAccent) : null,
              ),
            ),
          ]),
        ),
      );
}

/// CLEAAAN with a permanent wave; the A's are lavender.
class _CleanWord extends StatelessWidget {
  const _CleanWord({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          const word = 'CLEAAAN';
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < word.length; i++)
                Transform.translate(
                  // each letter bounces in the first 40% of the cycle, staggered
                  offset: Offset(0, _bounce((controller.value - i * .027) % 1.0)),
                  child: Text(word[i],
                      style: TextStyle(fontSize: 58, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1, color: (i >= 3 && i <= 5) ? SweeepColors.brand : SweeepColors.text)),
                ),
            ],
          );
        },
      );

  double _bounce(double p) => p < .4 ? -14 * math.sin(math.pi * (p / .4)) : 0;
}
