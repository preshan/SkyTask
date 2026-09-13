import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/voice_memo_service.dart';
import 'sky_icon.dart';
import 'voice_player_sheet.dart';

/// Compact play control for voice items in lists.
/// Opens the shared voice player (play / pause / seek).
class VoicePlayButton extends StatelessWidget {
  const VoicePlayButton({
    super.key,
    required this.path,
    this.title,
  });

  final String path;
  final String? title;

  Future<void> _open(BuildContext context) async {
    if (!VoiceMemoService.hasVoice(path)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice file missing')),
      );
      return;
    }
    await showVoicePlayerSheet(context, path: path, title: title);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Play voice memo',
      onPressed: () => _open(context),
      icon: SkyIcon(
        SkyIcons.playCircle,
        color: AppColors.brand(context),
        size: 28,
      ),
    );
  }
}
