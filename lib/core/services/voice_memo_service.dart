import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Local voice memo file helpers.
abstract final class VoiceMemoService {
  static Future<Directory> directory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/voice_memos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> newFilePath() async {
    final dir = await directory();
    return '${dir.path}/${const Uuid().v4()}.m4a';
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static bool hasVoice(String? path) => path != null && path.isNotEmpty;

  static bool isPlaceholderTitle(String title) {
    final t = title.trim();
    if (t.isEmpty) return true;
    return RegExp(
      r'^Untitled (task|idea|note|reminder)$',
      caseSensitive: false,
    ).hasMatch(t);
  }

  static String formatVoiceTitle([DateTime? at]) {
    return DateFormat('MMM d, yyyy · h:mm a').format(at ?? DateTime.now());
  }
}

/// Title when the user only saved a recording (no typed title).
String voiceAwareTitle({
  required String rawTitle,
  required bool hasVoice,
  required String untitledFallback,
  DateTime? at,
}) {
  final trimmed = rawTitle.trim();
  final placeholder = VoiceMemoService.isPlaceholderTitle(trimmed);
  if (!placeholder) return trimmed;
  if (hasVoice) return VoiceMemoService.formatVoiceTitle(at);
  return untitledFallback;
}

/// List/edit display title — upgrades old "Untitled *" voice items.
String displayItemTitle({
  required String title,
  required bool isVoice,
  DateTime? createdAt,
}) {
  if (isVoice && VoiceMemoService.isPlaceholderTitle(title)) {
    return VoiceMemoService.formatVoiceTitle(createdAt);
  }
  return title;
}
