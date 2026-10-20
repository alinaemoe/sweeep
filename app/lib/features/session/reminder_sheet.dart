import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../index/session_service.dart';
import '../../l10n/l10n.dart';
import '../../platform/reminder.dart';
import '../../providers.dart';

Future<void> showReminderSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: SweeepColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _ReminderSheet(),
    );

/// Puts the saved reminder back after an app start (new language, new alarm).
Future<void> applyReminder(SessionService svc) async {
  if (!await svc.reminderOn() || !await Reminder.hasPermission()) return;
  await Reminder.schedule(await svc.reminderMinutes());
}

class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet();

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> with WidgetsBindingObserver {
  bool _on = false;
  bool _allowed = true;
  int _minutes = SessionService.defaultReminderMinutes;

  SessionService get _svc => ref.read(sessionServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // back from the system permission dialog
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final on = await _svc.reminderOn();
    final minutes = await _svc.reminderMinutes();
    final allowed = await Reminder.hasPermission();
    if (on && allowed) await Reminder.schedule(minutes);
    if (mounted) {
      setState(() {
        _on = on;
        _minutes = minutes;
        _allowed = allowed;
      });
    }
  }

  Future<void> _toggle(bool v) async {
    HapticFeedback.selectionClick();
    setState(() => _on = v);
    await _svc.setReminder(on: v);
    if (!v) {
      await Reminder.cancel();
      return;
    }
    if (!await Reminder.hasPermission()) {
      await Reminder.requestPermission();
      return; // _load runs when the app comes back from the dialog
    }
    await Reminder.schedule(_minutes);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60));
    if (t == null) return;
    final m = t.hour * 60 + t.minute;
    setState(() => _minutes = m);
    await _svc.setReminder(on: _on, minutes: m);
    if (_on && await Reminder.hasPermission()) await Reminder.schedule(m);
  }

  @override
  Widget build(BuildContext context) {
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60), alwaysUse24HourFormat: true);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: SweeepColors.trackUsed, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.remTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.4)),
                const SizedBox(height: 3),
                Text(l10n.remSub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.textMutedSmall)),
              ]),
            ),
            Switch(
              value: _on,
              onChanged: _toggle,
              activeThumbColor: SweeepColors.onAccent,
              activeTrackColor: SweeepColors.brand,
              inactiveThumbColor: SweeepColors.textMutedSmall,
              inactiveTrackColor: SweeepColors.background,
            ),
          ]),
          if (_on && !_allowed) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(l10n.remNeedPerm, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SweeepColors.trash))),
              TextButton(onPressed: Reminder.requestPermission, child: Text(l10n.remAllow, style: const TextStyle(fontWeight: FontWeight.w800, color: SweeepColors.brand))),
            ]),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _on ? _pickTime : null,
            child: Opacity(
              opacity: _on ? 1 : .4,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: SweeepColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: SweeepColors.cardBorder)),
                child: Row(children: [
                  Text(l10n.remTime, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
