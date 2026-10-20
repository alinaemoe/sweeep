import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// The daily "sweep a few photos" reminder: a local alarm, no server.
/// Android only for now; elsewhere every call quietly does nothing.
class Reminder {
  static const _ch = MethodChannel('app.sweeep/reminder');

  static Future<bool> hasPermission() async {
    try {
      return await _ch.invokeMethod<bool>('hasPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _ch.invokeMethod<bool>('requestPermission');
    } on MissingPluginException {
      // not on Android
    }
  }

  /// Arms the alarm for [minutes] after midnight, with today's language.
  static Future<void> schedule(int minutes) async {
    try {
      await _ch.invokeMethod<void>('schedule', {
        'minutes': minutes,
        'title': l10n.remNotifTitle,
        'body': l10n.remNotifBody,
        'channel': l10n.remChannel,
      });
    } on MissingPluginException {
      // not on Android
    }
  }

  static Future<void> cancel() async {
    try {
      await _ch.invokeMethod<void>('cancel');
    } on MissingPluginException {
      // not on Android
    }
  }
}
