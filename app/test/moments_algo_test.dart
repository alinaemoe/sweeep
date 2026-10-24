import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/index/moments_algo.dart';

const homeLat = 53.9;
const homeLon = 27.56;

var _n = 0;

/// [n] photos from [start], [stepMin] minutes apart.
List<MomentPhoto> burst(DateTime start, int n, {int stepMin = 5, double? lat, double? lon, int size = 1000}) => [
      for (var i = 0; i < n; i++) MomentPhoto(id: 'p${_n++}', t: start.add(Duration(minutes: stepMin * i)).millisecondsSinceEpoch, size: size, lat: lat, lon: lon),
    ];

void main() {
  const home = HomePoint(homeLat, homeLon);

  test('a pause of more than 4 hours splits, exactly 4 hours does not', () {
    final a = burst(DateTime(2026, 6, 6, 10), 12, stepMin: 1);
    final lastA = DateTime(2026, 6, 6, 10, 11);
    final exact = burst(lastA.add(const Duration(hours: 4)), 12, stepMin: 1);
    expect(detectEvents([...a, ...exact]).length, 1);
    final over = burst(lastA.add(const Duration(hours: 4, minutes: 1)), 12, stepMin: 1);
    expect(detectEvents([...a, ...over]).length, 2);
  });

  test('11 photos are not an event, 12 are', () {
    expect(detectEvents(burst(DateTime(2026, 6, 6, 10), 11)), isEmpty);
    expect(detectEvents(burst(DateTime(2026, 6, 6, 10), 12)).length, 1);
  });

  test('rare single photos never make an event', () {
    final rare = [for (var d = 1; d <= 20; d++) ...burst(DateTime(2026, 6, d, 12), 1)];
    expect(detectEvents(rare), isEmpty);
  });

  test('without any place the names are plain: day, evening, weekend, N days', () {
    String one(DateTime t) => detectEvents(burst(t, 12)).single.title;
    expect(one(DateTime(2026, 6, 3, 10)), 'w_day'); // Wednesday morning
    expect(one(DateTime(2026, 6, 3, 19)), 'w_evening');
    expect(one(DateTime(2026, 6, 6, 10)), 'w_weekend'); // Saturday
    final days = detectEvents([...burst(DateTime(2026, 6, 1, 10), 12, stepMin: 2), ...burst(DateTime(2026, 6, 2, 8), 12, stepMin: 2)]);
    // 21 h between the days: two events, each a plain day
    expect(days.map((e) => e.title), ['w_day', 'w_day']);
    final longDay = detectEvents(burst(DateTime(2026, 6, 1, 20), 24, stepMin: 60));
    expect(longDay.single.title, 'w_days:2');
    expect(longDay.single.awayKm, isNull);
  });

  test('a three day trip far from home is one event, days glued with pauses under 18 hours', () {
    final far = [
      ...burst(DateTime(2026, 5, 3, 10), 40, stepMin: 10, lat: 41.9, lon: 12.5),
      ...burst(DateTime(2026, 5, 4, 9), 40, stepMin: 10, lat: 41.9, lon: 12.5), // ~11 h pause
      ...burst(DateTime(2026, 5, 5, 8), 40, stepMin: 10, lat: 41.89, lon: 12.49),
    ];
    final e = detectEvents([...far, ...burst(DateTime(2026, 5, 1, 12), 12, lat: homeLat, lon: homeLon)], home: home);
    final trip = e.firstWhere((x) => x.title.startsWith('trip'));
    expect(trip.ids.length, 120);
    expect(trip.title.startsWith('trip:3:'), isTrue);
    expect(trip.awayKm! > 1000, isTrue);
  });

  test('away days with a pause over 18 hours are two trips', () {
    final far = [
      ...burst(DateTime(2026, 5, 3, 10), 20, stepMin: 10, lat: 41.9, lon: 12.5),
      ...burst(DateTime(2026, 5, 4, 14), 20, stepMin: 10, lat: 41.9, lon: 12.5), // ~24 h pause
    ];
    expect(detectEvents(far, home: home).length, 2);
  });

  test('a weekend 30 km away and a day trip 30 km away on a weekday', () {
    const lat = homeLat + 0.27; // about 30 km north
    final sat = detectEvents(burst(DateTime(2026, 6, 13, 11), 15, lat: lat, lon: homeLon), home: home).single;
    expect(sat.title, 'weekend:${sat.awayKm!.round()}');
    expect(sat.awayKm! > 25 && sat.awayKm! < 35, isTrue);
    final tue = detectEvents(burst(DateTime(2026, 6, 16, 11), 15, lat: lat, lon: homeLon), home: home).single;
    expect(tue.title, 'daytrip:${tue.awayKm!.round()}');
  });

  test('an evening at home after 17:00, a morning at home is a plain date', () {
    expect(detectEvents(burst(DateTime(2026, 8, 22, 19), 14, lat: homeLat, lon: homeLon), home: home).single.title, 'evening');
    expect(detectEvents(burst(DateTime(2026, 8, 22, 10), 14, lat: homeLat, lon: homeLon), home: home).single.title, 'date');
  });

  test('a place without a known home falls back to plain names', () {
    final e = detectEvents(burst(DateTime(2026, 6, 6, 10), 12, lat: 41.9, lon: 12.5)).single;
    expect(e.title, 'w_weekend');
    expect(e.centerLat, 41.9);
    expect(e.awayKm, isNull);
  });

  test('home is the busiest night cell, or none when under 20% have a place', () {
    final nights = [
      ...burst(DateTime(2026, 6, 1, 23), 30, stepMin: 1, lat: homeLat, lon: homeLon),
      ...burst(DateTime(2026, 6, 2, 12), 40, stepMin: 1, lat: 41.9, lon: 12.5), // day photos elsewhere
    ];
    final h = findHome(nights)!;
    expect((h.lat - homeLat).abs() < 0.01, isTrue);
    // 70 photos with a place out of 1000: 7%, no home
    expect(findHome(nights, totalPhotos: 1000), isNull);
    expect(findHome(burst(DateTime(2026, 6, 1, 12), 5)), isNull);
  });

  test('no night photos: the busiest cell of all', () {
    final day = [...burst(DateTime(2026, 6, 1, 12), 20, lat: homeLat, lon: homeLon), ...burst(DateTime(2026, 6, 2, 12), 5, lat: 41.9, lon: 12.5)];
    final h = findHome(day)!;
    expect((h.lat - homeLat).abs() < 0.01, isTrue);
  });

  test('places are rounded to about 100 m and distance is a real great circle', () {
    expect(roundPlace(53.90456), 53.905);
    expect((haversineKm(0, 0, 0, 1) - 111.19).abs() < 0.5, isTrue);
  });

  test('size and range of an event add up', () {
    final e = detectEvents(burst(DateTime(2026, 6, 3, 10), 12, size: 500)).single;
    expect(e.bytes, 6000);
    expect(e.endMs - e.startMs, 55 * 60 * 1000);
  });
}
