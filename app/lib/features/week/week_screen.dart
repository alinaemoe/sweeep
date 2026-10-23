import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/database.dart' show DailyStat;
import '../../index/stats_service.dart';
import '../../l10n/l10n.dart';
import '../../platform/system_settings.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart' show formatBytes;

const _muted = Color(0xFF8A8F9E);
const _soft = Color(0xFFA9AEBB);
const _track = Color(0xFF262833);
const _ease = Cubic(.2, .8, .2, 1);
const _gib = 1024 * 1024 * 1024;

/// Test builds (`--dart-define=WEEK_DEMO=true`) page through the three weeks of the prototype.
const _demo = bool.fromEnvironment('WEEK_DEMO');

List<DailyStat> _demoRows(DateTime today) {
  const weeks = [
    ([42, 55, 61, 48, 50, 30, 26], [38, 27, 21, 14], 58),
    ([30, 36, 45, 52, 28, 40, 22], [30, 34, 22, 14], 60),
    ([20, 0, 33, 41, 25, 0, 18], [26, 30, 24, 20], 61),
  ];
  final mon = WeekBook.monday(today);
  final rows = <DailyStat>[];
  for (var w = 0; w < weeks.length; w++) {
    final (vals, cats, used) = weeks[w];
    final sum = cats.fold<int>(0, (a, b) => a + b);
    for (var i = 0; i < 7; i++) {
      final d = DateTime(mon.year, mon.month, mon.day - 7 * w + i);
      final cleared = (vals[i] * .26).round();
      int part(int c) => (cleared * c / sum).round();
      rows.add(DailyStat(
        day: StatsService.dayKey(d),
        swept: vals[i],
        kept: vals[i] - cleared,
        clearedFiles: cleared,
        clearedBytes: (cleared * .0296 * _gib).round(),
        sessions: vals[i] == 0 ? 0 : (vals[i] / 25).round().clamp(1, 9),
        catDups: part(cats[0]),
        catSimilar: part(cats[1]),
        catShots: part(cats[2]),
        catBlurry: part(cats[3]),
        catOther: 0,
        usedPct: i == 6 ? used : null,
      ));
    }
  }
  return rows;
}

/// Weekly report (D16): one Monday to Sunday week at a time, from `daily_stats`.
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> with TickerProviderStateMixin {
  WeekBook? _book;
  int _back = 0;
  int _day = 0;

  // count-up of the headline and the three counters, ~1.1 s ease-out
  late final AnimationController _count = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  List<double> _from = [0, 0, 0, 0];
  List<double> _to = [0, 0, 0, 0];

  // the category bar changes its flex over .6 s
  late final AnimationController _cats = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  List<double> _catFrom = List.filled(WeekCategory.values.length, 0);
  List<double> _catTo = List.filled(WeekCategory.values.length, 0);

  late final AnimationController _flame = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _count.dispose();
    _cats.dispose();
    _flame.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stats = ref.read(statsServiceProvider);
    final used = await SystemSettings.usedPercent();
    await stats.snapshot(usedPct: used);
    final goal = await ref.read(sessionServiceProvider).goal();
    final book = _demo ? WeekBook.from(_demoRows(DateTime.now()), today: DateTime.now(), goal: 50) : await stats.book(goal: goal, usedNow: used);
    if (!mounted) return;
    final today = DateTime.now();
    setState(() {
      _book = book;
      _day = today.weekday - 1;
    });
    _retarget(animate: true);
    _waiting = await stats.waitingBytes();
    if (mounted) setState(() {});
  }

  int _waiting = 0;

  WeekReport get _week => _book!.week(_back);

  double get _eased => Curves.easeOutCubic.transform(_count.value);

  List<double> get _shown => [for (var i = 0; i < 4; i++) _from[i] + (_to[i] - _from[i]) * _eased];

  List<double> get _catShown {
    final k = _ease.transform(_cats.value);
    return [for (var i = 0; i < _catTo.length; i++) _catFrom[i] + (_catTo[i] - _catFrom[i]) * k];
  }

  void _retarget({required bool animate}) {
    final w = _week;
    _from = animate ? _shown : _to;
    _to = [w.clearedBytes.toDouble(), w.swept.toDouble(), w.kept.toDouble(), w.clearedFiles.toDouble()];
    final total = w.cats.values.fold<int>(0, (t, v) => t + v);
    _catFrom = _catShown;
    _catTo = [for (final c in WeekCategory.values) total == 0 ? 0 : w.cats[c]! / total];
    _count.forward(from: 0);
    _cats.forward(from: 0);
  }

  void _go(int back) {
    if (back < 0 || back >= _book!.count) return;
    setState(() => _back = back);
    _retarget(animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    return Scaffold(
      body: Stack(children: [
        GlowOrb(right: -60, top: 60, width: 260, height: 260, color: SweeepColors.brand.withValues(alpha: .14), blur: 80),
        if (book == null)
          Positioned(left: 20, top: 52, child: _roundBack())
        else
          AnimatedBuilder(animation: Listenable.merge([_count, _cats]), builder: (_, __) => _content(book)),
      ]),
    );
  }

  Widget _roundBack() => Semantics(
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
      );

  String _range(WeekReport w) {
    final a = w.start;
    final b = w.end;
    final left = a.month == b.month ? '${a.day}' : '${a.day} ${fmtMonthAbbr(a.year, a.month)}';
    return l10n.weekRange(left, '${b.day} ${fmtMonthAbbr(b.year, b.month)}');
  }

  Widget _content(WeekBook book) {
    final w = _week;
    final shown = _shown;
    final big = w.clearedBytes >= _gib ~/ 10;
    final unit = l10n.byteUnits.split(',')[big ? 3 : 2];
    final gbText = big ? fmtNum(shown[0] / _gib, digits: 1) : fmtNum(shown[0] / (1024 * 1024), digits: 0);
    final cur = w.clearedBytes;
    final prev = w.prevClearedBytes;
    var delta = l10n.weekFirst;
    var deltaBg = Colors.white.withValues(alpha: .08);
    var deltaFg = _soft;
    var deltaRot = 0.0;
    if (prev != null) {
      if (prev == 0) {
        delta = cur == 0 ? l10n.weekSame : l10n.weekNothingBefore;
      } else {
        final pct = ((cur - prev) / prev * 100).round();
        if (pct == 0) {
          delta = l10n.weekSame;
        } else {
          delta = pct > 0 ? l10n.weekMore(pct) : l10n.weekLess(-pct);
          if (pct > 0) {
            deltaBg = SweeepColors.brand.withValues(alpha: .14);
            deltaFg = SweeepColors.brand;
          } else {
            deltaRot = math.pi;
          }
        }
      }
    }
    return ListView(
      padding: const EdgeInsets.only(top: 52, bottom: 40),
      children: [
        _header(book, w),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(w.isCurrent ? l10n.weekLabelNow : l10n.weekLabelPast, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: _muted)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(gbText, style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w800, letterSpacing: -3, height: .95)),
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(l10n.weekCleared(unit), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: deltaBg, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Transform.rotate(angle: deltaRot, child: Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: deltaFg, weight: 900)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(delta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: deltaFg))),
                ]),
              ),
            ),
          ]),
        ),
        _chart(w),
        Rise(delay: const Duration(milliseconds: 200), dy: 16, duration: const Duration(milliseconds: 600), child: _streak(w)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(child: _counter(l10n.weekSwept, shown[1], SweeepColors.text)),
            const SizedBox(width: 10),
            Expanded(child: _counter(l10n.weekKept, shown[2], SweeepColors.keep)),
            const SizedBox(width: 10),
            Expanded(child: _counter(l10n.weekClearedCaps, shown[3], SweeepColors.trash)),
          ]),
        ),
        Rise(delay: const Duration(milliseconds: 400), dy: 16, duration: const Duration(milliseconds: 600), child: _whatWent(w)),
        Rise(delay: const Duration(milliseconds: 500), dy: 16, duration: const Duration(milliseconds: 600), child: _storage(w)),
      ],
    );
  }

  Widget _header(WeekBook book, WeekReport w) {
    final canPrev = _back < book.count - 1;
    final canNext = _back > 0;
    Widget arrow(IconData icon, bool on, String label, VoidCallback tap) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: on ? tap : null,
            child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 18, color: on ? SweeepColors.text : const Color(0xFF3A3E4D))),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _roundBack(),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .06))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            arrow(Icons.chevron_left_rounded, canPrev, l10n.weekPrev, () => _go(_back + 1)),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 92),
              child: Text(_range(w), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 4),
            arrow(Icons.chevron_right_rounded, canNext, l10n.weekNext, () => _go(_back - 1)),
          ]),
        ),
      ]),
    );
  }

  Widget _chart(WeekReport w) {
    final max = [70, w.maxDay, w.goal].reduce(math.max).toDouble();
    final goalTop = (170 - w.goal / max * 120).roundToDouble();
    final sel = w.days[_day];
    final today = DateTime.now();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l10n.weekChartTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(l10n.weekGoal(w.goal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _muted)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: Stack(children: [
            Positioned(left: 0, right: 0, top: goalTop, child: const _Dashed()),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _bar(w, i, max, today)),
              ],
            ]),
          ]),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Text(fmtWeekdayShort(i), textAlign: TextAlign.center, maxLines: 1, style: TextStyle(fontSize: 11, fontWeight: i == _day ? FontWeight.w800 : FontWeight.w700, color: i == _day ? SweeepColors.text : _muted)),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: SweeepColors.background, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .06))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fmtWeekdayFull(_day), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sel.swept == 0 ? l10n.weekNoSession : l10n.weekDaySub(l10n.weekPhotosSwept(sel.swept), l10n.weekSessions(sel.sittings)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
              ]),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l10n.filesCount(sel.clearedFiles), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.4, color: SweeepColors.trash)),
              Text(l10n.weekClearedWord, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _bar(WeekReport w, int i, double max, DateTime today) {
    final d = w.days[i];
    final on = i == _day;
    final reached = d.swept >= w.goal;
    final h = math.max(4, (d.swept / max * 120).round()).toDouble();
    return Semantics(
      button: true,
      selected: on,
      label: '${fmtWeekdayFull(i)}, ${l10n.weekPhotosSwept(d.swept)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _day = i),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('${d.swept}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: on || reached ? SweeepColors.brand : _muted)),
          const SizedBox(height: 6),
          Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 650),
              curve: _ease,
              width: double.infinity,
              height: h,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(color: on ? SweeepColors.brand : SweeepColors.brand.withValues(alpha: reached ? .85 : .4), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            // outline 2 px, 2 px off the bar
            Positioned(
              left: -4,
              right: -4,
              top: -4,
              bottom: -4,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: on ? 1 : 0,
                  child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: SweeepColors.brand.withValues(alpha: .45), width: 2))),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _streak(WeekReport w) => Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: SweeepColors.brand.withValues(alpha: .16), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _flame,
              builder: (_, child) {
                final t = Curves.easeInOut.transform(_flame.value);
                return Transform.rotate(angle: (-2 + 5 * t) * math.pi / 180, child: Transform.scale(scale: 1 + .1 * t, child: child));
              },
              child: const _Flame(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.weekStreak(w.streak), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.6, height: 1)),
              const SizedBox(height: 4),
              Text(l10n.weekGoalsHit(w.goalsHit), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
            ]),
          ),
          const SizedBox(width: 14),
          Row(children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: w.days[i].swept >= w.goal ? SweeepColors.brand : const Color(0xFF2E3040))),
            ],
          ]),
        ]),
      );

  Widget _counter(String label, double v, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, maxLines: 1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: _muted)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(fmtNum(v.round()), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1, color: color))),
        ]),
      );

  Widget _whatWent(WeekReport w) {
    final names = {
      WeekCategory.duplicates: l10n.catDuplicates,
      WeekCategory.similar: l10n.catSimilar,
      WeekCategory.screenshots: l10n.catScreenshots,
      WeekCategory.blurry: l10n.catBlurry,
      WeekCategory.other: l10n.catOther,
    };
    const colors = {
      WeekCategory.duplicates: SweeepColors.trash,
      WeekCategory.similar: SweeepColors.brand,
      WeekCategory.screenshots: Color(0x8CB8A6FF),
      WeekCategory.blurry: Color(0x40B8A6FF),
      WeekCategory.other: Color(0x59FFFFFF),
    };
    final total = w.cats.values.fold<int>(0, (t, v) => t + v);
    final shown = _catShown;
    final all = WeekCategory.values;
    // what happened this week; a quiet week lists the four usual ones at 0%
    final listed = total == 0 ? all.take(4).toList() : all.where((c) => w.cats[c]! > 0).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.weekWhatWent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 14,
            child: total == 0 && _cats.isCompleted
                ? const ColoredBox(color: _track, child: SizedBox.expand())
                : Row(children: [
                    for (var i = 0, shownCount = 0; i < all.length; i++)
                      if (shown[i] > .0005) ...[
                        if (shownCount++ > 0) const SizedBox(width: 2),
                        Expanded(flex: math.max(1, (shown[i] * 10000).round()), child: ColoredBox(color: colors[all[i]]!, child: const SizedBox.expand())),
                      ],
                  ]),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < listed.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[listed[i]], shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(names[listed[i]]!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            Text('${total == 0 ? 0 : (w.cats[listed[i]]! / total * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted)),
          ]),
        ],
      ]),
    );
  }

  Widget _storage(WeekReport w) {
    final from = w.usedFrom;
    final to = w.usedTo;
    final label = to == null ? '' : (from != null && from != to ? l10n.weekStorageFromTo(from, to) : l10n.weekStorageNow(to));
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l10n.weekStorage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 10,
            color: _track,
            child: LayoutBuilder(
              builder: (_, c) => Stack(children: [
                Container(width: c.maxWidth * (from ?? 0) / 100, color: SweeepColors.trash.withValues(alpha: .5)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: _ease,
                  width: c.maxWidth * (to ?? 0) / 100,
                  decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(5)),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(l10n.weekStorageNote(formatBytes(_waiting)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
      ]),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) => SizedBox(height: 1, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .5), Offset(math.min(x + 3, size.width), .5), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

/// The flame of the prototype: "M12 2c1 4 5 5.5 5 10a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-5 1-9z", 24 px.
class _Flame extends StatelessWidget {
  const _Flame();

  @override
  Widget build(BuildContext context) => const CustomPaint(size: Size.square(24), painter: _FlamePainter());
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final path = Path()
      ..moveTo(12 * k, 2 * k)
      ..relativeCubicTo(1 * k, 4 * k, 5 * k, 5.5 * k, 5 * k, 10 * k)
      ..arcToPoint(Offset(7 * k, 12 * k), radius: Radius.circular(5 * k), clockwise: true)
      ..relativeCubicTo(0, -2 * k, 1 * k, -3 * k, 2 * k, -4 * k)
      ..relativeCubicTo(0, 2 * k, 1 * k, 3 * k, 2 * k, 3 * k)
      ..relativeCubicTo(0, -3 * k, -1 * k, -5 * k, 1 * k, -9 * k)
      ..close();
    canvas.drawPath(path, Paint()..color = SweeepColors.brand);
  }

  @override
  bool shouldRepaint(_FlamePainter old) => false;
}
