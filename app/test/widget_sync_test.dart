import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/data/database.dart';
import 'package:sweeep/index/widget_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SweeepDatabase db;
  Map<Object?, Object?>? saved;

  setUp(() {
    db = SweeepDatabase(NativeDatabase.memory());
    saved = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('app.sweeep/widgets'), (call) async {
      if (call.method == 'save') saved = call.arguments as Map<Object?, Object?>;
      return true;
    });
  });
  tearDown(() => db.close());

  Future<void> decide(String id, int at) async {
    await db.into(db.assets).insert(AssetsCompanion.insert(id: id, mediaType: 0, width: 1, height: 1, sizeBytes: 10, createdAtMs: 1, modifiedAtMs: 1));
    await db.into(db.decisions).insert(DecisionsCompanion.insert(assetId: id, decision: 0, decidedAtMs: at));
  }

  final now = DateTime(2026, 10, 23, 15);

  test('an empty library writes zero progress, a day key and only numbers and words', () async {
    await WidgetSync(db).refresh(now: now);
    expect(saved!['day'], '2026-10-23');
    expect(saved!['done'], 0);
    expect(saved!['goal'], 50);
    expect(saved!['streak'], 0);
    expect(saved!['tOf'], '/ 50 today');
    expect(saved!['tLeftNow'], '50 left for a 1-day streak');
    expect(saved!.keys.where((k) => '$k'.toLowerCase().contains('path') || '$k'.toLowerCase().contains('name')), isEmpty);
  });

  test('today counts only today, the streak counts yesterday too, and left text follows', () async {
    await decide('a', DateTime(2026, 10, 22, 10).millisecondsSinceEpoch);
    await decide('b', DateTime(2026, 10, 23, 9).millisecondsSinceEpoch);
    await decide('c', DateTime(2026, 10, 23, 11).millisecondsSinceEpoch);
    await WidgetSync(db).refresh(now: now);
    expect(saved!['done'], 2);
    expect(saved!['streak'], 2);
    expect(saved!['tLeftNow'], '48 left for today\'s goal');
    // what the widget falls back to after midnight, before the app runs again
    expect(saved!['tLeftNew'], '50 left for a 3-day streak');
    expect(saved!['tStreak'], '2 day streak');
  });
}
