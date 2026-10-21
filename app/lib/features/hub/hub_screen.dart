import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../index/session_service.dart';
import '../../l10n/l10n.dart';
import '../../platform/messages.g.dart' show PermissionState;
import '../../platform/reminder.dart';
import '../../platform/system_settings.dart';
import '../../providers.dart';
import '../library/library_screen.dart';
import '../tools/tools_screen.dart';

const _muted = Color(0xFF8A8F9E);
const _soft = Color(0xFFA9AEBB);

/// Hub (D22): everything that is rare, new or a setting. A full screen from
/// the header icon of Clean, Swipe and Space, not a tab.
class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> with WidgetsBindingObserver {
  bool _remindOn = false;
  int _minutes = SessionService.defaultReminderMinutes;

  SessionService get _svc => ref.read(sessionServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReminder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // back from the system permission dialog or from the settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _loadReminder();
    ref.read(permissionProvider.notifier).check();
  }

  Future<void> _loadReminder() async {
    final on = await _svc.reminderOn();
    final minutes = await _svc.reminderMinutes();
    if (on && await Reminder.hasPermission()) await Reminder.schedule(minutes);
    if (mounted) {
      setState(() {
        _remindOn = on;
        _minutes = minutes;
      });
    }
  }

  Future<void> _toggleReminder() async {
    HapticFeedback.selectionClick();
    final v = !_remindOn;
    setState(() => _remindOn = v);
    await _svc.setReminder(on: v);
    if (!v) {
      await Reminder.cancel();
      return;
    }
    if (!await Reminder.hasPermission()) {
      await Reminder.requestPermission();
      return; // _loadReminder runs when the app comes back from the dialog
    }
    await Reminder.schedule(_minutes);
  }

  Future<void> _pickTime() async {
    if (!_remindOn) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60));
    if (t == null) return;
    final m = t.hour * 60 + t.minute;
    setState(() => _minutes = m);
    await _svc.setReminder(on: true, minutes: m);
    if (await Reminder.hasPermission()) await Reminder.schedule(m);
  }

  void _openTool(int i) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ToolsScreen(initial: i, pushed: true)));

  Future<void> _scanAgain() async {
    HapticFeedback.selectionClick();
    ref.read(libraryProvider.notifier).sync(full: true);
    Navigator.of(context).pop();
    ref.read(shellTabProvider.notifier).set(0);
  }

  String get _time {
    final h = (_minutes ~/ 60).toString().padLeft(2, '0');
    final m = (_minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final perm = ref.watch(permissionProvider);
    final indexed = ref.watch(homeProvider).value?.libraryCount ?? ref.watch(libraryProvider).stats?.total ?? 0;
    final lang = ref.watch(languageProvider);
    final accessSub = switch (perm) {
      PermissionState.granted => l10n.hubAccessAll,
      PermissionState.limited => l10n.hubAccessLimited,
      _ => l10n.hubAccessNone,
    };
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 52, bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Semantics(
                button: true,
                label: l10n.back,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: SweeepColors.card, shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .06))),
                    child: const Icon(Icons.chevron_left_rounded, size: 22, color: SweeepColors.text),
                  ),
                ),
              ),
              // hold the version number: the developer screen
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LibraryScreen())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Text(l10n.hubVersion, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(l10n.hubTitle, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
          ),
          // Pro banner
          Rise(
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l10n.proSoon))),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [SweeepColors.brand.withValues(alpha: .30), SweeepColors.brand.withValues(alpha: .10)]),
                  border: Border.all(color: SweeepColors.brand.withValues(alpha: .4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.proTag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: SweeepColors.brand)),
                  const SizedBox(height: 6),
                  Text(l10n.proTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(l10n.proSub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _soft)),
                  const SizedBox(height: 14),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(19)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Text(l10n.proButton, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: SweeepColors.onAccent))]),
                  ),
                ]),
              ),
            ),
          ),
          _label(l10n.hubMore),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Rise(
                      delay: Duration(milliseconds: 100 + i * 80),
                      child: _Cleaner(
                        icon: const [Icons.mail_outline_rounded, Icons.apps_rounded, Icons.save_alt_rounded][i],
                        title: [l10n.cleanerEmail, l10n.cleanerApps, l10n.cleanerCache][i],
                        sub: [l10n.cleanerEmailSub, l10n.cleanerAppsSub, l10n.cleanerCacheSub][i],
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 10),
                ],
              ]),
            ),
          ),
          _label(l10n.hubTools),
          _group([
            _Row(icon: Icons.water_drop_outlined, title: l10n.hubWater, sub: l10n.hubWaterSub, onTap: () => _openTool(0)),
            _Row(icon: Icons.graphic_eq_rounded, title: l10n.hubDust, sub: l10n.hubDustSub, onTap: () => _openTool(1)),
            _Row(icon: Icons.volume_up_outlined, title: l10n.hubSound, sub: l10n.hubSoundSub, onTap: () => _openTool(2)),
          ]),
          _label(l10n.hubInsights),
          _group([
            _Row(title: l10n.hubWeek, sub: l10n.hubWeekSub, soon: true),
            _Row(title: l10n.hubWidgets, sub: l10n.hubWidgetsSub, soon: true),
          ]),
          _label(l10n.hubSettings),
          _group([
            _Row(title: l10n.hubLanguage, trailing: _Lang(value: lang, onChanged: (v) => ref.read(languageProvider.notifier).set(v))),
            _Row(
              title: l10n.remTitle,
              sub: _remindOn ? l10n.hubRemindOn(_time) : l10n.hubRemindOff,
              onTap: _pickTime,
              trailing: _Toggle(on: _remindOn, onTap: _toggleReminder),
            ),
            _Row(title: l10n.hubAccess, sub: accessSub, onTap: SystemSettings.openApp, chevron: true),
            _Row(title: l10n.hubScan, sub: l10n.hubScanSub(indexed), onTap: _scanAgain, chevron: true),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Text('${l10n.hubFoot1}\n${l10n.hubFoot2}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7080), height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: _muted)),
      );

  Widget _group(List<_Row> rows) => Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: .06)),
            rows[i],
          ],
        ]),
      );
}

class _Cleaner extends StatelessWidget {
  const _Cleaner({required this.icon, required this.title, required this.sub});
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: SweeepColors.brand.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 22, color: SweeepColors.brand),
            ),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -.2))),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted)),
          ]),
          const Positioned(right: -2, top: -4, child: _Soon()),
        ]),
      );
}

class _Soon extends StatelessWidget {
  const _Soon();

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context); // a const widget still has to follow a language change
    return Container(
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(9)),
        child: Text(l10n.soonBadge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .8, color: _soft)),
      );
  }
}

/// One row of a group: optional icon, title, subtitle, then a chevron, a SOON chip or a control.
class _Row extends StatelessWidget {
  const _Row({required this.title, this.sub, this.icon, this.onTap, this.trailing, this.chevron = false, this.soon = false});
  final String title;
  final String? sub;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool chevron;
  final bool soon;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: soon ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: SweeepColors.brand.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 20, color: SweeepColors.brand),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                if (sub != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(sub!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted))),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (soon) const _Soon(),
            if (trailing == null && !soon && (onTap != null || chevron)) const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
          ]),
        ),
      );
}

/// Auto | EN | RU, 30 high, the active one lavender.
class _Lang extends StatelessWidget {
  const _Lang({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [('auto', l10n.langAuto), ('en', 'EN'), ('ru', 'RU')];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: SweeepColors.background, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .08))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final it in items)
          Semantics(
            button: true,
            selected: value == it.$1,
            label: it.$2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(it.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 30,
                constraints: const BoxConstraints(minWidth: 46),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: value == it.$1 ? SweeepColors.brand : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                child: Text(it.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: value == it.$1 ? SweeepColors.onAccent : _soft)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 50x30 toggle with a 24 knob.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: on,
        label: l10n.remTitle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 50,
            height: 30,
            decoration: BoxDecoration(color: on ? SweeepColors.brand : const Color(0xFF2E3040), borderRadius: BorderRadius.circular(15)),
            child: Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                top: 3,
                left: on ? 23 : 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: on ? SweeepColors.background : _soft, shape: BoxShape.circle),
                ),
              ),
            ]),
          ),
        ),
      );
}
