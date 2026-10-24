import 'package:drift/drift.dart' hide isNull, isNotNull;

import '../data/database.dart';
import '../platform/places.dart';
import 'moments_algo.dart';

/// One event with what the list shows.
class MomentView {
  const MomentView({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.title,
    required this.userTitle,
    required this.count,
    required this.bytes,
    required this.awayKm,
    required this.best,
    required this.twins,
    required this.tiles,
  });
  final int id;
  final int startMs;
  final int endMs;

  /// Code from [momentTitleCode].
  final String title;
  final String? userTitle;
  final int count;
  final int bytes;
  final double? awayKm;

  /// Similar-photo series in this event (one sharpest frame each is suggested).
  final int best;

  /// Photos of the event that sit in a similar group besides its best one.
  final int twins;

  /// Up to four photo ids; the first is the sharpest frame.
  final List<String> tiles;
}

/// Events (Moments): built from capture time and, when the user allows it, the place.
/// Everything stays in the app database.
class MomentsService {
  MomentsService(this.db);
  final SweeepDatabase db;

  static const placesKey = 'moments_places';
  static const _algoKey = 'events_algo';
  static const _homeKey = 'events_home';
  static const _headKey = 'events_head';
  static const _geoChunk = 250;

  static const _eligible = 'a.is_screenshot = 0 AND a.is_screen_recording = 0';

  Future<String?> _pref(String key) async => (await (db.select(db.scanState)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setPref(String key, String value) => db.into(db.scanState).insertOnConflictUpdate(ScanStateCompanion.insert(key: key, value: value));

  /// null: not asked yet, true/false: the user's choice.
  Future<bool?> placesOn() async {
    final v = await _pref(placesKey);
    return v == null ? null : v == '1';
  }

  /// Turning places off forgets every stored coordinate.
  Future<void> setPlaces(bool on) async {
    await _setPref(placesKey, on ? '1' : '0');
    if (!on) {
      await db.customStatement('UPDATE assets SET lat = NULL, lon = NULL, geo_state = 0');
      await recompute(full: true);
    }
  }

  /// Reads the place of photos not read yet (a chunk at a time). Returns how many got a place.
  Future<int> scanPlaces({void Function(int done)? onProgress}) async {
    if (await placesOn() != true || !await Places.hasPermission()) return 0;
    var found = 0;
    var done = 0;
    while (true) {
      final rows = await db.customSelect(
        'SELECT a.id AS id FROM assets a WHERE a.media_type = 0 AND $_eligible AND a.geo_state = 0 LIMIT $_geoChunk',
      ).get();
      if (rows.isEmpty) break;
      final ids = [for (final r in rows) r.read<String>('id')];
      final got = await Places.read(ids);
      await db.batch((b) {
        for (final id in ids) {
          final p = got[id];
          if (p == null) {
            b.customStatement('UPDATE assets SET geo_state = 2 WHERE id = ?', [id]);
          } else {
            b.customStatement('UPDATE assets SET lat = ?, lon = ?, geo_state = 1 WHERE id = ?', [roundPlace(p[0]), roundPlace(p[1]), id]);
          }
        }
      });
      found += got.length;
      done += ids.length;
      onProgress?.call(done);
    }
    return found;
  }

  Future<List<MomentPhoto>> _photos({required int fromMs, bool onlyPlaced = false}) async {
    final rows = await db.customSelect(
      'SELECT a.id AS id, a.created_at_ms AS t, a.size_bytes AS size, a.lat AS lat, a.lon AS lon FROM assets a '
      'WHERE $_eligible AND a.created_at_ms >= ? ${onlyPlaced ? 'AND a.lat IS NOT NULL' : ''} ORDER BY a.created_at_ms',
      variables: [Variable.withInt(fromMs)],
    ).get();
    return [
      for (final r in rows)
        MomentPhoto(id: r.read<String>('id'), t: r.read<int>('t'), size: r.read<int>('size'), lat: r.read<double?>('lat'), lon: r.read<double?>('lon')),
    ];
  }

  Future<int> _eligibleBefore(int ms) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM assets a WHERE $_eligible AND a.created_at_ms < ?', variables: [Variable.withInt(ms)]).getSingle()).read<int>('n');

  /// Rebuilds the events. Normally only the tail (the last two events and what came after);
  /// everything when [full], when the algorithm version or the home changed, or when old
  /// photos appeared or went. Returns the number of events stored.
  Future<int> recompute({bool full = false}) async {
    final places = await placesOn() == true;
    final total = (await db.customSelect('SELECT COUNT(*) AS n FROM assets a WHERE $_eligible').getSingle()).read<int>('n');
    final placed = places ? await _photos(fromMs: 0, onlyPlaced: true) : <MomentPhoto>[];
    final home = places ? findHome(placed, totalPhotos: total) : null;
    final homeStr = home == null ? '' : '${home.lat.toStringAsFixed(3)},${home.lon.toStringAsFixed(3)}';

    final lastEvents = await (db.select(db.events)..orderBy([(e) => OrderingTerm.desc(e.startMs)])..limit(2)).get();
    var tailStart = 0;
    var doFull = full || lastEvents.isEmpty || await _pref(_algoKey) != '${MomentsConfig.algoVersion}' || await _pref(_homeKey) != homeStr;
    if (!doFull) {
      tailStart = lastEvents.last.startMs;
      if (await _eligibleBefore(tailStart) != int.tryParse(await _pref(_headKey) ?? '')) {
        doFull = true;
        tailStart = 0;
      }
    }

    final photos = await _photos(fromMs: tailStart);
    final events = detectEvents(photos, home: home);
    await db.transaction(() async {
      await (db.delete(db.events)..where((e) => e.startMs.isBiggerOrEqualValue(tailStart))).go();
      for (final e in events) {
        final id = await db.into(db.events).insert(EventsCompanion.insert(
              startMs: e.startMs,
              endMs: e.endMs,
              title: e.title,
              centerLat: Value(e.centerLat),
              centerLon: Value(e.centerLon),
              awayKm: Value(e.awayKm),
              count: e.ids.length,
              bytes: e.bytes,
            ));
        await db.batch((b) {
          b.insertAll(db.eventMembers, [for (final a in e.ids) EventMembersCompanion.insert(assetId: a, eventId: id)], mode: InsertMode.insertOrReplace);
        });
      }
    });
    await _setPref(_algoKey, '${MomentsConfig.algoVersion}');
    await _setPref(_homeKey, homeStr);
    // what the next tail run will compare against: photos before the start of the second-last event
    final now = await (db.select(db.events)..orderBy([(e) => OrderingTerm.desc(e.startMs)])..limit(2)).get();
    await _setPref(_headKey, '${now.isEmpty ? 0 : await _eligibleBefore(now.last.startMs)}');
    return (await db.customSelect('SELECT COUNT(*) AS n FROM events').getSingle()).read<int>('n');
  }

  /// Places first (when allowed), then the events. Safe to call often.
  Future<void> refresh() async {
    await scanPlaces();
    await recompute();
  }

  Future<int> eventCount() async => (await db.customSelect('SELECT COUNT(*) AS n FROM events').getSingle()).read<int>('n');

  /// Events, newest first, [limit] at a time.
  Future<List<MomentView>> list({int limit = 12, int offset = 0}) async {
    final rows = await (db.select(db.events)
          ..orderBy([(e) => OrderingTerm.desc(e.startMs)])
          ..limit(limit, offset: offset))
        .get();
    return [for (final e in rows) await _view(e)];
  }

  Future<MomentView?> byId(int id) async {
    final e = await (db.select(db.events)..where((x) => x.id.equals(id))).getSingleOrNull();
    return e == null ? null : _view(e);
  }

  Future<MomentView> _view(Event e) async {
    final groups = await db.customSelect('''
      SELECT g.id AS gid, COUNT(*) AS n
      FROM event_members em JOIN group_members gm ON gm.asset_id = em.asset_id JOIN groups g ON g.id = gm.group_id
      WHERE em.event_id = ? AND g.kind IN (0, 1)
      GROUP BY g.id HAVING n >= 2
    ''', variables: [Variable.withInt(e.id)]).get();
    var twins = 0;
    for (final g in groups) {
      twins += g.read<int>('n') - 1;
    }
    final tiles = <String>[];
    final sharp = await db.customSelect('''
      SELECT em.asset_id AS id FROM event_members em JOIN hashes h ON h.asset_id = em.asset_id JOIN assets a ON a.id = em.asset_id
      WHERE em.event_id = ? AND a.media_type = 0 AND h.laplacian_var IS NOT NULL ORDER BY h.laplacian_var DESC LIMIT 1
    ''', variables: [Variable.withInt(e.id)]).get();
    if (sharp.isNotEmpty) tiles.add(sharp.first.read<String>('id'));
    for (var k = 1; k <= 3; k++) {
      final off = (e.count * k / 4).floor();
      final r = await db.customSelect('''
        SELECT em.asset_id AS id FROM event_members em JOIN assets a ON a.id = em.asset_id
        WHERE em.event_id = ? ORDER BY a.created_at_ms LIMIT 1 OFFSET $off
      ''', variables: [Variable.withInt(e.id)]).get();
      if (r.isNotEmpty && !tiles.contains(r.first.read<String>('id'))) tiles.add(r.first.read<String>('id'));
    }
    if (tiles.isEmpty) {
      final r = await db.customSelect('SELECT asset_id AS id FROM event_members WHERE event_id = ? LIMIT 4', variables: [Variable.withInt(e.id)]).get();
      tiles.addAll([for (final x in r) x.read<String>('id')]);
    }
    return MomentView(
      id: e.id,
      startMs: e.startMs,
      endMs: e.endMs,
      title: e.title,
      userTitle: e.userTitle,
      count: e.count,
      bytes: e.bytes,
      awayKm: e.awayKm,
      best: groups.length,
      twins: twins,
      tiles: tiles.take(4).toList(),
    );
  }

  /// An empty or blank name goes back to the generated one.
  Future<void> rename(int id, String? name) async {
    final v = name?.trim();
    await (db.update(db.events)..where((e) => e.id.equals(id))).write(EventsCompanion(userTitle: Value(v == null || v.isEmpty ? null : v)));
  }

  /// A number for the Hub row: how many events, how many with a place.
  Future<({int events, int withPlace})> stats() async {
    final r = await db.customSelect('SELECT COUNT(*) AS n, COALESCE(SUM(center_lat IS NOT NULL), 0) AS g FROM events').getSingle();
    return (events: r.read<int>('n'), withPlace: r.read<int>('g'));
  }
}
