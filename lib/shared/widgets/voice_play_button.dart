import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/voice_memo_service.dart';

/// Compact play/pause control for voice items in lists.
class VoicePlayButton extends StatefulWidget {
  const VoicePlayButton({super.key, required this.path});

  final String path;

  @override
  State<VoicePlayButton> createState() => _VoicePlayButtonState();
}

class _VoicePlayButtonState extends State<VoicePlayButton> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!VoiceMemoService.hasVoice(widget.path)) return;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }

    final file = File(widget.path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice file missing')),
        );
      }
      return;
    }

    try {
      await _player.stop();
      await _player.play(DeviceFileSource(widget.path));
      if (mounted) setState(() => _playing = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _playing ? 'Pause' : 'Play voice memo',
      onPressed: _toggle,
      icon: Icon(
        _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
        color: AppColors.brand(context),
        size: 28,
      ),
    );
  }
}
