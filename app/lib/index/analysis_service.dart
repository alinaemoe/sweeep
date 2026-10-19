
import 'package:drift/drift.dart';

import '../core/native_core.dart';
import '../data/database.dart';
import '../platform/media_source.dart';

class SimilarSummary {
  const SimilarSummary({required this.groups, required this.members, required this.savingsBytes});
  final int groups;
  final int members;

  /// Bytes freed if every group kept only its largest file. A rough bound;
  /// real best-pick (sharpness) arrives with the group review screens.
  final int savingsBytes;
}

class HashStats {
  const HashStats({
    required this.hashed,
    required this.unreadable,
    required this.dark,
    required this.lapP10,
    required this.lapP50,
    required this.lapP90,
  });
  final int hashed;
  final int unreadable;
  final int dark;
  final double lapP10;
  final double lapP50;
  final double lapP90;
}

/// Stage 2 of the scan pipeline: grayscale thumbnail -> hashes + metrics,
/// persisted in batches. The `hashes` table doubles as the checkpoint:
/// anything without a row at the current [version] is still pending, so a
/// killed run resumes exactly where it stopped.
class AnalysisService {
  AnalysisService(this.db, this.media, this.core, {this.concurrency = 8, this.batchSize = 64});

  final SweeepDatabase db;
  final MediaSource media;
  final AnalysisCore core;
  final int concurrency;
  final int batchSize;

  /// Bump to force re-analysis of everything (e.g. algorithm change).
  static const version = 1;
  static const thumbSide = 128;

  Future<int> pendingCount() async {
    final r = await db.customSelect(
      'SELECT COUNT(*) AS n FROM assets a LEFT JOIN hashes h ON h.asset_id = a.id '
      'WHERE h.asset_id IS NULL OR h.analysis_version < ?',
      variables: [Variable.withInt(version)],
    ).getSingle();
    return r.read<int>('n');
  }

  Future<List<String>> _nextBatch() async {
    final rows = await db.customSelect(
      'SELECT a.id AS id FROM assets a LEFT JOIN hashes h ON h.asset_id = a.id '
      'WHERE h.asset_id IS NULL OR h.analysis_version < ? ORDER BY a.created_at_ms DESC LIMIT ?',
      variables: [Variable.withInt(version), Variable.withInt(batchSize)],
    ).get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

  /// Analyses everything pending. Returns the number processed in this run.
  /// [shouldCancel] is polled between batches (each batch is committed).
  Future<int> run({void Function(int done, int total)? onProgress, bool Function()? shouldCancel}) async {
    final total = await pendingCount();
    var done = 0;
    while (true) {
      if (shouldCancel?.call() ?? false) break;
      final ids = await _nextBatch();
      if (ids.isEmpty) break;

      final rows = <HashesCompanion>[];
      for (var i = 0; i < ids.length; i += concurrency) {
        final chunk = ids.sublist(i, i + concurrency > ids.length ? ids.length : i + concurrency);
        final thumbs = await Future.wait(chunk.map((id) => media.grayThumbnail(id, maxSide: thumbSide)));
        for (var k = 0; k < chunk.length; k++) {
          rows.add(_analyze(chunk[k], thumbs[k]?.bytes, thumbs[k]?.width, thumbs[k]?.height));
        }
      }
      await db.batch((b) => b.insertAllOnConflictUpdate(db.hashes, rows));
      done += ids.length;
      onProgress?.call(done, total);
    }
    return done;
  }

  HashesCompanion _analyze(String id, Uint8List? bytes, int? w, int? h) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final a = (bytes == null || w == null || h == null) ? null : core.analyze(bytes, w, h);
    // An unreadable asset still gets a row (null hashes) so it is not retried
    // forever; it surfaces later under "Other / strange".
    return HashesCompanion.insert(
      assetId: id,
      analyzedAtMs: now,
      analysisVersion: version,
      phash: Value(a?.phash),
      dhash: Value(a?.dhash),
      ahash: Value(a?.ahash),
      laplacianVar: Value(a?.laplacianVar),
      medianBrightness: Value(a?.medianBrightness),
    );
  }

  Future<HashStats> stats() async {
    final c = await db.customSelect('''
      SELECT COUNT(*) AS total,
             COALESCE(SUM(phash IS NULL), 0) AS bad,
             COALESCE(SUM(median_brightness < 40), 0) AS dark
      FROM hashes
    ''').getSingle();
    final laps = await db.customSelect(
      'SELECT laplacian_var AS v FROM hashes WHERE laplacian_var IS NOT NULL ORDER BY laplacian_var',
    ).get();
    double pct(double p) => laps.isEmpty ? 0 : laps[((laps.length - 1) * p).round()].read<double>('v');
    return HashStats(
      hashed: c.read<int>('total') - c.read<int>('bad'),
      unreadable: c.read<int>('bad'),
      dark: c.read<int>('dark'),
      lapP10: pct(.1),
      lapP50: pct(.5),
      lapP90: pct(.9),
    );
  }

  /// Quick "burst" grouping over photos: pHash within [maxHamming] and
  /// capture times within [windowMs]. Computed in Rust, not persisted yet.
  Future<SimilarSummary> similarSummary({int maxHamming = 6, int windowMs = 5000}) async {
    final rows = await db.customSelect(
      'SELECT h.phash AS p, a.created_at_ms AS t, a.size_bytes AS s '
      'FROM hashes h JOIN assets a ON a.id = h.asset_id '
      'WHERE h.phash IS NOT NULL AND a.media_type = 0',
    ).get();
    if (rows.isEmpty) return const SimilarSummary(groups: 0, members: 0, savingsBytes: 0);
    final hashes = [for (final r in rows) r.read<int>('p')];
    final ts = [for (final r in rows) r.read<int>('t')];
    final sizes = [for (final r in rows) r.read<int>('s')];
    final res = core.groupSimilar(hashes, ts, maxHamming: maxHamming, windowMs: windowMs);

    final total = <int, int>{};
    final largest = <int, int>{};
    var members = 0;
    for (var i = 0; i < res.labels.length; i++) {
      final g = res.labels[i];
      if (g < 0) continue;
      members++;
      total[g] = (total[g] ?? 0) + sizes[i];
      if (sizes[i] > (largest[g] ?? 0)) largest[g] = sizes[i];
    }
    var savings = 0;
    total.forEach((g, t) => savings += t - largest[g]!);
    return SimilarSummary(groups: res.count, members: members, savingsBytes: savings);
  }
}
