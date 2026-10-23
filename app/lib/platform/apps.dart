import 'package:flutter/services.dart';

/// One installed app as the platform reports it.
class AppInfo {
  const AppInfo(
      {required this.package,
      required this.name,
      required this.size,
      required this.exact,
      required this.lastUsed,
      required this.installed});

  final String package;
  final String name;

  /// Bytes: app + data + cache with usage access, the apk files alone without.
  final int size;
  final bool exact;

  /// Last launch, epoch ms; 0 when Android has no record.
  final int lastUsed;
  final int installed;

  /// Whole days since the last launch (or since install when never launched).
  int daysSince(DateTime now) {
    final t = lastUsed > 0 ? lastUsed : installed;
    if (t <= 0) return 0;
    return now
        .difference(DateTime.fromMillisecondsSinceEpoch(t))
        .inDays
        .clamp(0, 100000);
  }

  factory AppInfo.fromMap(Map<Object?, Object?> m) => AppInfo(
        package: m['package']! as String,
        name: m['name']! as String,
        size: (m['size']! as num).toInt(),
        exact: m['exact']! as bool,
        lastUsed: (m['lastUsed']! as num).toInt(),
        installed: (m['installed']! as num).toInt(),
      );
}

/// Installed user apps, their icons, usage access and the system uninstall dialog.
class AppsPlatform {
  static const _ch = MethodChannel('app.sweeep/apps');

  static Future<bool> usageGranted() async {
    try {
      return await _ch.invokeMethod<bool>('usageGranted') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> openUsageSettings() async {
    try {
      return await _ch.invokeMethod<bool>('openUsageSettings') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<List<AppInfo>> list() async {
    try {
      final raw =
          await _ch.invokeListMethod<Map<Object?, Object?>>('list') ?? const [];
      return raw.map(AppInfo.fromMap).toList();
    } on MissingPluginException {
      return const [];
    }
  }

  static final Map<String, Future<Uint8List?>> _icons = {};

  /// PNG of the launcher icon, cached for the session.
  static Future<Uint8List?> icon(String package) =>
      _icons.putIfAbsent(package, () async {
        try {
          return await _ch
              .invokeMethod<Uint8List>('icon', {'package': package});
        } on MissingPluginException {
          return null;
        }
      });

  /// Opens the system uninstall dialog; true when the app is gone afterwards.
  static Future<bool> uninstall(String package) async {
    try {
      return await _ch.invokeMethod<bool>('uninstall', {'package': package}) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }
}
