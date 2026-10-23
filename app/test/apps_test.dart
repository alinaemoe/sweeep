import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/platform/apps.dart';

AppInfo _app({int lastUsed = 0, int installed = 0}) => AppInfo(package: 'p', name: 'n', size: 1, exact: true, lastUsed: lastUsed, installed: installed);

void main() {
  final now = DateTime(2026, 10, 23, 12);

  test('days count from the last launch, or from install when there is none', () {
    expect(_app(lastUsed: now.subtract(const Duration(days: 94)).millisecondsSinceEpoch).daysSince(now), 94);
    expect(_app(installed: now.subtract(const Duration(days: 12)).millisecondsSinceEpoch).daysSince(now), 12);
    expect(_app(lastUsed: now.subtract(const Duration(days: 3)).millisecondsSinceEpoch, installed: 1).daysSince(now), 3);
  });

  test('no dates at all means zero days, and the future never goes negative', () {
    expect(_app().daysSince(now), 0);
    expect(_app(lastUsed: now.add(const Duration(days: 2)).millisecondsSinceEpoch).daysSince(now), 0);
  });

  test('fromMap reads what the platform sends', () {
    final a = AppInfo.fromMap({'package': 'a.b', 'name': 'AB', 'size': 5, 'exact': false, 'lastUsed': 0, 'installed': 7});
    expect((a.package, a.name, a.size, a.exact, a.installed), ('a.b', 'AB', 5, false, 7));
  });
}
