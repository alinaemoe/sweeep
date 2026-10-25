import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/gray_image.dart';
import 'core/native_core.dart';
import 'data/database.dart';
import 'index/analysis_service.dart';
import 'index/goal_service.dart';
import 'index/group_service.dart';
import 'index/home_service.dart';
import 'index/index_service.dart';
import 'index/month_wrap_service.dart';
import 'index/review_service.dart';
import 'index/session_service.dart';
import 'index/stats_service.dart';
import 'index/storage_service.dart';
import 'l10n/l10n.dart';
import 'platform/media_source.dart';
import 'platform/messages.g.dart' show PermissionState;
import 'platform/scan_foreground.dart';
import 'platform/system_settings.dart';

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

/// Storage map numbers. Recomputed each time the screen opens.
final storageProvider = FutureProvider.autoDispose<StorageData>((ref) => StorageService(ref.watch(databaseProvider)).load());

final sessionServiceProvider = Provider<SessionService>((ref) => SessionService(ref.watch(databaseProvider)));

/// Streak, week and month progress for the Cleanup session screen.
final sessionOverviewProvider = FutureProvider.autoDispose<SessionOverview>((ref) => ref.watch(sessionServiceProvider).overview());

/// Just the streak, for the entry card on the Timeline.
final streakProvider = FutureProvider.autoDispose<StreakInfo>((ref) => ref.watch(sessionServiceProvider).streak());

final statsServiceProvider = Provider<StatsService>((ref) => StatsService(ref.watch(databaseProvider)));

/// This week and the one before, for the Hub row and the Space card.
final weekSummaryProvider = FutureProvider.autoDispose<WeekReport>((ref) async {
  final stats = ref.watch(statsServiceProvider);
  final used = await SystemSettings.usedPercent();
  await stats.snapshot(usedPct: used);
  final book = await stats.book(goal: await ref.watch(sessionServiceProvider).goal(), usedNow: used);
  return book.week(0);
});

final monthWrapServiceProvider = Provider<MonthWrapService>((ref) => MonthWrapService(ref.watch(databaseProvider)));

/// The plan behind Free by goal, rebuilt each time the screen opens.
final goalPlanProvider = FutureProvider.autoDispose<GoalPlan>((ref) => GoalService(ref.watch(databaseProvider)).load());

/// Which tab of the app shell is showing (0 Clean, 1 Swipe, 2 Space, 3 Trash).
class ShellTab extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}

final shellTabProvider = NotifierProvider<ShellTab, int>(ShellTab.new);

/// 'auto' (the phone's language), 'en' or 'ru'. Kept in `scan_state`.
class LanguageController extends Notifier<String> {
  static const key = 'language';

  @override
  String build() {
    Future.microtask(_load);
    return 'auto';
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final row = await (db.select(db.scanState)..where((s) => s.key.equals(key))).getSingleOrNull();
    if (row != null && const ['auto', 'en', 'ru', 'it'].contains(row.value)) state = row.value;
  }

  Future<void> set(String v) async {
    state = v;
    final db = ref.read(databaseProvider);
    await db.into(db.scanState).insertOnConflictUpdate(ScanStateCompanion.insert(key: key, value: v));
  }
}

final languageProvider = NotifierProvider<LanguageController, String>(LanguageController.new);

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
      );
}

class LibraryController extends Notifier<LibraryState> {
  final _foreground = ScanForeground();

  @override
  LibraryState build() => const LibraryState();

  /// Whole scan (index -> hash -> duplicates -> groups), kept alive in the
  /// background by a foreground service for as long as it runs.
  Future<void> sync({bool full = false}) async {
    if (state.syncing || state.analyzing || state.verifying) return;
    await _foreground.start();
    try {
      await _sync(full: full);
    } finally {
      await _foreground.stop();
    }
  }

  Future<void> _sync({bool full = false}) async {
    state = state.copyWith(syncing: true, processed: 0);
    final index = ref.read(indexServiceProvider);
    final media = ref.read(mediaSourceProvider);
    try {
      final sw = Stopwatch()..start();
      final result = await index.sync(onProgress: (n) => state = state.copyWith(processed: n), full: full);
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
    } catch (e) {
      state = state.copyWith(syncing: false, error: e.toString());
      return;
    }
    await analyze();
  }

  /// Stage 2: hash everything not yet hashed; resumes after a restart.
  Future<void> analyze() async {
    if (state.analyzing) return;
    final svc = ref.read(analysisServiceProvider);
    try {
      final pending = await svc.pendingCount();
      final total = state.stats?.total ?? pending;
      state = state.copyWith(analyzing: true, analysisDone: 0, analysisTotal: pending, alreadyHashed: total - pending);
      final sw = Stopwatch()..start();
      await svc.run(onProgress: (done, tot) {
        state = state.copyWith(analysisDone: done, analysisTotal: tot);
        _foreground.update(done, tot, l10n.notifHashing(fmtNum(done), fmtNum(tot)));
      });
      final ms = sw.elapsedMilliseconds;
      final hs = await svc.stats();
      final sim = await svc.similarSummary();
      state = state.copyWith(analyzing: false, analysisMs: ms, hashStats: hs, similar: sim);
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
      await groups.hashExactCandidates(onProgress: (d, t) {
        state = state.copyWith(verifyDone: d, verifyTotal: t);
        _foreground.update(d, t, l10n.notifChecking(fmtNum(d), fmtNum(t)));
      });
      final built = await groups.rebuild();
      ref.invalidate(groupsProvider);
      ref.invalidate(trashSummaryProvider);
      ref.invalidate(homeProvider);
      state = state.copyWith(verifying: false, groupsBuilt: built);
    } catch (e) {
      state = state.copyWith(verifying: false, error: e.toString());
    }
  }
}

final libraryProvider = NotifierProvider<LibraryController, LibraryState>(LibraryController.new);
