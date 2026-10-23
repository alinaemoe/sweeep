import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../../platform/apps.dart';
import 'apps_icons.dart';
import 'usage_access_screen.dart';

const _muted = Color(0xFF8A8F9E);
const _track = Color(0xFF262833);
const _ease = Cubic(.2, .8, .2, 1);
const _unusedDays = 60;
const _step = 80.0;

enum _Sort { size, unused, recent }

/// "2.4 GB" / "640 MB": the number and its unit.
(String, String) _sizeParts(int bytes) {
  final u = l10n.byteUnits.split(',');
  const gb = 1024 * 1024 * 1024;
  if (bytes >= gb * .95) return (fmtNum(bytes / gb, digits: 1), u[3]);
  return (fmtNum(bytes / (1024 * 1024), digits: 0), u[2]);
}

String _size(int bytes) {
  final p = _sizeParts(bytes);
  return '${p.$1} ${p.$2}';
}

/// App cleaner (D25): installed apps by size and by how long they sat unused.
/// [usage] says whether Usage access is granted: sizes include data and last
/// launch is known. Without it only the apk sizes are shown.
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key, required this.usage});
  final bool usage;

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<AppInfo>? _apps;
  _Sort _sort = _Sort.size;
  final Set<String> _sel = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await AppsPlatform.list();
    apps.sort((a, b) => b.size.compareTo(a.size));
    if (!mounted) return;
    setState(() => _apps = apps);
  }

  /// Days apart, then the bigger app first, so equal days keep a steady order.
  int _byDays(AppInfo a, AppInfo b, DateTime now) {
    final d = a.daysSince(now).compareTo(b.daysSince(now));
    return d != 0 ? d : b.size.compareTo(a.size);
  }

  List<AppInfo> _ranked(List<AppInfo> apps, DateTime now) {
    final l = apps.toList();
    switch (_sort) {
      case _Sort.size:
        break;
      case _Sort.unused:
        l.sort((a, b) => _byDays(b, a, now));
      case _Sort.recent:
        l.sort((a, b) => _byDays(a, b, now));
    }
    return l;
  }

  Future<void> _uninstall() async {
    final apps = _apps;
    if (apps == null || _busy) return;
    _busy = true;
    final now = DateTime.now();
    final queue = _ranked(apps, now)
        .where((a) => _sel.contains(a.package))
        .map((a) => a.package)
        .toList();
    for (final pkg in queue) {
      final gone = await AppsPlatform.uninstall(pkg);
      if (!mounted) return;
      if (!gone) break; // cancelled in the system dialog: stop the queue
      setState(() {
        _apps = _apps!.where((a) => a.package != pkg).toList();
        _sel.remove(pkg);
      });
    }
    _busy = false;
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    final now = DateTime.now();
    final ranked = apps == null ? const <AppInfo>[] : _ranked(apps, now);
    final total = apps?.fold<int>(0, (t, a) => t + a.size) ?? 0;
    final unused =
        apps?.where((a) => a.daysSince(now) >= _unusedDays).toList() ??
            const <AppInfo>[];
    final unusedBytes = unused.fold<int>(0, (t, a) => t + a.size);
    final maxSize = apps == null || apps.isEmpty
        ? 1
        : apps.map((a) => a.size).reduce((a, b) => a > b ? a : b);
    final selBytes = apps
            ?.where((a) => _sel.contains(a.package))
            .fold<int>(0, (t, a) => t + a.size) ??
        0;
    return Scaffold(
      body: Stack(children: [
        GlowOrb(
            right: -70,
            top: 30,
            width: 260,
            height: 260,
            color: SweeepColors.brand.withValues(alpha: .12),
            blur: 70),
        ListView(
          padding: const EdgeInsets.only(top: 52, bottom: 150),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      button: true,
                      label: l10n.back,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: SweeepColors.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: .06))),
                          child: const Icon(Icons.chevron_left_rounded,
                              size: 22, color: SweeepColors.text),
                        ),
                      ),
                    ),
                    if (apps != null)
                      Text(
                          l10n.appsHeader(
                              l10n.appsCount(apps.length), _size(total)),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _muted)),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(l10n.appsTitle,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1)),
            ),
            if (apps == null)
              const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                      child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: SweeepColors.brand))))
            else ...[
              Rise(
                  child: _summary(widget.usage ? unusedBytes : total,
                      widget.usage ? unused.length : apps.length, total)),
              if (widget.usage) _chips() else _noAccess(),
              if (apps.isEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                        child: Text(l10n.appsEmpty,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _muted))))
              else
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  height: apps.length * _step,
                  child: Stack(clipBehavior: Clip.none, children: [
                    for (final a in apps)
                      AnimatedPositioned(
                        key: ValueKey(a.package),
                        duration: const Duration(milliseconds: 550),
                        curve: _ease,
                        left: 0,
                        right: 0,
                        top: ranked.indexOf(a) * _step,
                        height: 72,
                        child: _AppRow(
                          app: a,
                          maxSize: maxSize,
                          now: now,
                          usage: widget.usage,
                          selected: _sel.contains(a.package),
                          onTap: () => setState(() => _sel.contains(a.package)
                              ? _sel.remove(a.package)
                              : _sel.add(a.package)),
                        ),
                      ),
                  ]),
                ),
            ],
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 22,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _sel.isEmpty ? 200 : 0),
            duration: const Duration(milliseconds: 400),
            curve: _ease,
            builder: (_, y, child) =>
                Transform.translate(offset: Offset(0, y), child: child),
            child: IgnorePointer(ignoring: _sel.isEmpty, child: _bar(selBytes)),
          ),
        ),
      ]),
    );
  }

  Widget _summary(int bytes, int n, int total) {
    final p = _sizeParts(bytes);
    final share = total <= 0 ? 0.0 : bytes / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: SweeepColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: SweeepColors.brand.withValues(alpha: .35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.usage ? l10n.appsUnusedLabel : l10n.appsAllLabel,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _muted)),
        const SizedBox(height: 6),
        Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(p.$1,
                  style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.5,
                      height: .95)),
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(l10n.appsUnusedIn(n, p.$2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: SweeepColors.brand)),
                ),
              ),
            ]),
        if (widget.usage) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 10,
              color: _track,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: _ease,
                builder: (_, t, __) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                      widthFactor: (share * t).clamp(0.0, 1.0),
                      child: Container(color: SweeepColors.brand)),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
            widget.usage
                ? l10n.appsOfTotal(_size(total))
                : l10n.appsOfTotalApk(_size(total)),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
      ]),
    );
  }

  Widget _chips() {
    final labels = {
      _Sort.size: l10n.appsSortSize,
      _Sort.unused: l10n.appsSortUnused,
      _Sort.recent: l10n.appsSortRecent
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(children: [
        for (final s in _Sort.values) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _sort = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _sort == s ? SweeepColors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: _sort == s
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: .12)),
              ),
              child: Text(labels[s]!,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _sort == s
                          ? SweeepColors.onAccent
                          : SweeepColors.text)),
            ),
          ),
          if (s != _Sort.values.last) const SizedBox(width: 8),
        ],
      ]),
    );
  }

  Widget _noAccess() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(children: [
          Expanded(
              child: Text(l10n.appsNoAccess,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                      height: 1.4))),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                    builder: (_) => const UsageAccessScreen())),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: SweeepColors.brand,
                  borderRadius: BorderRadius.circular(18)),
              child: Text(l10n.appsAllowAccess,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SweeepColors.onAccent)),
            ),
          ),
        ]),
      );

  Widget _bar(int selBytes) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: SweeepColors.card.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: .08))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.appsUninstallNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _muted)),
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _uninstall,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: SweeepColors.trash,
                      borderRadius: BorderRadius.circular(26)),
                  child: Text(l10n.appsUninstall(_sel.length, _size(selBytes)),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: SweeepColors.onAccent)),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _AppRow extends StatelessWidget {
  const _AppRow(
      {required this.app,
      required this.maxSize,
      required this.now,
      required this.usage,
      required this.selected,
      required this.onTap});
  final AppInfo app;
  final int maxSize;
  final DateTime now;
  final bool usage;
  final bool selected;
  final VoidCallback onTap;

  String _age(int days) {
    if (app.lastUsed > 0 && days == 0) return l10n.appsOpenedToday;
    if (app.lastUsed > 0 && days == 1) return l10n.appsOpenedYesterday;
    if (app.lastUsed == 0 && days == 0) return l10n.appsNeverOpened;
    return l10n.appsAgeDays(days);
  }

  @override
  Widget build(BuildContext context) {
    final days = app.daysSince(now);
    return Semantics(
      button: true,
      selected: selected,
      label: app.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? SweeepColors.trash.withValues(alpha: .06)
                : SweeepColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: selected
                    ? SweeepColors.trash.withValues(alpha: .6)
                    : Colors.white.withValues(alpha: .06),
                width: selected ? 1.5 : 1),
          ),
          child: Row(children: [
            _AppIcon(app: app),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                              child: Text(app.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.2))),
                          const SizedBox(width: 8),
                          Text(_size(app.size),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.3)),
                        ]),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 5,
                        color: _track,
                        alignment: Alignment.centerLeft,
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 500),
                          widthFactor: (app.size / maxSize).clamp(0.0, 1.0),
                          child: Container(color: SweeepColors.brand),
                        ),
                      ),
                    ),
                    if (usage) ...[
                      const SizedBox(height: 5),
                      Text(_age(days),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: days >= _unusedDays
                                  ? SweeepColors.trash
                                  : _muted)),
                    ],
                  ]),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? SweeepColors.trash : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: .25), width: 1.5),
              ),
              child: selected
                  ? const Center(
                      child: CheckIcon(
                          size: 13, color: SweeepColors.onAccent, stroke: 3.5))
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app});
  final AppInfo app;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: const Color(0xFF2E3A59),
            borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: FutureBuilder(
          future: AppsPlatform.icon(app.package),
          builder: (_, s) => s.data == null
              ? Text(
                  app.name.isEmpty
                      ? '?'
                      : app.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800))
              : Image.memory(s.data!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  gaplessPlayback: true),
        ),
      );
}
