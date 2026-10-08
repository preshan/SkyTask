import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/voice_memo_service.dart';
import 'confirm_delete_dialog.dart';
import 'sky_icon.dart';
import 'voice_player_sheet.dart';

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
    this.titleBuilder,
  });

  final String? initialPath;
  final ValueChanged<String?> onChanged;
  final VoiceMemoController? controller;
  final bool enabled;

  /// Current item title from the parent form (read when opening the player).
  final String? Function()? titleBuilder;

  @override
  State<VoiceMemoRecorder> createState() => _VoiceMemoRecorderState();
}

class _VoiceMemoRecorderState extends State<VoiceMemoRecorder> {
  final _recorder = AudioRecorder();

  String? _path;
  String? _activeRecordPath;
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    widget.controller?._bind(this);
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
      }());
    } else {
      unawaited(_recorder.dispose());
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
          const SnackBar(content: Text('Recording failed - try again')),
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

  Future<void> _openPlayer() async {
    final path = _path;
    if (path == null || !VoiceMemoService.hasVoice(path)) return;
    await showVoicePlayerSheet(
      context,
      path: path,
      title: widget.titleBuilder?.call(),
    );
  }

  Future<void> _clear() async {
    final confirmed = await confirmDelete(
      context,
      title: 'Remove voice memo?',
      message: 'The recording will be removed from this item.',
    );
    if (!confirmed || !mounted) return;

    final old = _path;
    setState(() {
      _path = null;
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
    final brand = AppColors.brand(context);
    final scheme = Theme.of(context).colorScheme;
    final title = _recording
        ? 'Recording ${_format(_elapsed)}'
        : hasMemo
            ? 'Voice memo'
            : 'Add voice memo';
    final subtitle = _recording
        ? 'Tap stop when finished'
        : hasMemo
            ? 'Tap to play · long-press to remove'
            : 'Tap to record a voice memo';

    VoidCallback? primaryTap;
    if (!widget.enabled) {
      primaryTap = null;
    } else if (_recording) {
      primaryTap = _stop;
    } else if (hasMemo) {
      primaryTap = _openPlayer;
    } else {
      primaryTap = _start;
    }

    return PopScope(
      canPop: !_recording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_recording) return;
        await _stop();
      },
      child: Material(
        color: brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: primaryTap,
          onLongPress: widget.enabled && hasMemo && !_recording ? _clear : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (_recording)
                  _CircleAction(
                    color: AppColors.error,
                    onTap: widget.enabled ? _stop : null,
                    child: const SkyIcon(
                      SkyIcons.stop,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                else if (!hasMemo)
                  _CircleAction(
                    color: brand,
                    onTap: widget.enabled ? _start : null,
                    child: const SkyIcon(
                      SkyIcons.mic,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                else ...[
                  _CircleAction(
                    color: brand,
                    onTap: widget.enabled ? _openPlayer : null,
                    child: const SkyIcon(
                      SkyIcons.play,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CircleAction(
                    color: scheme.surfaceContainerHighest,
                    border: true,
                    onTap: widget.enabled ? _clear : null,
                    child: SkyIcon(
                      SkyIcons.close,
                      color: scheme.onSurface,
                      size: 18,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                  ),
                ),
                SkyIcon(
                  SkyIcons.chevronRight,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
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
      shape: CircleBorder(
        side: border
            ? BorderSide(color: AppColors.brand(context).withValues(alpha: 0.25))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}
