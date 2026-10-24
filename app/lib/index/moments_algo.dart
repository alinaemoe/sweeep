import 'dart:math' as math;

/// Thresholds of the Moments algorithm. Change one and bump [algoVersion]:
/// stored events are rebuilt from scratch when the version differs.
class MomentsConfig {
  static const algoVersion = 1;

  /// A pause longer than this starts a new candidate event.
  static const gap = Duration(hours: 4);

  /// Candidates with fewer photos are not events.
  static const minPhotos = 12;

  /// Further than this from home counts as away; neighbouring away days are one trip.
  static const awayKm = 50.0;

  /// Pauses up to this are bridged while away.
  static const tripGap = Duration(hours: 18);

  /// 10..50 km is a weekend or a day trip.
  static const nearAwayKm = 10.0;

  /// Closer than this to home, after [eveningHour], is an evening at home.
  static const homeKm = 2.0;
  static const eveningHour = 17;

  /// Night window used to find the home cell: 22:00 to 07:00.
  static const nightFromHour = 22;
  static const nightToHour = 7;

  /// No home when fewer photos than this share of the library carry a place.
  static const minGeoShare = 0.2;

  /// Home cell size: two decimals of a degree, about 1 km.
  static const homeCellDecimals = 2;

  /// Stored places are rounded to three decimals, about 100 m.
  static const placeDecimals = 3;
}

class MomentPhoto {
  const MomentPhoto({required this.id, required this.t, required this.size, this.lat, this.lon});
  final String id;

  /// Capture time, epoch ms.
  final int t;
  final int size;
  final double? lat;
  final double? lon;

  bool get hasPlace => lat != null && lon != null;
}

class HomePoint {
  const HomePoint(this.lat, this.lon);
  final double lat;
  final double lon;
}

class DetectedEvent {
  const DetectedEvent({
    required this.startMs,
    required this.endMs,
    required this.ids,
    required this.bytes,
    required this.title,
    this.centerLat,
    this.centerLon,
    this.awayKm,
  });
  final int startMs;
  final int endMs;
  final List<String> ids;
  final int bytes;

  /// Code for the screen, see [momentTitleCode].
  final String title;
  final double? centerLat;
  final double? centerLon;
  final double? awayKm;
}

/// Rounds a coordinate to [MomentsConfig.placeDecimals] (about 100 m).
double roundPlace(double v) {
  final f = math.pow(10, MomentsConfig.placeDecimals);
  return (v * f).round() / f;
}

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

double _median(List<double> v) {
  final s = [...v]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// The most frequent ~1 km cell among night photos (22:00 to 07:00), or among all
/// photos when there are no night ones. Null when under 20% of [totalPhotos] have a place.
HomePoint? findHome(List<MomentPhoto> photos, {int? totalPhotos}) {
  final geo = photos.where((p) => p.hasPlace).toList();
  final total = totalPhotos ?? photos.length;
  if (geo.isEmpty || total == 0 || geo.length < total * MomentsConfig.minGeoShare) return null;
  bool night(MomentPhoto p) {
    final h = DateTime.fromMillisecondsSinceEpoch(p.t).hour;
    return h >= MomentsConfig.nightFromHour || h < MomentsConfig.nightToHour;
  }

  final nights = geo.where(night).toList();
  final pool = nights.isEmpty ? geo : nights;
  final f = math.pow(10, MomentsConfig.homeCellDecimals).toDouble();
  final cells = <(int, int), List<MomentPhoto>>{};
  for (final p in pool) {
    cells.putIfAbsent(((p.lat! * f).round(), (p.lon! * f).round()), () => []).add(p);
  }
  var best = cells.entries.first;
  for (final e in cells.entries) {
    if (e.value.length > best.value.length) best = e;
  }
  return HomePoint(_median([for (final p in best.value) p.lat!]), _median([for (final p in best.value) p.lon!]));
}

class _Cand {
  _Cand(this.photos);
  final List<MomentPhoto> photos;
  int get start => photos.first.t;
  int get end => photos.last.t;
  double? lat;
  double? lon;
  double? away;

  void measure(HomePoint? home) {
    final g = photos.where((p) => p.hasPlace).toList();
    if (g.isEmpty) {
      lat = lon = away = null;
      return;
    }
    lat = _median([for (final p in g) p.lat!]);
    lon = _median([for (final p in g) p.lon!]);
    away = home == null ? null : haversineKm(home.lat, home.lon, lat!, lon!);
  }
}

int _daysSpanned(int startMs, int endMs) {
  final a = DateTime.fromMillisecondsSinceEpoch(startMs);
  final b = DateTime.fromMillisecondsSinceEpoch(endMs);
  return DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays + 1;
}

/// The code of an event title. `trip:<days>:<km>`, `weekend:<km>`, `daytrip:<km>`,
/// `evening`, `date`; without a place: `w_days:<n>`, `w_weekend`, `w_evening`, `w_day`.
String momentTitleCode({required int startMs, required int endMs, double? awayKm}) {
  final start = DateTime.fromMillisecondsSinceEpoch(startMs);
  final days = _daysSpanned(startMs, endMs);
  if (awayKm != null) {
    final km = awayKm.round();
    if (awayKm >= MomentsConfig.awayKm) return 'trip:$days:$km';
    if (awayKm >= MomentsConfig.nearAwayKm) {
      return start.weekday >= DateTime.saturday ? 'weekend:$km' : 'daytrip:$km';
    }
    if (awayKm < MomentsConfig.homeKm && start.hour >= MomentsConfig.eveningHour) return 'evening';
    return 'date';
  }
  if (days > 1) return 'w_days:$days';
  if (start.weekday >= DateTime.saturday) return 'w_weekend';
  if (start.hour >= MomentsConfig.eveningHour) return 'w_evening';
  return 'w_day';
}

/// Cuts [photos] (any order; screenshots and recordings already left out) into events.
///
/// 1. a pause over [MomentsConfig.gap] starts a candidate;
/// 2. each candidate gets its median place and distance from [home];
/// 3. neighbouring candidates that are both over 50 km away and at most 18 h apart are one trip;
/// 4. what is left with fewer than 12 photos is dropped; the rest is named.
List<DetectedEvent> detectEvents(List<MomentPhoto> photos, {HomePoint? home}) {
  if (photos.isEmpty) return const [];
  final sorted = [...photos]..sort((a, b) => a.t.compareTo(b.t));
  final cands = <_Cand>[];
  var cur = <MomentPhoto>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i].t - sorted[i - 1].t > MomentsConfig.gap.inMilliseconds) {
      cands.add(_Cand(cur));
      cur = [];
    }
    cur.add(sorted[i]);
  }
  cands.add(_Cand(cur));
  for (final c in cands) {
    c.measure(home);
  }

  final merged = <_Cand>[];
  for (final c in cands) {
    final prev = merged.isEmpty ? null : merged.last;
    final bothAway = prev != null && (prev.away ?? 0) > MomentsConfig.awayKm && (c.away ?? 0) > MomentsConfig.awayKm;
    if (bothAway && c.start - prev.end <= MomentsConfig.tripGap.inMilliseconds) {
      final joined = _Cand([...prev.photos, ...c.photos])..measure(home);
      merged[merged.length - 1] = joined;
    } else {
      merged.add(c);
    }
  }

  return [
    for (final c in merged)
      if (c.photos.length >= MomentsConfig.minPhotos)
        DetectedEvent(
          startMs: c.start,
          endMs: c.end,
          ids: [for (final p in c.photos) p.id],
          bytes: c.photos.fold(0, (t, p) => t + p.size),
          title: momentTitleCode(startMs: c.start, endMs: c.end, awayKm: c.away),
          centerLat: c.lat,
          centerLon: c.lon,
          awayKm: c.away,
        ),
  ];
}
