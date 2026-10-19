import 'package:drift/drift.dart';

part 'database.g.dart';

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

/// Key/value for scan checkpoints (cursor, last full scan, thresholds hash).
class ScanState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Assets, Hashes, Groups, GroupMembers, Decisions, TrashItems, ScanState])
class SweeepDatabase extends _$SweeepDatabase {
  SweeepDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Reinterpret between the core's u64 hashes and SQLite's signed ints.
int hashToDb(BigInt u64) => u64.toSigned(64).toInt();
BigInt hashFromDb(int v) => BigInt.from(v).toUnsigned(64);
