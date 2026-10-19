import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/group_service.dart';
import '../groups/groups_screen.dart';
import '../../platform/messages.g.dart' show PermissionState;
import '../../providers.dart';

String _bytes(int b) {
  const u = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i < 2 ? 0 : 1)} ${u[i]}';
}

/// Phase 1 "library index" screen: runs the delta index and shows what the
/// device library contains, plus a grayscale-thumbnail check. The real Scan
/// and Home screens replace this in later phases.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(libraryProvider.notifier).sync());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(libraryProvider);
    final perm = ref.watch(permissionProvider);
    final stats = s.stats;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const SweeepWordmark(),
            const SizedBox(height: 20),
            if (perm == PermissionState.limited)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SweeepCard(
                  child: Text('Limited access: Sweeep only sees the photos you selected.',
                      style: TextStyle(color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
                ),
              ),
            Text(s.syncing ? 'INDEXING…' : 'LIBRARY INDEXED',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: SweeepColors.textMutedSmall)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _fmt(s.syncing ? s.processed : (stats?.total ?? 0)),
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, letterSpacing: -3, height: 1),
                ),
                const SizedBox(width: 8),
                const Text('files', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: SweeepColors.brand)),
              ],
            ),
            if (s.syncing) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 6, color: SweeepColors.brand, backgroundColor: SweeepColors.trackDim),
            ],
            if (s.error != null) ...[
              const SizedBox(height: 12),
              Text(s.error!, style: const TextStyle(color: SweeepColors.trash)),
            ],
            if (stats != null) ...[
              const SizedBox(height: 20),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _Stat('Photos', _fmt(stats.photos)),
                _Stat('Videos', _fmt(stats.videos)),
                _Stat('Screenshots', _fmt(stats.screenshots)),
                _Stat('Screen rec.', _fmt(stats.screenRecordings)),
                _Stat('Chat media', _fmt(stats.chatMedia)),
                _Stat('Total size', _bytes(stats.bytes)),
              ]),
              const SizedBox(height: 14),
              Text(
                '${s.result!.full ? 'Full' : 'Delta'} sync: ${s.result!.upserted} updated, ${s.result!.removed} removed · ${s.syncMs} ms',
                style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
            if (s.thumbs.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Grayscale thumbnails · ${s.thumbMsAvg?.toStringAsFixed(0)} ms each',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: s.thumbs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final t = s.thumbs[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(aspectRatio: t.width / t.height, child: RawImage(image: t.image, fit: BoxFit.cover)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text('${s.thumbs.first.width}×${s.thumbs.first.height} px, 8-bit gray',
                  style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 12)),
            ],
            if (s.stats != null) ...[
              const SizedBox(height: 24),
              const Text('Fingerprints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (s.analyzing) ...[
                Text(
                  '${_fmt(s.alreadyHashed + s.analysisDone)} of ${_fmt(s.alreadyHashed + s.analysisTotal)} hashed'
                  '${s.alreadyHashed > 0 ? ' · resumed from ${_fmt(s.alreadyHashed)}' : ''}',
                  style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 6,
                  value: (s.alreadyHashed + s.analysisTotal) == 0 ? null : (s.alreadyHashed + s.analysisDone) / (s.alreadyHashed + s.analysisTotal),
                  color: SweeepColors.brand,
                  backgroundColor: SweeepColors.trackDim,
                ),
              ],
              if (!s.analyzing && s.hashStats != null) ...[
                Wrap(spacing: 10, runSpacing: 10, children: [
                  _Stat('Hashed', _fmt(s.hashStats!.hashed)),
                  _Stat('Unreadable', _fmt(s.hashStats!.unreadable)),
                  _Stat('Dark (<40)', _fmt(s.hashStats!.dark)),
                  if (s.similar != null) _Stat('Burst groups', _fmt(s.similar!.groups)),
                  if (s.similar != null) _Stat('In groups', _fmt(s.similar!.members)),
                  if (s.similar != null) _Stat('Could free', _bytes(s.similar!.savingsBytes)),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Laplacian variance p10 / p50 / p90: ${s.hashStats!.lapP10.toStringAsFixed(0)} / '
                  '${s.hashStats!.lapP50.toStringAsFixed(0)} / ${s.hashStats!.lapP90.toStringAsFixed(0)}'
                  '${s.analysisMs != null && s.analysisTotal > 0 ? ' · hashed ${_fmt(s.analysisTotal)} in ${(s.analysisMs! / 1000).toStringAsFixed(1)} s' : ''}',
                  style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ],
            ],
            if (s.verifying) ...[
              const SizedBox(height: 16),
              Text(
                s.verifyTotal == 0 ? 'Looking for exact duplicates…' : 'Verifying duplicates · ${_fmt(s.verifyDone)} of ${_fmt(s.verifyTotal)} files compared',
                style: const TextStyle(color: SweeepColors.textMutedSmall, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                minHeight: 6,
                value: s.verifyTotal == 0 ? null : s.verifyDone / s.verifyTotal,
                color: SweeepColors.brand,
                backgroundColor: SweeepColors.trackDim,
              ),
            ],
            if (s.groupsBuilt != null && !s.verifying) ...[
              const SizedBox(height: 24),
              const Text('Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              PillButton(
                label: 'Duplicates · ${_fmt(s.groupsBuilt!.exactGroups)} groups · ${_bytes(s.groupsBuilt!.exactSavings)}',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GroupsScreen(kind: GroupKind.duplicate))),
              ),
              const SizedBox(height: 10),
              PillButton(
                label: 'Similar · ${_fmt(s.groupsBuilt!.similarGroups)} groups · ${_bytes(s.groupsBuilt!.similarSavings)}',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GroupsScreen(kind: GroupKind.similar))),
              ),
            ],
            const SizedBox(height: 28),
            PillButton(
              label: s.syncing ? 'Indexing…' : (s.analyzing ? 'Hashing…' : (s.verifying ? 'Comparing…' : 'Re-sync')),
              onPressed: (s.syncing || s.analyzing || s.verifying) ? null : () => ref.read(libraryProvider.notifier).sync(),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 104,
        child: SweeepCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: SweeepColors.textMutedSmall, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
