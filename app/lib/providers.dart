import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/gray_image.dart';
import 'core/native_core.dart';
import 'data/database.dart';
import 'index/analysis_service.dart';
import 'index/group_service.dart';
import 'index/home_service.dart';
import 'index/index_service.dart';
import 'index/review_service.dart';
import 'l10n/l10n.dart';
import 'platform/media_source.dart';
import 'platform/messages.g.dart' show PermissionState;
import 'platform/scan_foreground.dart';

final databaseProvider = Provider<SweeepDatabase>((ref) {
  final db = SweeepDatabase(driftDatabase(name: 'sweeep'));
  ref.onDispose(db.close);
  return db;
});

final mediaSourceProvider = Provider<MediaSource>((ref) => PlatformMediaSource());

final analysisCoreProvider = Provider<AnalysisCore>((ref) => NativeCore.load());

final indexServiceProvider = Provider<IndexService>(
  (ref) => IndexService(ref.watch(databaseProvider), ref.watch(mediaSourceProvider)),
);

final analysisServiceProvider = Provider<AnalysisService>(
  (ref) => AnalysisService(ref.watch(databaseProvider), ref.watch(mediaSourceProvider), ref.watch(analysisCoreProvider)),
);

final groupServiceProvider = Provider<GroupService>(
  (ref) => GroupService(ref.watch(databaseProvider), ref.watch(mediaSourceProvider), ref.watch(analysisCoreProvider)),
);

/// Persisted groups of one kind, biggest saving first. Invalidate after trashing.
final groupsProvider = FutureProvider.family<List<GroupView>, GroupKind>(
  (ref, kind) => ref.watch(groupServiceProvider).groups(kind),
);

final homeServiceProvider = Provider<HomeService>((ref) => HomeService(ref.watch(databaseProvider), ref.watch(groupServiceProvider)));

/// Everything the Home feed shows. Invalidate after groups are rebuilt or items trashed.
final homeProvider = FutureProvider<HomeData>((ref) => ref.watch(homeServiceProvider).load());

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService(ref.watch(databaseProvider)));

/// Timeline of the library, month by month.
final timelineProvider = FutureProvider.autoDispose<List<MonthSummary>>((ref) => ref.watch(reviewServiceProvider).months());

final trashListProvider = FutureProvider.autoDispose<List<TrashEntry>>((ref) => ref.watch(reviewServiceProvider).trashed());

/// Large preview for the swipe card; released when the card leaves the screen.
final bigThumbProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, id) => ref.watch(mediaSourceProvider).thumbnail(id, maxSide: 900),
);

final trashSummaryProvider = FutureProvider<TrashSummary>((ref) => ref.watch(groupServiceProvider).trashSummary());

/// Color JPEG thumbnail, cached while in use.
typedef ThumbKey = ({String id, int side});
final thumbProvider = FutureProvider.autoDispose.family<Uint8List?, ThumbKey>((ref, k) {
  // Keep a thumbnail 30 s after it leaves the screen (scrolling back is instant),
  // then free it so browsing thousands of photos does not grow memory forever.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), link.close);
  ref.onDispose(timer.cancel);
  return ref.watch(mediaSourceProvider).thumbnail(k.id, maxSide: k.side);
});

/// Photo/video access state. `null` until first checked.
class PermissionController extends Notifier<PermissionState?> {
  @override
  PermissionState? build() {
    Future.microtask(check);
    return null;
  }

  Future<void> check() async => state = await ref.read(mediaSourceProvider).permissionState();

  Future<void> request() async => state = await ref.read(mediaSourceProvider).requestPermission();
}

final permissionProvider = NotifierProvider<PermissionController, PermissionState?>(PermissionController.new);

class ThumbSample {
  const ThumbSample(this.image, this.width, this.height);
  final ui.Image image;
  final int width;
  final int height;
}

class LibraryState {
  const LibraryState({
    this.syncing = false,
    this.processed = 0,
    this.result,
    this.stats,
    this.thumbs = const [],
    this.thumbMsAvg,
    this.syncMs,
    this.error,
    this.analyzing = false,
    this.analysisDone = 0,
    this.analysisTotal = 0,
    this.alreadyHashed = 0,
    this.analysisMs,
    this.hashStats,
    this.similar,
    this.verifyDone = 0,
    this.verifyTotal = 0,
    this.verifying = false,
    this.groupsBuilt,
    this.fullScan = false,
    this.paused = false,
    this.dismissed = false,
    this.grouping = false,
  });

  final bool syncing;
  final int processed;
  final IndexResult? result;
  final LibraryStats? stats;
  final List<ThumbSample> thumbs;
  final double? thumbMsAvg;
  final int? syncMs;
  final String? error;

  // Stage 2 (hashing)
  final bool analyzing;
  final int analysisDone; // processed in the current run
  final int analysisTotal; // pending at the start of the current run
  final int alreadyHashed; // hashed before this run started (checkpoint resume)
  final int? analysisMs;
  final HashStats? hashStats;
  final SimilarSummary? similar;

  // Stage 3-4 (exact duplicates + groups)
  final bool verifying;
  final int verifyDone;
  final int verifyTotal;
  final BuildResult? groupsBuilt;

  /// A long scan (first run or lots of new photos): shown on the Scan screen
  /// instead of just inside the Home oval.
  final bool fullScan;
  final bool paused;

  /// The user chose "Later" on the paused Scan screen.
  final bool dismissed;
  final bool grouping;

  bool get busy => syncing || analyzing || verifying;

  /// 0 reading library, 1 fingerprinting, 2 comparing, 3 grouping, 4 finished.
  int get phase {
    if (syncing) return 0;
    if (analyzing) return 1;
    if (grouping) return 3;
    if (verifying) return 2;
    if (paused) return analysisDone < analysisTotal ? 1 : 2;
    return 4;
  }

  /// Overall scan progress 0..1 (read library 0-8%, hash 8-80%, compare 80-97%, group 98%).
  double get progress {
    double frac(int done, int total) => total <= 0 ? 1 : (done / total).clamp(0.0, 1.0);
    switch (phase) {
      case 0:
        return .04;
      case 1:
        return .08 + .72 * frac(alreadyHashed + analysisDone, alreadyHashed + analysisTotal);
      case 2:
        return .8 + .17 * (verifyTotal == 0 ? 0 : frac(verifyDone, verifyTotal));
      case 3:
        return .98;
      default:
        return 1;
    }
  }

  LibraryState copyWith({
    bool? syncing,
    int? processed,
    IndexResult? result,
    LibraryStats? stats,
    List<ThumbSample>? thumbs,
    double? thumbMsAvg,
    int? syncMs,
    String? error,
    bool? analyzing,
    int? analysisDone,
    int? analysisTotal,
    int? alreadyHashed,
    int? analysisMs,
    HashStats? hashStats,
    SimilarSummary? similar,
    bool? verifying,
    int? verifyDone,
    int? verifyTotal,
    BuildResult? groupsBuilt,
    bool? fullScan,
    bool? paused,
    bool? dismissed,
    bool? grouping,
  }) =>
      LibraryState(
        syncing: syncing ?? this.syncing,
        processed: processed ?? this.processed,
        result: result ?? this.result,
        stats: stats ?? this.stats,
        thumbs: thumbs ?? this.thumbs,
        thumbMsAvg: thumbMsAvg ?? this.thumbMsAvg,
        syncMs: syncMs ?? this.syncMs,
        error: error,
        analyzing: analyzing ?? this.analyzing,
        analysisDone: analysisDone ?? this.analysisDone,
        analysisTotal: analysisTotal ?? this.analysisTotal,
        alreadyHashed: alreadyHashed ?? this.alreadyHashed,
        analysisMs: analysisMs ?? this.analysisMs,
        hashStats: hashStats ?? this.hashStats,
        similar: similar ?? this.similar,
        verifying: verifying ?? this.verifying,
        verifyDone: verifyDone ?? this.verifyDone,
        verifyTotal: verifyTotal ?? this.verifyTotal,
        groupsBuilt: groupsBuilt ?? this.groupsBuilt,
        fullScan: fullScan ?? this.fullScan,
        paused: paused ?? this.paused,
        dismissed: dismissed ?? this.dismissed,
        grouping: grouping ?? this.grouping,
      );
}

class LibraryController extends Notifier<LibraryState> {
  final _foreground = ScanForeground();

  @override
  LibraryState build() => const LibraryState();

  /// Whole scan (index -> hash -> duplicates -> groups), kept alive in the
  /// background by a foreground service for as long as it runs.
  Future<void> sync() async {
    if (state.busy) return;
    _cancel = false;
    state = state.copyWith(syncing: true, processed: 0, paused: false, dismissed: false);
    await _foreground.start();
    try {
      state = state.copyWith(fullScan: await _isBigScan());
      await _sync();
    } finally {
      await _foreground.stop();
    }
  }

  bool _cancel = false;

  /// Stops after the current batch; everything done so far is saved, and
  /// [sync] picks up from there.
  void pause() {
    _cancel = true;
    state = state.copyWith(paused: true);
  }

  /// "Later" on the paused Scan screen: back to Home with what is there.
  void dismissScan() => state = state.copyWith(dismissed: true);

  static const _bigScanFiles = 300;

  /// First run (empty index) or plenty of unhashed photos.
  Future<bool> _isBigScan() async {
    final stats = await ref.read(indexServiceProvider).stats();
    if (stats.total == 0) return true;
    return await ref.read(analysisServiceProvider).pendingCount() >= _bigScanFiles;
  }

  bool _estimating = false;
  DateTime _lastEstimate = DateTime.fromMillisecondsSinceEpoch(0);

  /// Live "groups found / could free" while hashing, at most every 6 s.
  void _maybeEstimate() {
    if (_estimating || DateTime.now().difference(_lastEstimate) < const Duration(seconds: 6)) return;
    _estimating = true;
    ref.read(analysisServiceProvider).similarSummary().then((sim) {
      state = state.copyWith(similar: sim);
    }).catchError((_) {}).whenComplete(() {
      _estimating = false;
      _lastEstimate = DateTime.now();
    });
  }

  Future<void> _sync() async {
    final index = ref.read(indexServiceProvider);
    final media = ref.read(mediaSourceProvider);
    try {
      final sw = Stopwatch()..start();
      final result = await index.sync(onProgress: (n) => state = state.copyWith(processed: n));
      final syncMs = sw.elapsedMilliseconds;
      final stats = await index.stats();
      state = state.copyWith(result: result, stats: stats, syncMs: syncMs);

      // Gray thumbnail check: fetch a few of the newest photos, time them.
      final ids = await index.newestPhotoIds(8);
      final thumbs = <ThumbSample>[];
      final tsw = Stopwatch()..start();
      for (final id in ids) {
        final t = await media.grayThumbnail(id, maxSide: 128);
        if (t != null) {
          thumbs.add(ThumbSample(await grayToImage(t.bytes, t.width, t.height), t.width, t.height));
        }
      }
      final avg = ids.isEmpty ? null : tsw.elapsedMilliseconds / ids.length;
      state = state.copyWith(syncing: false, thumbs: thumbs, thumbMsAvg: avg);
      if (!state.fullScan && await ref.read(analysisServiceProvider).pendingCount() >= _bigScanFiles) {
        state = state.copyWith(fullScan: true);
      }
    } catch (e) {
      state = state.copyWith(syncing: false, error: e.toString());
      return;
    }
    await analyze();
  }

  /// Stage 2: hash everything not yet hashed; resumes after a restart.
  Future<void> analyze() async {
    if (state.analyzing) return;
    if (_cancel) return;
    final svc = ref.read(analysisServiceProvider);
    try {
      final pending = await svc.pendingCount();
      final total = state.stats?.total ?? pending;
      state = state.copyWith(analyzing: true, analysisDone: 0, analysisTotal: pending, alreadyHashed: total - pending);
      final sw = Stopwatch()..start();
      await svc.run(shouldCancel: () => _cancel, onProgress: (done, tot) {
        state = state.copyWith(analysisDone: done, analysisTotal: tot);
        _foreground.update(done, tot, l10n.notifHashing(fmtNum(done), fmtNum(tot)));
        _maybeEstimate();
      });
      final ms = sw.elapsedMilliseconds;
      final hs = await svc.stats();
      final sim = await svc.similarSummary();
      state = state.copyWith(analyzing: false, analysisMs: ms, hashStats: hs, similar: sim);
      if (_cancel) return;
    } catch (e) {
      state = state.copyWith(analyzing: false, error: e.toString());
      return;
    }
    await buildGroups();
  }

  /// Exact-duplicate verification (SHA-256 of same-size files), then persist groups.
  Future<void> buildGroups() async {
    if (state.verifying) return;
    final groups = ref.read(groupServiceProvider);
    try {
      state = state.copyWith(verifying: true, verifyDone: 0, verifyTotal: 0);
      await groups.hashExactCandidates(shouldCancel: () => _cancel, onProgress: (d, t) {
        state = state.copyWith(verifyDone: d, verifyTotal: t);
        _foreground.update(d, t, l10n.notifChecking(fmtNum(d), fmtNum(t)));
      });
      if (_cancel) {
        state = state.copyWith(verifying: false);
        return;
      }
      state = state.copyWith(grouping: true);
      final built = await groups.rebuild();
      ref.invalidate(groupsProvider);
      ref.invalidate(trashSummaryProvider);
      ref.invalidate(homeProvider);
      state = state.copyWith(verifying: false, grouping: false, groupsBuilt: built);
    } catch (e) {
      state = state.copyWith(verifying: false, grouping: false, error: e.toString());
    }
  }
}

final libraryProvider = NotifierProvider<LibraryController, LibraryState>(LibraryController.new);

/// Whether the full-screen Scan screen is up (long scans, or paused ones until
/// the user taps "Later").
final scanScreenProvider = Provider<bool>((ref) {
  final s = ref.watch(libraryProvider);
  return s.fullScan && !s.dismissed && (s.busy || s.grouping || s.paused);
});
