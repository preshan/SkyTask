import 'package:equatable/equatable.dart';

import '../../../../core/services/voice_memo_service.dart';

class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    this.content = '',
    this.attachments = const [],
    this.isPrivate = false,
    this.voicePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final List<String> attachments;
  final bool isPrivate;
  final String? voicePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVoice => VoiceMemoService.hasVoice(voicePath);

  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? attachments,
    bool? isPrivate,
    String? voicePath,
    bool clearVoicePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      isPrivate: isPrivate ?? this.isPrivate,
      voicePath: clearVoicePath ? null : (voicePath ?? this.voicePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        attachments,
        isPrivate,
        voicePath,
        createdAt,
        updatedAt,
      ];
}
