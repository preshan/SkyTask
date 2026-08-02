import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/voice_memo_service.dart';
import 'sky_icon.dart';

/// Lets parent forms finalize an in-progress recording before save.
class VoiceMemoController {
  _VoiceMemoRecorderState? _state;

  void _bind(_VoiceMemoRecorderState state) => _state = state;
  void _unbind(_VoiceMemoRecorderState state) {
    if (_state == state) _state = null;
  }

  /// Stops recording if needed and returns the current memo path.
  Future<String?> finalize() async {
    final state = _state;
    if (state == null) return null;
    return state.finalize();
  }
}

/// Record / preview / clear a voice memo for create & edit sheets.
class VoiceMemoRecorder extends StatefulWidget {
  const VoiceMemoRecorder({
    super.key,
    this.initialPath,
    required this.onChanged,
    this.controller,
    this.enabled = true,
  });

  final String? initialPath;
  final ValueChanged<String?> onChanged;
  final VoiceMemoController? controller;
  final bool enabled;

  @override
  State<VoiceMemoRecorder> createState() => _VoiceMemoRecorderState();
}

class _VoiceMemoRecorderState extends State<VoiceMemoRecorder> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  String? _path;
  String? _activeRecordPath;
  bool _recording = false;
  bool _playing = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    widget.controller?._bind(this);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void didUpdateWidget(covariant VoiceMemoRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._unbind(this);
      widget.controller?._bind(this);
    }
    if (widget.initialPath != oldWidget.initialPath &&
        widget.initialPath != null &&
        _path == null &&
        !_recording) {
      _path = widget.initialPath;
    }
  }

  @override
  void dispose() {
    widget.controller?._unbind(this);
    _ticker?.cancel();
    // Best-effort: stop an in-progress capture and drop orphan bytes.
    // PopScope blocks the first dismiss while recording so users can keep the memo.
    if (_recording) {
      final orphan = _activeRecordPath;
      _recording = false;
      unawaited(() async {
        try {
          await _recorder.stop();
        } catch (_) {}
        await VoiceMemoService.deleteIfExists(orphan);
        await _recorder.dispose();
        await _player.dispose();
      }());
    } else {
      unawaited(_recorder.dispose());
      unawaited(_player.dispose());
    }
    super.dispose();
  }

  Future<String?> finalize() async {
    if (_recording) {
      await _stop();
    }
    return _path;
  }

  Future<bool> _ensureMicPermission() async {
    if (await _recorder.hasPermission()) return true;

    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
    }
    return false;
  }

  Future<void> _start() async {
    if (!widget.enabled || _recording) return;
    if (!await _ensureMicPermission()) return;

    final path = await VoiceMemoService.newFilePath();
    _activeRecordPath = path;
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _ticker?.cancel();

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    path ??= _activeRecordPath;

    final file = path == null ? null : File(path);
    final exists = file != null && await file.exists();
    final hasBytes = exists && await file.length() > 0;

    if (!hasBytes) {
      await VoiceMemoService.deleteIfExists(path);
      path = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording failed — try again')),
        );
      }
    } else {
      // Replace previous memo only after a successful new recording.
      final previous = _path;
      if (previous != null &&
          previous != path &&
          previous != widget.initialPath) {
        await VoiceMemoService.deleteIfExists(previous);
      }
    }

    _activeRecordPath = null;
    if (!mounted) {
      widget.onChanged(path);
      return;
    }
    setState(() {
      _recording = false;
      _path = path;
    });
    widget.onChanged(path);
  }

  Future<void> _togglePlay() async {
    final path = _path;
    if (path == null) return;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice file missing')),
        );
      }
      return;
    }
    try {
      await _player.play(DeviceFileSource(path));
      setState(() => _playing = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play voice memo: $e')),
        );
      }
    }
  }

  Future<void> _clear() async {
    await _player.stop();
    final old = _path;
    setState(() {
      _path = null;
      _playing = false;
    });
    widget.onChanged(null);
    if (old != null && old != widget.initialPath) {
      await VoiceMemoService.deleteIfExists(old);
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasMemo = VoiceMemoService.hasVoice(_path);

    return PopScope(
      canPop: !_recording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_recording) return;
        await _stop();
      },
      child: Row(
        children: [
          if (_recording)
            _RoundAction(
              color: AppColors.error,
              onTap: widget.enabled ? _stop : null,
              child: const Icon(Icons.stop, color: Colors.white, size: 22),
            )
          else if (!hasMemo)
            _RoundAction(
              color: AppColors.primary,
              onTap: widget.enabled ? _start : null,
              child: const SkyIcon(SkyIcons.mic, color: Colors.white, size: 22),
            )
          else ...[
            _RoundAction(
              color: AppColors.primary,
              onTap: widget.enabled ? _togglePlay : null,
              child: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            _RoundAction(
              color: AppColors.background,
              border: true,
              onTap: widget.enabled ? _clear : null,
              child: const SkyIcon(
                SkyIcons.close,
                color: AppColors.primaryText,
                size: 18,
              ),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _recording
                  ? 'Recording ${_format(_elapsed)}'
                  : hasMemo
                      ? 'Voice memo'
                      : 'Add voice memo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: hasMemo || _recording
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.color,
    required this.child,
    this.onTap,
    this.border = false,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border
            ? BorderSide(color: AppColors.primary.withValues(alpha: 0.25))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}
