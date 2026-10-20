import '../data/database.dart';
import 'group_service.dart';
import 'storage_service.dart';

/// One tile in a category carousel.
class HomeItem {
  const HomeItem({required this.id, required this.sizeBytes, this.durationMs, this.tag});
  final String id;
  final int sizeBytes;
  final int? durationMs;

  /// 'blurry' / 'dark' for the Blurry & dark carousel.
  final String? tag;
}

/// Count + bytes + a few preview tiles for one category.
class HomeCategory {
  const HomeCategory({required this.count, required this.bytes, required this.items});
  final int count;
  final int bytes;
  final List<HomeItem> items;

  static const empty = HomeCategory(count: 0, bytes: 0, items: []);
}

class HomeData {
  const HomeData({
    required this.libraryBytes,
    required this.libraryCount,
    required this.duplicates,
    required this.duplicateCount,
    required this.duplicateBytes,
    required this.similar,
    required this.similarCount,
    required this.similarBytes,
    required this.screenshots,
    required this.screenRecordings,
    required this.videos,
    required this.blurry,
    required this.chat,
    this.safeBytes = 0,
  });

  final int libraryBytes;
  final int libraryCount;
  /// The first groups of each kind (biggest saving first), enough for the
  /// carousels; the counts and bytes cover all of them.
  final List<GroupView> duplicates;
  final int duplicateCount;
  final int duplicateBytes;
  final List<GroupView> similar;
  final int similarCount;
  final int similarBytes;
  final HomeCategory screenshots;
  final HomeCategory screenRecordings;
  final HomeCategory videos;
  final HomeCategory blurry;
  final HomeCategory chat;

  /// Everything the Storage map calls safe to clear (quick wins + extras of
  /// duplicate and similar groups). This is the number in the oval.
  final int safeBytes;

  int get reclaimableBytes => safeBytes;
}

/// Read-only queries behind the Home feed. Everything already in the app
/// trash is excluded.
class HomeService {
  HomeService(this.db, this.groups);

  final SweeepDatabase db;
  final GroupService groups;

  /// Laplacian variance (128 px thumbnail) below this = blurry. The p10 on the
  /// dev phone was ~540, so 250 catches only clearly soft shots.
  static const blurBelow = 250.0;

  /// Median brightness (0-255) below this = dark.
  static const darkBelow = 40;

  static const previewCount = 14;

  /// Groups handed to the Home carousels.
  static const groupPreview = 30;

  Future<HomeData> load() async {
    final lib = await db.customSelect('SELECT COUNT(*) AS n, COALESCE(SUM(size_bytes), 0) AS b FROM assets').getSingle();
    final dup = await groups.groupTotals(GroupKind.duplicate);
    final sim = await groups.groupTotals(GroupKind.similar);
    final safe = await db.customSelect('SELECT COALESCE(SUM(a.size_bytes), 0) AS b FROM assets a WHERE ${safeWhere(DateTime.now().millisecondsSinceEpoch)}').getSingle();
    return HomeData(
      safeBytes: safe.read<int>('b'),
      libraryCount: lib.read<int>('n'),
      libraryBytes: lib.read<int>('b'),
      duplicates: await groups.groups(GroupKind.duplicate, limit: groupPreview),
      duplicateCount: dup.count,
      duplicateBytes: dup.savings,
      similar: await groups.groups(GroupKind.similar, limit: groupPreview),
      similarCount: sim.count,
      similarBytes: sim.savings,
      screenshots: await _category('a.is_screenshot = 1 AND a.media_type = 0', 'a.created_at_ms DESC'),
      screenRecordings: await _category('a.media_type = 1 AND a.is_screen_recording = 1', 'a.size_bytes DESC', withDuration: true),
      videos: await _category('a.media_type = 1 AND a.is_screen_recording = 0', 'a.size_bytes DESC', withDuration: true),
      blurry: await _blurry(),
      chat: await _category('a.chat_source IS NOT NULL', 'a.created_at_ms DESC', withDuration: true),
    );
  }

  static const _notTrashed = 'a.id NOT IN (SELECT asset_id FROM trash_items)';

  Future<HomeCategory> _category(String where, String order, {bool withDuration = false}) async {
    final total = await db.customSelect('SELECT COUNT(*) AS n, COALESCE(SUM(a.size_bytes), 0) AS b FROM assets a WHERE $where AND $_notTrashed').getSingle();
    final rows = await db.customSelect(
      'SELECT a.id AS id, a.size_bytes AS size, a.duration_ms AS dur FROM assets a WHERE $where AND $_notTrashed ORDER BY $order LIMIT $previewCount',
    ).get();
    return HomeCategory(
      count: total.read<int>('n'),
      bytes: total.read<int>('b'),
      items: [
        for (final r in rows) HomeItem(id: r.read<String>('id'), sizeBytes: r.read<int>('size'), durationMs: withDuration ? r.read<int?>('dur') : null),
      ],
    );
  }

  Future<HomeCategory> _blurry() async {
    const from = '''
      FROM assets a JOIN hashes h ON h.asset_id = a.id
      WHERE a.media_type = 0 AND a.is_screenshot = 0 AND $_notTrashed
        AND ((h.laplacian_var IS NOT NULL AND h.laplacian_var < $blurBelow) OR (h.median_brightness IS NOT NULL AND h.median_brightness < $darkBelow))
    ''';
    final total = await db.customSelect('SELECT COUNT(*) AS n, COALESCE(SUM(a.size_bytes), 0) AS b $from').getSingle();
    final rows = await db.customSelect('''
      SELECT a.id AS id, a.size_bytes AS size,
             CASE WHEN h.median_brightness < $darkBelow THEN 'dark' ELSE 'blurry' END AS tag
      $from ORDER BY a.created_at_ms DESC LIMIT $previewCount
    ''').get();
    return HomeCategory(
      count: total.read<int>('n'),
      bytes: total.read<int>('b'),
      items: [for (final r in rows) HomeItem(id: r.read<String>('id'), sizeBytes: r.read<int>('size'), tag: r.read<String>('tag'))],
    );
  }
}
