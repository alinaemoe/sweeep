
import 'package:drift/drift.dart';

import '../core/native_core.dart';
import '../data/database.dart';
import '../platform/media_source.dart';

enum GroupKind { duplicate, similar }

class GroupMember {
  const GroupMember({required this.assetId, required this.sizeBytes, required this.createdAtMs, required this.width, required this.height});
  final String assetId;
  final int sizeBytes;
  final int createdAtMs;
  final int width;
  final int height;
}

class GroupView {
  const GroupView({required this.id, required this.kind, required this.bestId, required this.savingsBytes, required this.members});
  final int id;
  final GroupKind kind;
  final String bestId;
  final int savingsBytes;

  /// Live members (not already in the app trash), best first.
  final List<GroupMember> members;

  List<GroupMember> get others => members.where((m) => m.assetId != bestId).toList();
  GroupMember get best => members.firstWhere((m) => m.assetId == bestId);
}

class BuildResult {
  const BuildResult({required this.exactGroups, required this.similarGroups, required this.exactSavings, required this.similarSavings});
  final int exactGroups;
  final int similarGroups;
  final int exactSavings;
  final int similarSavings;
}

class TrashSummary {
  const TrashSummary(this.count, this.bytes);
  final int count;
  final int bytes;
}

String _hex(Uint8List b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

/// Stage 3-4 of the pipeline: exact duplicates (SHA-256 of files that share
/// a size) and similar groups (pHash + time window), persisted in Drift.
class GroupService {
  GroupService(this.db, this.media, this.core, {this.concurrency = 4});

  final SweeepDatabase db;
  final MediaSource media;
  final AnalysisCore core;
  final int concurrency;

  static const trashDays = 30;

  /// Ids whose file size collides with another asset and that have no digest yet.
  Future<List<String>> exactCandidates() async {
    final rows = await db.customSelect('''
      SELECT a.id AS id FROM assets a JOIN hashes h ON h.asset_id = a.id
      WHERE h.sha256 IS NULL AND a.size_bytes > 0
        AND a.size_bytes IN (SELECT size_bytes FROM assets GROUP BY size_bytes HAVING COUNT(*) > 1)
      ORDER BY a.size_bytes
    ''').get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

  /// Computes SHA-256 natively for size-collision candidates. Resumable:
  /// digests are written as they arrive.
  Future<int> hashExactCandidates({void Function(int done, int total)? onProgress, bool Function()? shouldCancel}) async {
    final ids = await exactCandidates();
    var done = 0;
    for (var i = 0; i < ids.length; i += concurrency) {
      if (shouldCancel?.call() ?? false) break;
      final chunk = ids.sublist(i, i + concurrency > ids.length ? ids.length : i + concurrency);
      final digests = await Future.wait(chunk.map(media.sha256));
      await db.batch((b) {
        for (var k = 0; k < chunk.length; k++) {
          final d = digests[k];
          if (d == null) continue;
          b.update(db.hashes, HashesCompanion(sha256: Value(d)), where: (h) => h.assetId.equals(chunk[k]));
        }
      });
      done += chunk.length;
      onProgress?.call(done, ids.length);
    }
    return done;
  }

  /// Rebuilds the persisted groups from the current hashes.
  Future<BuildResult> rebuild({int maxHamming = 6, int windowMs = 5000}) async {
    // --- exact duplicates
    final exactRows = await db.customSelect('''
      SELECT a.id AS id, a.size_bytes AS size, a.created_at_ms AS t, h.sha256 AS d
      FROM assets a JOIN hashes h ON h.asset_id = a.id WHERE h.sha256 IS NOT NULL
    ''').get();
    final byDigest = <String, List<({String id, int size, int t})>>{};
    for (final r in exactRows) {
      byDigest.putIfAbsent(_hex(r.read<Uint8List>('d')), () => []).add((id: r.read<String>('id'), size: r.read<int>('size'), t: r.read<int>('t')));
    }
    final newGroups = <_NewGroup>[];
    final excluded = <String>{}; // exact-group members that are not the representative
    for (final g in byDigest.values.where((g) => g.length > 1)) {
      g.sort((a, b) => a.t != b.t ? a.t.compareTo(b.t) : a.id.compareTo(b.id));
      final best = g.first; // keep the oldest copy
      final total = g.fold<int>(0, (s, e) => s + e.size);
      newGroups.add(_NewGroup(GroupKind.duplicate, best.id, total - best.size, g.map((e) => e.id).toList()));
      excluded.addAll(g.skip(1).map((e) => e.id));
    }

    // --- similar photos (representatives of exact groups stay in play)
    final sim = await db.customSelect('''
      SELECT a.id AS id, a.size_bytes AS size, a.created_at_ms AS t, h.phash AS p, COALESCE(h.laplacian_var, 0) AS lap
      FROM assets a JOIN hashes h ON h.asset_id = a.id
      WHERE h.phash IS NOT NULL AND a.media_type = 0
    ''').get();
    final items = sim.where((r) => !excluded.contains(r.read<String>('id'))).toList();
    if (items.isNotEmpty) {
      final labels = core.groupSimilar(
        [for (final r in items) r.read<int>('p')],
        [for (final r in items) r.read<int>('t')],
        maxHamming: maxHamming,
        windowMs: windowMs,
      );
      final buckets = <int, List<QueryRow>>{};
      for (var i = 0; i < items.length; i++) {
        final g = labels.labels[i];
        if (g >= 0) buckets.putIfAbsent(g, () => []).add(items[i]);
      }
      for (final g in buckets.values) {
        // best = sharpest; ties -> larger file
        g.sort((a, b) {
          final c = b.read<double>('lap').compareTo(a.read<double>('lap'));
          return c != 0 ? c : b.read<int>('size').compareTo(a.read<int>('size'));
        });
        final best = g.first;
        final total = g.fold<int>(0, (s, e) => s + e.read<int>('size'));
        newGroups.add(_NewGroup(GroupKind.similar, best.read<String>('id'), total - best.read<int>('size'), g.map((e) => e.read<String>('id')).toList()));
      }
    }

    // Diff against what is stored instead of wiping everything: a group whose
    // kind and member set did not change keeps its row (stable id, so open
    // screens and selections survive a rescan); only new groups are inserted
    // and vanished ones removed.
    final now = DateTime.now().millisecondsSinceEpoch;
    String keyOf(GroupKind k, Iterable<String> ids) => '${k.index}|${(ids.toList()..sort()).join(',')}';
    await db.transaction(() async {
      final stored = await db.customSelect(
        'SELECT g.id AS gid, g.kind AS kind, g.best_asset_id AS best, g.savings_bytes AS savings, m.asset_id AS aid '
        'FROM groups g JOIN group_members m ON m.group_id = g.id',
      ).get();
      final members = <int, List<String>>{};
      final info = <int, ({int kind, String? best, int savings})>{};
      for (final r in stored) {
        final id = r.read<int>('gid');
        (members[id] ??= []).add(r.read<String>('aid'));
        info[id] = (kind: r.read<int>('kind'), best: r.read<String?>('best'), savings: r.read<int>('savings'));
      }
      final byKey = <String, int>{};
      members.forEach((id, ids) => byKey[keyOf(GroupKind.values[info[id]!.kind], ids)] = id);

      final keep = <int>{};
      for (final g in newGroups) {
        final existing = byKey[keyOf(g.kind, g.ids)];
        if (existing != null && keep.add(existing)) {
          final old = info[existing]!;
          if (old.best != g.bestId || old.savings != g.savings) {
            await (db.update(db.groups)..where((t) => t.id.equals(existing))).write(GroupsCompanion(bestAssetId: Value(g.bestId), savingsBytes: Value(g.savings)));
          }
          continue;
        }
        final id = await db.into(db.groups).insert(GroupsCompanion.insert(
              kind: g.kind.index,
              savingsBytes: g.savings,
              createdAtMs: now,
              bestAssetId: Value(g.bestId),
            ));
        keep.add(id);
        await db.batch((b) => b.insertAll(db.groupMembers, [for (final m in g.ids) GroupMembersCompanion.insert(groupId: id, assetId: m)]));
      }
      // groups that no longer exist (members changed or deleted)
      await (db.delete(db.groups)..where((t) => t.id.isNotIn(keep))).go();
    });

    int count(GroupKind k) => newGroups.where((g) => g.kind == k).length;
    int saved(GroupKind k) => newGroups.where((g) => g.kind == k).fold(0, (s, g) => s + g.savings);
    return BuildResult(
      exactGroups: count(GroupKind.duplicate),
      similarGroups: count(GroupKind.similar),
      exactSavings: saved(GroupKind.duplicate),
      similarSavings: saved(GroupKind.similar),
    );
  }

  /// Groups of [kind], biggest saving first. Members already in the app
  /// trash are dropped; groups left with fewer than 2 live members vanish.
  Future<List<GroupView>> groups(GroupKind kind) async {
    final rows = await db.customSelect('''
      SELECT g.id AS gid, g.best_asset_id AS best, g.savings_bytes AS savings,
             a.id AS aid, a.size_bytes AS size, a.created_at_ms AS t, a.width AS w, a.height AS h
      FROM groups g
      JOIN group_members m ON m.group_id = g.id
      JOIN assets a ON a.id = m.asset_id
      WHERE g.kind = ? AND a.id NOT IN (SELECT asset_id FROM trash_items)
      ORDER BY g.savings_bytes DESC, g.id, a.created_at_ms
    ''', variables: [Variable.withInt(kind.index)]).get();

    final out = <GroupView>[];
    int? curId;
    String? best;
    int savings = 0;
    var members = <GroupMember>[];
    void flush() {
      if (curId != null && members.length > 1 && best != null && members.any((m) => m.assetId == best)) {
        members.sort((a, b) => a.assetId == best ? -1 : (b.assetId == best ? 1 : a.createdAtMs.compareTo(b.createdAtMs)));
        out.add(GroupView(id: curId, kind: kind, bestId: best, savingsBytes: savings, members: members));
      }
    }

    for (final r in rows) {
      final gid = r.read<int>('gid');
      if (gid != curId) {
        flush();
        curId = gid;
        best = r.read<String?>('best');
        savings = r.read<int>('savings');
        members = [];
      }
      members.add(GroupMember(
        assetId: r.read<String>('aid'),
        sizeBytes: r.read<int>('size'),
        createdAtMs: r.read<int>('t'),
        width: r.read<int>('w'),
        height: r.read<int>('h'),
      ));
    }
    flush();
    return out;
  }

  /// Soft-trash: records ids in the app trash (nothing is deleted from the
  /// device until the user empties it, Phase 3).
  Future<void> trash(List<GroupMember> members, {int reason = 1}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + trashDays * Duration.millisecondsPerDay;
    await db.batch((b) {
      b.insertAllOnConflictUpdate(db.trashItems, [
        for (final m in members) TrashItemsCompanion.insert(assetId: m.assetId, sizeBytes: m.sizeBytes, trashedAtMs: now, expiresAtMs: expires, reason: reason),
      ]);
      b.insertAllOnConflictUpdate(db.decisions, [
        for (final m in members) DecisionsCompanion.insert(assetId: m.assetId, decision: 1, decidedAtMs: now),
      ]);
    });
  }

  Future<TrashSummary> trashSummary() async {
    final r = await db.customSelect('SELECT COUNT(*) AS n, COALESCE(SUM(size_bytes), 0) AS b FROM trash_items').getSingle();
    return TrashSummary(r.read<int>('n'), r.read<int>('b'));
  }
}

class _NewGroup {
  _NewGroup(this.kind, this.bestId, this.savings, this.ids);
  final GroupKind kind;
  final String bestId;
  final int savings;
  final List<String> ids;
}
