import 'package:equatable/equatable.dart';

import '../../../../core/services/voice_memo_service.dart';

class Idea extends Equatable {
  const Idea({
    required this.id,
    required this.title,
    this.content = '',
    this.tags = const [],
    this.isPrivate = false,
    this.voicePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool isPrivate;
  final String? voicePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVoice => VoiceMemoService.hasVoice(voicePath);

  Idea copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? isPrivate,
    String? voicePath,
    bool clearVoicePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isPrivate: isPrivate ?? this.isPrivate,
      voicePath: clearVoicePath ? null : (voicePath ?? this.voicePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, content, tags, isPrivate, voicePath, createdAt, updatedAt];
}
