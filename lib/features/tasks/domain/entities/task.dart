import 'package:equatable/equatable.dart';

import '../../../../core/constants/task_categories.dart';
import '../../../../core/services/voice_memo_service.dart';

enum TaskPriority { low, medium, high }

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.tags = const [],
    this.category = TaskCategories.personal,
    this.dueDate,
    this.completed = false,
    this.pinned = false,
    this.archived = false,
    this.isPrivate = false,
    this.voicePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final List<String> tags;
  /// Display name (e.g. Work, Personal, or a user-added label).
  final String category;
  final DateTime? dueDate;
  final bool completed;
  final bool pinned;
  final bool archived;
  final bool isPrivate;
  final String? voicePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVoice => VoiceMemoService.hasVoice(voicePath);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    List<String>? tags,
    String? category,
    DateTime? dueDate,
    bool? completed,
    bool? pinned,
    bool? archived,
    bool? isPrivate,
    String? voicePath,
    bool clearVoicePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
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
        description,
        priority,
        tags,
        category,
        dueDate,
        completed,
        pinned,
        archived,
        isPrivate,
        voicePath,
        createdAt,
        updatedAt,
      ];
}
