import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweeep/l10n/app_localizations.dart';

void main() {
  Map<String, dynamic> arb(String lang) => jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

  test('Russian has exactly the keys English has', () {
    final en = arb('en').keys.where((k) => !k.startsWith('@')).toSet();
    final ru = arb('ru').keys.where((k) => !k.startsWith('@')).toSet();
    expect(ru.difference(en), isEmpty);
    expect(en.difference(ru), isEmpty);
  });

  test('plural forms follow each language', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect([1, 2, 5].map(en.filesCount), ['1 file', '2 files', '5 files']);
    expect([1, 2, 5, 11, 21, 22, 25].map(ru.filesCount), ['1 файл', '2 файла', '5 файлов', '11 файлов', '21 файл', '22 файла', '25 файлов']);
    expect([1, 3, 12].map(ru.groupsCount), ['1 группа', '3 группы', '12 групп']);
  });

  test('placeholders are filled in both languages', () {
    for (final lang in ['en', 'ru']) {
      final l = lookupAppLocalizations(Locale(lang));
      expect(l.pagerTrashN(2, '3 MB'), allOf(contains('2'), contains('3 MB')));
      expect(l.swipeOf(3, 9), allOf(contains('3'), contains('9')));
      expect(l.trashDeleteBody('2 files', '1 MB'), allOf(contains('2 files'), contains('1 MB')));
    }
  });
}
