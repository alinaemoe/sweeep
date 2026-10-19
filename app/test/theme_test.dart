import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/core/theme.dart';

void main() {
  test('swipe word stretches with the gesture and is capped', () {
    expect(swipeWord(0), 'SWIPE');
    expect(swipeWord(13), 'SWIPE');
    expect(swipeWord(14), 'SWIIPE');
    expect(swipeWord(-28), 'SWIIIPE');
    expect(swipeWordIs(10000), 10);
  });
}
