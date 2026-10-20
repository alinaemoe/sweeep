import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';

/// Minimal player on top of a video card: one play button, then tap the
/// picture to pause or resume, drag the thin bar to scrub, time on the right.
/// Nothing else. It plays the MediaStore video straight from its content URI.
class VideoLayer extends StatefulWidget {
  const VideoLayer({super.key, required this.id});
  final String id;

  @override
  State<VideoLayer> createState() => _VideoLayerState();
}

class _VideoLayerState extends State<VideoLayer> with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _c?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.removeListener(_tick);
    _c?.dispose();
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _open() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final c = VideoPlayerController.contentUri(Uri.parse('content://media/external/video/media/${widget.id}'));
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.play();
    } catch (_) {
      await c.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    c.addListener(_tick);
    setState(() {
      _c = c;
      _loading = false;
    });
  }

  void _toggle() {
    final c = _c;
    if (c == null) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) {
      // before playing: just a round play button on the poster
      return Center(
        child: Semantics(
          button: true,
          label: l10n.videoPlay,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _open,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .55), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .25))),
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 3, color: SweeepColors.text))
                    : const Icon(Icons.play_arrow_rounded, size: 46, color: SweeepColors.text),
              ),
              if (_failed) ...[
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .7), borderRadius: BorderRadius.circular(12)),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: Text(l10n.videoFailed, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                ),
              ],
            ]),
          ),
        ),
      );
    }

    final v = c.value;
    final playing = v.isPlaying;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(fit: StackFit.expand, children: [
        // the picture, filling the card like the poster did
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(width: v.size.width, height: v.size.height, child: VideoPlayer(c)),
        ),
        // tap anywhere on it: pause / resume
        Semantics(
          button: true,
          label: playing ? l10n.videoPause : l10n.videoPlay,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _toggle, child: const SizedBox.expand()),
        ),
        // a calm play mark while paused
        IgnorePointer(
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: playing ? 0 : 1,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .55), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .25))),
                child: const Icon(Icons.play_arrow_rounded, size: 46, color: SweeepColors.text),
              ),
            ),
          ),
        ),
        // thin scrub bar and the time, above the date pill
        Positioned(
          left: 18,
          right: 18,
          bottom: 70,
          child: DecoratedBox(
            decoration: BoxDecoration(color: SweeepColors.background.withValues(alpha: .5), borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Row(children: [
                Expanded(
                  child: VideoProgressIndicator(
                    c,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    colors: const VideoProgressColors(playedColor: SweeepColors.brand, bufferedColor: Colors.white24, backgroundColor: Colors.white12),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_fmt(v.position)} / ${_fmt(v.duration)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SweeepColors.text)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
