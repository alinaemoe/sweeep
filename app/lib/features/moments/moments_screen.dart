import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav_icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../index/moments_service.dart';
import '../../index/review_service.dart';
import '../../l10n/l10n.dart';
import '../../platform/places.dart';
import '../../providers.dart';
import '../groups/group_widgets.dart';
import '../swipe/swipe_screen.dart';
import 'places_access_screen.dart';

const _muted = Color(0xFF8A8F9E);
const _page = 12;

/// The words for an event title code (see `momentTitleCode`).
String momentName(MomentView m) {
  final user = m.userTitle;
  if (user != null && user.isNotEmpty) return user;
  final p = m.title.split(':');
  int arg(int i) => i < p.length ? int.tryParse(p[i]) ?? 0 : 0;
  final start = DateTime.fromMillisecondsSinceEpoch(m.startMs);
  return switch (p.first) {
    'trip' => l10n.momTripDays(arg(1)),
    'weekend' => l10n.momWeekendAway(arg(1)),
    'daytrip' => l10n.momDayTrip(arg(1)),
    'evening' => l10n.momEveningHome,
    'date' => fmtDayMonth(start),
    'w_days' => l10n.momDays(arg(1)),
    'w_weekend' => l10n.momWeekend,
    'w_evening' => l10n.momEvening,
    _ => l10n.momDay,
  };
}

/// 3 – 6 May 2026 / 22 Aug 2026 / 30 Apr – 2 May 2026.
String momentWhen(int startMs, int endMs) {
  final a = DateTime.fromMillisecondsSinceEpoch(startMs);
  final b = DateTime.fromMillisecondsSinceEpoch(endMs);
  final same = a.year == b.year && a.month == b.month && a.day == b.day;
  if (same) return '${a.day} ${fmtMonthAbbr(a.year, a.month)} ${a.year}';
  if (a.year == b.year && a.month == b.month) return '${a.day} – ${b.day} ${fmtMonthAbbr(b.year, b.month)} ${b.year}';
  final left = a.year == b.year ? '${a.day} ${fmtMonthAbbr(a.year, a.month)}' : '${a.day} ${fmtMonthAbbr(a.year, a.month)} ${a.year}';
  return '$left – ${b.day} ${fmtMonthAbbr(b.year, b.month)} ${b.year}';
}

/// Moments (D18): photos shot close in time (and place) as one event.
class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  final List<MomentView> _items = [];
  final _scroll = ScrollController();
  bool _building = true;
  bool _more = true;
  bool _loadingMore = false;
  bool _placesOn = false;

  MomentsService get _svc => ref.read(momentsServiceProvider);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) _loadMore();
    });
    _boot();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    // the first time: ask, calmly, before Android does
    var places = await _svc.placesOn();
    if (places == null) {
      if (await Places.hasPermission()) {
        await _svc.setPlaces(true);
        places = true;
      } else if (mounted) {
        places = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(builder: (_) => const PlacesAccessScreen())) ?? false;
      }
    }
    if (!mounted) return;
    setState(() => _placesOn = places == true);
    // events already stored show at once; the rebuild runs behind them
    await _reload();
    await _svc.refresh();
    if (!mounted) return;
    await _reload();
    setState(() => _building = false);
  }

  Future<void> _reload() async {
    final first = await _svc.list(limit: _page);
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(first);
      _more = first.length == _page;
    });
  }

  Future<void> _loadMore() async {
    if (!_more || _loadingMore) return;
    _loadingMore = true;
    final next = await _svc.list(limit: _page, offset: _items.length);
    if (!mounted) return;
    setState(() {
      _items.addAll(next);
      _more = next.length == _page;
    });
    _loadingMore = false;
  }

  Future<void> _sweep(MomentView m) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SwipeScreen(source: SwipeSource.event, eventId: m.id, eventTitle: momentName(m))));
    if (!mounted) return;
    ref.invalidate(timelineProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(trashSummaryProvider);
    final fresh = await _svc.byId(m.id);
    if (!mounted || fresh == null) return;
    final i = _items.indexWhere((e) => e.id == m.id);
    if (i >= 0) setState(() => _items[i] = fresh);
  }

  Future<void> _rename(MomentView m) async {
    final r = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RenameSheet(current: m.userTitle ?? '', generated: momentName(MomentView(id: m.id, startMs: m.startMs, endMs: m.endMs, title: m.title, userTitle: null, count: m.count, bytes: m.bytes, awayKm: m.awayKm, best: m.best, twins: m.twins, tiles: m.tiles))),
    );
    if (r == null || !mounted) return;
    await _svc.rename(m.id, r);
    final fresh = await _svc.byId(m.id);
    final i = _items.indexWhere((e) => e.id == m.id);
    if (fresh != null && i >= 0 && mounted) setState(() => _items[i] = fresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const GlowOrb(right: -60, top: 40, width: 260, height: 260, color: Color(0x1FB8A6FF), blur: 70),
        ListView(
          controller: _scroll,
          padding: const EdgeInsets.only(top: 52, bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.momentsTitle, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(height: 4),
                Text(l10n.momentsDesc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _muted, height: 1.4)),
              ]),
            ),
            if (_items.isEmpty && _building)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(children: [
                  const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: SweeepColors.brand)),
                  const SizedBox(height: 14),
                  Text(l10n.momentsBuilding, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted)),
                ]),
              )
            else if (_items.isEmpty)
              _empty()
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 18),
                    Rise(
                      key: ValueKey(_items[i].id),
                      delay: Duration(milliseconds: (100 + (i % _page) * 120).clamp(0, 600)),
                      dy: 18,
                      duration: const Duration(milliseconds: 600),
                      child: _MomentCard(view: _items[i], onSweep: () => _sweep(_items[i]), onRename: () => _rename(_items[i])),
                    ),
                  ],
                ]),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: CustomPaint(
                painter: _Dashed(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Text(_placesOn ? l10n.momentsNotePlaces : l10n.momentsNoteTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted, height: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.momentsEmptyTitle, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.5)),
            const SizedBox(height: 6),
            Text(l10n.momentsEmptySub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted, height: 1.45)),
          ]),
        ),
      );
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.view, required this.onSweep, required this.onRename});
  final MomentView view;
  final VoidCallback onSweep;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final m = view;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onRename,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(momentName(m), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                const SizedBox(height: 2),
                Text(momentWhen(m.startMs, m.endMs), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _muted)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatBytes(m.bytes), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)),
            Text(l10n.photosCount(m.count), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
          ]),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: i == 0 ? Border.all(color: SweeepColors.keep, width: 2) : Border.all(color: Colors.white.withValues(alpha: .1))),
                  clipBehavior: Clip.antiAlias,
                  child: i < m.tiles.length ? ThumbImage(id: m.tiles[i], side: 256) : const ColoredBox(color: Color(0xFF2E3A59), child: SizedBox.expand()),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(text: l10n.momentsBest(m.best), bg: SweeepColors.keep.withValues(alpha: .12), fg: SweeepColors.keep),
          _Chip(text: l10n.momentsTwins(m.twins), bg: SweeepColors.trash.withValues(alpha: .12), fg: SweeepColors.trash),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSweep,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(23)),
            child: Text(l10n.momentsSweep, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: SweeepColors.onAccent)),
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
        child: Center(widthFactor: 1, child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg))),
      );
}

/// Name field in a sheet; pops the new text, '' to go back to the generated name.
class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.current, required this.generated});
  final String current;
  final String generated;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _c = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          decoration: const BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.momRenameTitle, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.5)),
            const SizedBox(height: 14),
            TextField(
              controller: _c,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: widget.generated,
                hintStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
                counterText: '',
                filled: true,
                fillColor: SweeepColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: SweeepColors.brand)),
              ),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(_c.text),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(23)),
                child: Text(l10n.momRenameSave, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: SweeepColors.onAccent)),
              ),
            ),
            if (widget.current.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(''),
                child: SizedBox(height: 40, child: Center(child: Text(l10n.momRenameReset, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted)))),
              ),
          ]),
        ),
      );
}

class _Dashed extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)));
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => false;
}
