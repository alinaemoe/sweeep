import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The strings for the language the app is showing right now. Bound once per
/// build of the app root (see `main.dart`), so plain helpers without a
/// BuildContext (`filesLabel`, `formatBytes`, ...) can use it too.
AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

AppLocalizations get l10n => _current;

void bindL10n(BuildContext context) => _current = AppLocalizations.of(context);

String get _loc => _current.localeName;

/// 12,345 / 12 345 (language aware), with [digits] decimals.
String fmtNum(num v, {int digits = 0}) => NumberFormat.decimalPatternDigits(locale: _loc, decimalDigits: digits).format(v);

/// 20 Oct 2026 / 20 окт. 2026 г.
String fmtDate(DateTime d) => DateFormat.yMMMd(_loc).format(d);

/// 20 Oct / 20 окт.
String fmtDayMonth(DateTime d) => DateFormat.MMMd(_loc).format(d);

/// October 2026 / Октябрь 2026
String fmtMonth(int year, int month) {
  final s = DateFormat('LLLL y', _loc).format(DateTime(year, month));
  return s[0].toUpperCase() + s.substring(1);
}
