import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/group_service.dart';
import '../../index/review_service.dart';
import '../../index/storage_service.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../category/category_screen.dart';
import '../goal/goal_screen.dart';
import '../groups/group_widgets.dart';
import '../groups/groups_screen.dart';
import '../hub/hub_screen.dart';
import '../storage/storage_labels.dart';
import '../storage/storage_screen.dart';
import '../storage/treemap.dart';

const _muted = Color(0xFF8A8F9E);

/// Space tab (D23): "I need room now". The number that can go, a goal and the
/// safest files to reach it, a small storage map and the quick wins.
class SpaceScreen extends ConsumerStatefulWidget {
  const SpaceScreen({super.key});

  @override
  ConsumerState<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends ConsumerState<SpaceScreen> with SingleTickerProviderStateMixin {
  static const _totalMs = 1300.0;
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  int _goal = 5;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// 0..1 of a step that starts at [delay] ms and lasts [dur] ms.
  double _seg(double delay, double dur, Curve curve) => curve.transform(((_t.value * _totalMs - delay) / dur).clamp(0.0, 1.0));

  Future<void> _push(Widget w) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    ref.invalidate(storageProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(trashSummaryProvider);
  }

  void _clean(QuickWin w) {
    HapticFeedback.selectionClick();
    _push(w == QuickWin.duplicates ? const GroupsScreen(kind: GroupKind.duplicate) : CategoryScreen(kind: CategoryKind.quickWin, win: w));
  }

  /// "14.2" and "GB" for a size, picking the unit from the size.
  (String, String) _split(int bytes) {
    final u = l10n.byteUnits.split(',');
    var v = bytes.toDouble();
    var i = 0;
    while (v >= 1024 && i < u.length - 1) {
      v /= 1024;
      i++;
    }
    final unit = i < 2 ? 2 : i; // never show KB as the headline: it reads as 0.0 MB
    final shown = i < 2 ? bytes / (1024 * 1024) : v;
    return (fmtNum(shown, digits: 1), u[unit]);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storageProvider);
    final width = MediaQuery.sizeOf(context).width;
    return ColoredBox(
      color: SweeepColors.background,
      child: Stack(children: [
        const GlowOrb(right: -60, top: 20, width: 260, height: 260, color: Color(0x1FB8A6FF), blur: 70),
        async.when(
          loading: () => _body(null, width),
          error: (e, _) => _body(null, width),
          data: (d) => _body(d, width),
        ),
      ]),
    );
  }

  Widget _body(StorageData? d, double width) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) => ListView(
        padding: const EdgeInsets.only(top: 52, bottom: 130),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(l10n.spaceTitle, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
              HubButton(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HubScreen()))),
            ]),
          ),
          if (d != null) ..._content(d, width),
        ],
      ),
    );
  }

  List<Widget> _content(StorageData d, double width) {
    final (big, unit) = _split(d.safeBytes);
    final types = {for (final t in d.cuts[StorageCut.types]!) t.key: t.bytes};
    final videos = (types['videos'] ?? 0) + (types['recordings'] ?? 0);
    final photos = types['photos'] ?? 0;
    final other = (types['chat'] ?? 0) + (types['screenshots'] ?? 0);
    final labelGb = d.totalBytes >= 1024 * 1024 * 1024;
    String lab(int b) => fmtNum(b / (labelGb ? 1024 * 1024 * 1024 : 1024 * 1024), digits: 1);
    final months = [...d.cuts[StorageCut.months]!]..sort((a, b) => b.bytes.compareTo(a.bytes));
    final mapTiles = months.take(4).toList();
    final div = d.totalBytes >= 1024 * 1024 * 1024 ? 1024 * 1024 * 1024 : 1024 * 1024;
    final mapW = width - 40;
    final floor = mapTiles.fold<int>(0, (a, t) => a + t.bytes) * .08;
    final rects = squarify([for (final t in mapTiles) t.bytes < floor ? floor : t.bytes.toDouble()], mapW, 170);
    final wins = d.wins.where((w) => w.count > 0).toList();
    final riseCard = _seg(0, 500, Curves.easeOut);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(big, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, letterSpacing: -3, height: .95)),
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(l10n.spaceCanGo(unit), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SweeepColors.brand))),
          ]),
          const SizedBox(height: 6),
          Text(l10n.storOfTotal(formatBytes(d.totalBytes)), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _muted)),
          const SizedBox(height: 14),
          // Videos / Photos / Other, each bar grows from the left
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(children: [
                for (final (i, b) in [videos, photos, other].indexed) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: b <= 0 ? 0 : (b / 1024).ceil().clamp(1, 1 << 30),
                    child: Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.diagonal3Values(_seg(i * 100.0, 800, const Cubic(.2, .8, .2, 1)), 1, 1),
                      child: ColoredBox(color: SweeepColors.brand.withValues(alpha: const <double>[1, .55, .25][i]), child: const SizedBox.expand()),
                    ),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('${l10n.storTypeVideos} ${lab(videos)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted)),
            const SizedBox(width: 14),
            Text('${l10n.storTypePhotos} ${lab(photos)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted)),
            const SizedBox(width: 14),
            Text('${l10n.storSrcOther} ${lab(other)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted)),
          ]),
        ]),
      ),
      // I NEED
      Opacity(
        opacity: riseCard,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - riseCard)),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: SweeepColors.brand.withValues(alpha: .35))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.goalLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: _muted)),
              const SizedBox(height: 10),
              Row(children: [
                for (final g in const [1, 3, 5, 8]) ...[
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _goal = g);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: g == _goal ? SweeepColors.brand : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          border: g == _goal ? null : Border.all(color: Colors.white.withValues(alpha: .12)),
                        ),
                        child: Text('$g ${goalUnitName()}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: g == _goal ? SweeepColors.onAccent : SweeepColors.text)),
                      ),
                    ),
                  ),
                  if (g != 8) const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 14),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _push(GoalScreen(initialGoal: _goal)),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: SweeepColors.brand.withValues(alpha: .25), blurRadius: 24)]),
                  child: Text(l10n.spaceFind('$_goal ${goalUnitName()}'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: SweeepColors.onAccent)),
                ),
              ),
            ]),
          ),
        ),
      ),
      // storage map
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(l10n.spaceMap, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5))),
          GestureDetector(onTap: () => _push(const StorageScreen()), child: Text(l10n.spaceOpen, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SweeepColors.brand))),
        ]),
      ),
      if (mapTiles.isNotEmpty)
        GestureDetector(
          onTap: () => _push(const StorageScreen()),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            height: 170,
            child: Stack(children: [
              for (var i = 0; i < mapTiles.length; i++) _mapTile(i, mapTiles[i], rects[i], div),
            ]),
          ),
        ),
      // quick wins
      if (wins.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.storQuickTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                const SizedBox(height: 2),
                Text(l10n.storQuickSub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted)),
              ]),
            ),
            Text(formatBytes(d.winsBytes), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: SweeepColors.brand)),
          ]),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            itemCount: wins.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _WinCard(stat: wins[i], onClean: () => _clean(wins[i].win)),
          ),
        ),
      ],
      _link(Icons.videocam_outlined, l10n.spaceShrink, l10n.soonWord, topGap: 18),
      _link(Icons.bar_chart_rounded, l10n.hubWeek, l10n.soonWord, topGap: 12),
    ];
  }

  /// One block of the mini map, popping in from scale .7 (0.5 s, ease-out) at 0 / .08 / .16 / .24 s.
  Widget _mapTile(int i, StorageTile t, Rect r, int div) {
    final k = _seg(i * 80.0, 500, Curves.easeOut);
    final big = i == 0;
    final mid = i == 1;
    final bg = big ? SweeepColors.brand : SweeepColors.brand.withValues(alpha: mid ? .34 : .15);
    final label = i < 2 ? tileLabel(StorageCut.months, t.key) : tileShortLabel(StorageCut.months, t.key);
    final size = i < 2 ? formatBytes(t.bytes) : fmtNum(t.bytes / div, digits: 1);
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: Opacity(
        opacity: k,
        child: Transform.scale(
          scale: .7 + .3 * k,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              padding: i < 2 ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(i < 2 ? 18 : 16)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, maxLines: 1, style: TextStyle(fontSize: i < 2 ? 12 : 11, fontWeight: FontWeight.w800, color: big ? SweeepColors.onAccent : SweeepColors.text)),
                  SizedBox(height: i == 0 || i == 1 ? 6 : 4),
                  Text(size, maxLines: 1, style: TextStyle(fontSize: big ? 24 : (mid ? 18 : 14), fontWeight: FontWeight.w800, letterSpacing: big ? -.5 : 0, color: big ? SweeepColors.onAccent : SweeepColors.text)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(IconData icon, String title, String sub, {required double topGap}) => Container(
        margin: EdgeInsets.fromLTRB(20, topGap, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: SweeepColors.brand.withValues(alpha: .14), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, size: 22, color: SweeepColors.brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Padding(padding: const EdgeInsets.only(top: 1), child: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted))),
            ]),
          ),
          Container(
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(9)),
            child: Text(l10n.soonBadge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .8, color: Color(0xFFA9AEBB))),
          ),
        ]),
      );
}

class _WinCard extends StatelessWidget {
  const _WinCard({required this.stat, required this.onClean});
  final QuickWinStat stat;
  final VoidCallback onClean;

  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: .06))),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(quickWinTitle(stat.win), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
            const SizedBox(width: 4),
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: SweeepColors.brand.withValues(alpha: .5))),
              child: Text(l10n.storSafe, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8, color: SweeepColors.brand)),
            ),
          ]),
          Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatBytes(stat.bytes), maxLines: 1, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.8)),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: '${l10n.storClean}: ${quickWinTitle(stat.win)}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClean,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: SweeepColors.trash, borderRadius: BorderRadius.circular(17)),
                  child: Text(l10n.storClean, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: SweeepColors.onAccent)),
                ),
              ),
            ),
          ]),
        ]),
      );
}
