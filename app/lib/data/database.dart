import 'package:drift/drift.dart';

part 'database.g.dart';

/// Month / newest-first queries (Timeline, Swipe queue, categories) range-scan this.
@TableIndex(name: 'idx_assets_type_created', columns: {#mediaType, #createdAtMs})
/// One row per media item known to the index. `id` is the platform asset id
/// (PHAsset.localIdentifier / MediaStore id). Never the file path.
class Assets extends Table {
  TextColumn get id => text()();
  IntColumn get mediaType => integer()(); // 0 photo, 1 video
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get sizeBytes => integer()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get modifiedAtMs => integer()();
  TextColumn get bucket => text().nullable()(); // album / folder
  BoolColumn get isScreenshot => boolean().withDefault(const Constant(false))();
  BoolColumn get isScreenRecording => boolean().withDefault(const Constant(false))();
  TextColumn get chatSource => text().nullable()(); // telegram, whatsapp, ...

  /// Where the photo was taken, rounded to about 100 m. Only filled when the
  /// user allows places in Moments; null otherwise. `geoState`: 0 not read yet,
  /// 1 has a place, 2 read and none.
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();
  IntColumn get geoState => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Analysis results. 64-bit hashes are stored as signed ints
/// (reinterpret the u64 bit pattern from the Rust core).
class Hashes extends Table {
  TextColumn get assetId => text().references(Assets, #id, onDelete: KeyAction.cascade)();
  IntColumn get phash => integer().nullable()();
  IntColumn get dhash => integer().nullable()();
  IntColumn get ahash => integer().nullable()();
  RealColumn get laplacianVar => real().nullable()();
  IntColumn get medianBrightness => integer().nullable()();
  BlobColumn get sha256 => blob().nullable()();
  IntColumn get analyzedAtMs => integer()();
  IntColumn get analysisVersion => integer()(); // bump to force re-analysis

  @override
  Set<Column> get primaryKey => {assetId};
}

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kind => integer()(); // 0 duplicate, 1 similar, 2 video, 3 screenshot
  TextColumn get bestAssetId => text().nullable()();
  IntColumn get savingsBytes => integer()();
  IntColumn get createdAtMs => integer()();
}

class GroupMembers extends Table {
  IntColumn get groupId => integer().references(Groups, #id, onDelete: KeyAction.cascade)();
  TextColumn get assetId => text().references(Assets, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {groupId, assetId};
}

/// Swipe / review decisions (kept or trashed), used for progress and Undo.
class Decisions extends Table {
  TextColumn get assetId => text().references(Assets, #id, onDelete: KeyAction.cascade)();
  IntColumn get decision => integer()(); // 0 keep, 1 trash
  IntColumn get decidedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {assetId};
}

/// The soft "App Trash Bin": ids only, originals are never copied.
class TrashItems extends Table {
  TextColumn get assetId => text().references(Assets, #id, onDelete: KeyAction.cascade)();
  IntColumn get sizeBytes => integer()();
  IntColumn get trashedAtMs => integer()();
  IntColumn get expiresAtMs => integer()(); // default trashedAt + 30 days
  IntColumn get reason => integer()(); // 0 swipe, 1 group, 2 category

  @override
  Set<Column> get primaryKey => {assetId};
}

/// One finished Cleanup session (for the done screen and later history).
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startedMs => integer()();
  IntColumn get endedMs => integer()();
  IntColumn get goal => integer()();
  IntColumn get swept => integer()();
  IntColumn get trashed => integer()();
  IntColumn get bytes => integer()(); // size of what went to the app trash

}

/// Per-day totals that outlive the files: deleting a photo for good removes its
/// decision row, so the weekly report reads these instead. Rows only ever grow
/// (see StatsService.snapshot), `usedPct` is the phone storage seen that day.
class DailyStats extends Table {
  TextColumn get day => text()(); // local date, YYYY-MM-DD
  IntColumn get swept => integer().withDefault(const Constant(0))();
  IntColumn get kept => integer().withDefault(const Constant(0))();
  IntColumn get clearedFiles => integer().withDefault(const Constant(0))();
  IntColumn get clearedBytes => integer().withDefault(const Constant(0))();
  IntColumn get sessions => integer().withDefault(const Constant(0))();
  IntColumn get catDups => integer().withDefault(const Constant(0))();
  IntColumn get catSimilar => integer().withDefault(const Constant(0))();
  IntColumn get catShots => integer().withDefault(const Constant(0))();
  IntColumn get catBlurry => integer().withDefault(const Constant(0))();
  IntColumn get catOther => integer().withDefault(const Constant(0))();
  IntColumn get usedPct => integer().nullable()();

  @override
  Set<Column> get primaryKey => {day};
}

/// A Moment: photos close in time (and place). `title` is a code the screen
/// turns into words ('trip:4:62', 'weekend:30', 'evening', 'w_days:3', ...),
/// `userTitle` is what the user typed.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
  TextColumn get title => text()();
  TextColumn get userTitle => text().nullable()();
  RealColumn get centerLat => real().nullable()();
  RealColumn get centerLon => real().nullable()();
  RealColumn get awayKm => real().nullable()();
  IntColumn get count => integer()();
  IntColumn get bytes => integer()();
}

/// Which event a photo belongs to (at most one).
class EventMembers extends Table {
  TextColumn get assetId => text().references(Assets, #id, onDelete: KeyAction.cascade)();
  IntColumn get eventId => integer().references(Events, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {assetId};
}

/// Key/value for scan checkpoints (cursor, last full scan, thresholds hash).
class ScanState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Assets, Hashes, Groups, GroupMembers, Decisions, TrashItems, ScanState, Sessions, DailyStats, Events, EventMembers])
class SweeepDatabase extends _$SweeepDatabase {
  SweeepDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createIndex(idxAssetsTypeCreated);
          if (from < 3) await m.createTable(sessions);
          if (from < 4) {
            await m.createTable(dailyStats);
            // history that can still be read: swept, kept, trashed files and their bytes
            await customStatement(statsSnapshotSql);
            await customStatement(statsSessionsSql);
          }
          if (from < 5) {
            await m.addColumn(assets, assets.lat);
            await m.addColumn(assets, assets.lon);
            await m.addColumn(assets, assets.geoState);
            await m.createTable(events);
            await m.createTable(eventMembers);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Upserts one row per day from the live decisions. Counts only grow
/// (max with what is stored), because deleting a file for good drops its
/// decision and the day must not shrink then.
const statsSnapshotSql = '''
INSERT INTO daily_stats (day, swept, kept, cleared_files, cleared_bytes, cat_dups, cat_similar, cat_shots, cat_blurry, cat_other)
SELECT strftime('%Y-%m-%d', d.decided_at_ms / 1000, 'unixepoch', 'localtime') AS day,
       COUNT(*) AS swept,
       SUM(CASE WHEN d.decision = 0 THEN 1 ELSE 0 END) AS kept,
       SUM(CASE WHEN d.decision = 1 THEN 1 ELSE 0 END) AS cleared_files,
       COALESCE(SUM(CASE WHEN d.decision = 1 THEN a.size_bytes ELSE 0 END), 0) AS cleared_bytes,
       SUM(CASE WHEN d.decision = 1 AND a.id IN (SELECT gm.asset_id FROM group_members gm JOIN groups g ON g.id = gm.group_id WHERE g.kind = 0) THEN 1 ELSE 0 END),
       SUM(CASE WHEN d.decision = 1 AND a.id NOT IN (SELECT gm.asset_id FROM group_members gm JOIN groups g ON g.id = gm.group_id WHERE g.kind = 0)
                 AND a.id IN (SELECT gm.asset_id FROM group_members gm JOIN groups g ON g.id = gm.group_id WHERE g.kind = 1) THEN 1 ELSE 0 END),
       SUM(CASE WHEN d.decision = 1 AND a.is_screenshot = 1
                 AND a.id NOT IN (SELECT asset_id FROM group_members) THEN 1 ELSE 0 END),
       SUM(CASE WHEN d.decision = 1 AND a.is_screenshot = 0 AND a.id NOT IN (SELECT asset_id FROM group_members)
                 AND a.id IN (SELECT asset_id FROM hashes WHERE laplacian_var < 250 OR median_brightness < 40) THEN 1 ELSE 0 END),
       SUM(CASE WHEN d.decision = 1 AND a.id NOT IN (SELECT asset_id FROM group_members) AND a.is_screenshot = 0
                 AND a.id NOT IN (SELECT asset_id FROM hashes WHERE laplacian_var < 250 OR median_brightness < 40) THEN 1 ELSE 0 END)
FROM decisions d JOIN assets a ON a.id = d.asset_id
GROUP BY day
ON CONFLICT(day) DO UPDATE SET
  swept = MAX(swept, excluded.swept), kept = MAX(kept, excluded.kept),
  cleared_files = MAX(cleared_files, excluded.cleared_files), cleared_bytes = MAX(cleared_bytes, excluded.cleared_bytes),
  cat_dups = MAX(cat_dups, excluded.cat_dups), cat_similar = MAX(cat_similar, excluded.cat_similar),
  cat_shots = MAX(cat_shots, excluded.cat_shots), cat_blurry = MAX(cat_blurry, excluded.cat_blurry),
  cat_other = MAX(cat_other, excluded.cat_other)
''';

/// Cleanup sessions per day (the table keeps its own rows).
const statsSessionsSql = '''
INSERT INTO daily_stats (day, sessions)
SELECT strftime('%Y-%m-%d', ended_ms / 1000, 'unixepoch', 'localtime') AS day, COUNT(*) AS n FROM sessions GROUP BY day
ON CONFLICT(day) DO UPDATE SET sessions = MAX(sessions, excluded.sessions)
''';

/// Reinterpret between the core's u64 hashes and SQLite's signed ints.
int hashToDb(BigInt u64) => u64.toSigned(64).toInt();
BigInt hashFromDb(int v) => BigInt.from(v).toUnsigned(64);
