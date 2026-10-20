import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../core/widgets.dart';
import 'tone_service.dart';

enum _Tool { water, dust, sound }

/// Tools tab: Water / Dust tone generators and a small Sound test.
/// A plain sine through the speaker; results are not promised.
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
  static const _tone = ToneService();
  static const _runSeconds = 30;

  late final AnimationController _bars = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  _Tool _tool = _Tool.water;
  bool _playing = false;
  Timer? _timer;
  int _left = _runSeconds;

  // Water 165..200 Hz, Dust 100..160 Hz (low, strong pulses), Sound test: free.
  double _water = 165;
  double _dust = 120;
  double _sound = 440;
  int _side = 0; // sound test: 0 both, 1 left, 2 right
  bool _sweep = false;

  (double, double) get _range => switch (_tool) {
        _Tool.water => (165, 200),
        _Tool.dust => (100, 160),
        _Tool.sound => (20, 8000),
      };

  double get _freq => switch (_tool) {
        _Tool.water => _water,
        _Tool.dust => _dust,
        _Tool.sound => _sound,
      };

  bool get _timed => _tool != _Tool.sound;

  @override
  void dispose() {
    _timer?.cancel();
    _tone.stop();
    _bars.dispose();
    super.dispose();
  }

  void _pick(_Tool t) {
    if (t == _tool) return;
    HapticFeedback.selectionClick();
    _stop();
    setState(() => _tool = t);
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    await _tone.start(freq: _freq, pulse: _timed, sweep: _tool == _Tool.sound && _sweep, side: _tool == _Tool.sound ? _side : 0);
    _bars.repeat(reverse: false);
    _left = _runSeconds;
    _timer?.cancel();
    if (_timed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_left <= 1) {
          _stop();
        } else {
          setState(() => _left--);
        }
      });
    }
    setState(() => _playing = true);
  }

  void _stop() {
    _timer?.cancel();
    _tone.stop();
    _bars.stop();
    if (mounted) setState(() => _playing = false);
  }

  void _setFreq(double v) {
    setState(() {
      switch (_tool) {
        case _Tool.water:
          _water = v;
        case _Tool.dust:
          _dust = v;
        case _Tool.sound:
          _sound = v;
      }
    });
    if (_playing) _tone.update(freq: v);
  }

  String get _status {
    if (_tool == _Tool.sound) {
      if (_sweep) return l10n.toolsSweepStatus;
      return switch (_side) {
        1 => l10n.toolsLeftOnly,
        2 => l10n.toolsRightOnly,
        _ => l10n.toolsSteady,
      };
    }
    final tail = _playing ? l10n.toolsTimeLeft('00:${_left.toString().padLeft(2, '0')}') : '00:$_runSeconds';
    return l10n.toolsPulsing(tail);
  }

  @override
  Widget build(BuildContext context) {
    final (lo, hi) = _range;
    final f = _freq.clamp(lo, hi);
    final bottom = MediaQuery.paddingOf(context).bottom + 96;
    return ColoredBox(
      color: SweeepColors.background,
      child: Stack(children: [
      const GlowOrb(left: 40, top: 150, width: 310, height: 250, color: Color(0x17B8A6FF), blur: 70),
      SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
          children: [
            SizedBox(height: 40, child: Align(alignment: Alignment.centerLeft, child: Text(l10n.navTools, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)))),
            const SizedBox(height: 14),
            _Segments(tool: _tool, onChanged: _pick),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: SweeepColors.cardBorder)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(_sweep && _tool == _Tool.sound ? '···' : f.round().toString(), style: const TextStyle(fontSize: 72, height: 1, fontWeight: FontWeight.w800, letterSpacing: -3)),
                  const SizedBox(width: 6),
                  Text(l10n.unitHz, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: SweeepColors.brand)),
                ]),
                const SizedBox(height: 14),
                _Bars(controller: _bars, active: _playing),
                const SizedBox(height: 14),
                if (!(_tool == _Tool.sound && _sweep)) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(l10n.hz('${lo.round()}'), style: const TextStyle(fontSize: 12, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                    Text(hi >= 1000 ? l10n.khz('${(hi / 1000).round()}') : l10n.hz('${hi.round()}'), style: const TextStyle(fontSize: 12, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
                  ]),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: SweeepColors.brand,
                      inactiveTrackColor: const Color(0xFF262833),
                      thumbColor: SweeepColors.text,
                      overlayColor: SweeepColors.brand.withValues(alpha: .12),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Semantics(
                      label: l10n.toolsFrequency,
                      child: Slider(min: lo, max: hi, value: f, onChanged: _setFreq),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(_status, style: const TextStyle(fontSize: 13, color: SweeepColors.textMuted, fontWeight: FontWeight.w600)),
              ]),
            ),
            if (_tool == _Tool.sound) ...[
              const SizedBox(height: 14),
              _SoundPresets(
                side: _side,
                sweep: _sweep,
                onSide: (s) {
                  setState(() => _side = s);
                  if (_playing) _tone.update(side: s);
                },
                onSweep: (v) {
                  setState(() => _sweep = v);
                  if (_playing) _tone.update(sweep: v);
                },
                onPreset: (hz) {
                  setState(() => _sweep = false);
                  _setFreq(hz);
                  if (_playing) _tone.update(sweep: false);
                },
              ),
            ],
            const SizedBox(height: 14),
            _MainButton(
              label: _playing ? l10n.toolsStop : switch (_tool) {
                _Tool.water => l10n.toolsEject,
                _Tool.dust => l10n.toolsShake,
                _Tool.sound => l10n.toolsPlay,
              },
              playing: _playing,
              onPressed: _playing ? _stop : _start,
            ),
            const SizedBox(height: 14),
            const _Warning(),
          ],
        ),
      ),
    ]));
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.tool, required this.onChanged});
  final _Tool tool;
  final ValueChanged<_Tool> onChanged;

  static Map<_Tool, String> get _labels => {_Tool.water: l10n.toolsWater, _Tool.dust: l10n.toolsDust, _Tool.sound: l10n.toolsSound};

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: SweeepColors.cardBorder)),
        child: Row(children: [
          for (final t in _Tool.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == tool,
                label: _labels[t],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t == tool ? SweeepColors.brand : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                    child: Text(_labels[t]!, style: TextStyle(fontSize: 14, fontWeight: t == tool ? FontWeight.w800 : FontWeight.w700, color: t == tool ? SweeepColors.onAccent : SweeepColors.textMuted)),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// Twelve bars that breathe with a 0.1 s stagger, like the prototype's `bar` keyframes.
class _Bars extends StatelessWidget {
  const _Bars({required this.controller, required this.active});
  final AnimationController controller;
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 84,
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) => Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            for (var i = 0; i < 12; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              _bar(i),
            ],
          ]),
        ),
      );

  Widget _bar(int i) {
    final ms = controller.value * 1100 - i * 100;
    final p = (((ms % 1100) + 1100) % 1100) / 1100;
    // scaleY .25 -> 1 -> .25, ease-in-out
    final k = Curves.easeInOut.transform(p < .5 ? p * 2 : (1 - p) * 2);
    final h = active ? 84 * (.25 + .75 * k) : 84 * .25;
    return Container(width: 8, height: h, decoration: BoxDecoration(color: SweeepColors.brand, borderRadius: BorderRadius.circular(4)));
  }
}

class _SoundPresets extends StatelessWidget {
  const _SoundPresets({required this.side, required this.sweep, required this.onSide, required this.onSweep, required this.onPreset});
  final int side;
  final bool sweep;
  final ValueChanged<int> onSide;
  final ValueChanged<bool> onSweep;
  final ValueChanged<double> onPreset;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        _Chip(l10n.toolsBoth, side == 0, () => onSide(0)),
        _Chip(l10n.toolsLeft, side == 1, () => onSide(1)),
        _Chip(l10n.toolsRight, side == 2, () => onSide(2)),
        _Chip(l10n.toolsBass, false, () => onPreset(60)),
        _Chip(l10n.toolsTreble, false, () => onPreset(8000)),
        _Chip(l10n.toolsSweep, sweep, () => onSweep(!sweep)),
      ]);
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.on, this.onTap);
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? SweeepColors.brand.withValues(alpha: .16) : SweeepColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: on ? SweeepColors.brand.withValues(alpha: .5) : SweeepColors.cardBorder),
            ),
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? SweeepColors.brand : SweeepColors.textMutedSmall)),
          ),
        ),
      );
}

class _MainButton extends StatelessWidget {
  const _MainButton({required this.label, required this.playing, required this.onPressed});
  final String label;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: neonGlow(SweeepColors.brand)),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(backgroundColor: SweeepColors.brand, foregroundColor: SweeepColors.onAccent, shape: const StadiumBorder()),
            child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
      );
}

class _Warning extends StatelessWidget {
  const _Warning();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SweeepColors.trash.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SweeepColors.trash.withValues(alpha: .35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.warning_amber_rounded, size: 20, color: SweeepColors.trash)),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.toolsWarning, style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500))),
        ]),
      );
}
