import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/voice_memo_service.dart';
import 'sky_icon.dart';

/// Opens a voice memo player with play / pause and a seekable progress bar.
Future<void> showVoicePlayerSheet(
  BuildContext context, {
  required String path,
  String? title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => VoicePlayerSheet(path: path, title: title),
  );
}

class VoicePlayerSheet extends StatefulWidget {
  const VoicePlayerSheet({
    super.key,
    required this.path,
    this.title,
  });

  final String path;
  final String? title;

  @override
  State<VoicePlayerSheet> createState() => _VoicePlayerSheetState();
}

class _VoicePlayerSheetState extends State<VoicePlayerSheet> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _loading = true;
  bool _seeking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.onPositionChanged.listen((pos) {
      if (!mounted || _seeking) return;
      setState(() => _position = pos);
    });
    _durationSub = _player.onDurationChanged.listen((dur) {
      if (!mounted) return;
      if (dur > Duration.zero) {
        setState(() => _duration = dur);
      }
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _position = _duration;
      });
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
    });
    unawaited(_start());
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _start() async {
    if (!VoiceMemoService.hasVoice(widget.path)) {
      setState(() {
        _loading = false;
        _error = 'Voice file missing';
      });
      return;
    }

    final file = File(widget.path);
    if (!await file.exists()) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Voice file missing';
      });
      return;
    }

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setSource(DeviceFileSource(widget.path));
      final dur = await _player.getDuration();
      if (mounted && dur != null && dur > Duration.zero) {
        setState(() => _duration = dur);
      }
      await _player.resume();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not play: $e';
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_error != null || _loading) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_duration > Duration.zero && _position >= _duration) {
      await _player.seek(Duration.zero);
      setState(() => _position = Duration.zero);
    }
    await _player.resume();
  }

  Future<void> _seekTo(double valueMs) async {
    final target = Duration(milliseconds: valueMs.round());
    setState(() {
      _position = target;
      _seeking = false;
    });
    await _player.seek(target);
  }

  String _format(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final title = voicePlayerPanelTitle(widget.title);
    final maxMs = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final valueMs = _position.inMilliseconds
        .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0)
        .toDouble();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Voice recording',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppColors.brand(context),
                inactiveTrackColor:
                    AppColors.brand(context).withValues(alpha: 0.2),
                thumbColor: AppColors.brand(context),
              ),
              child: Slider(
                min: 0,
                max: maxMs,
                value: valueMs.clamp(0, maxMs),
                onChangeStart: (_) => setState(() => _seeking = true),
                onChanged: (v) => setState(
                  () => _position = Duration(milliseconds: v.round()),
                ),
                onChangeEnd: _seekTo,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    _format(_position),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  Text(
                    _format(_duration),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Material(
                color: AppColors.brand(context),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _togglePlayPause,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: SkyIcon(
                        _playing ? SkyIcons.pause : SkyIcons.play,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
