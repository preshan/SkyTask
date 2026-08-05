import 'package:equatable/equatable.dart';

import '../../../../core/constants/task_categories.dart';
import '../../../../core/services/voice_memo_service.dart';

class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    this.content = '',
    this.category = TaskCategories.personal,
    this.attachments = const [],
    this.isPrivate = false,
    this.voicePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String category;
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
    String? category,
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
      category: category ?? this.category,
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
        category,
        attachments,
        isPrivate,
        voicePath,
        createdAt,
        updatedAt,
      ];
}
