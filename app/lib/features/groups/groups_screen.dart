import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../index/group_service.dart';
import '../../providers.dart';
import 'group_pager.dart';
import 'group_widgets.dart';

/// "See all": grid of group stacks for one category.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key, required this.kind});
  final GroupKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupsProvider(kind));
    final trash = ref.watch(trashSummaryProvider).value;
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SweeepColors.brand)),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: SweeepColors.trash))),
          data: (groups) {
            final total = groups.fold<int>(0, (s, g) => s + g.savingsBytes);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                      style: IconButton.styleFrom(backgroundColor: SweeepColors.card, foregroundColor: SweeepColors.text, minimumSize: const Size(44, 44)),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(kindTitle(kind), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${groups.length} groups · ${formatBytes(total)} to free'
                    '${trash != null && trash.count > 0 ? ' · ${trash.count} in trash (${formatBytes(trash.bytes)})' : ''}',
                    style: const TextStyle(fontSize: 14, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: groups.isEmpty
                      ? const Center(child: Text('Nothing left here.', style: TextStyle(color: SweeepColors.textMutedSmall, fontSize: 16)))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 22, childAspectRatio: .85),
                          itemCount: groups.length,
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupPager(kind: kind, initialIndex: i))),
                            child: GroupStack(group: groups[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
