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
    this.dueTimeMinutes,
    this.durationMinutes = 30,
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
  /// Minutes from midnight when this task is timed on the Day Plan; null = untimed.
  final int? dueTimeMinutes;
  final int durationMinutes;
  final bool completed;
  final bool pinned;
  final bool archived;
  final bool isPrivate;
  final String? voicePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVoice => VoiceMemoService.hasVoice(voicePath);

  bool get isTimed => dueDate != null && dueTimeMinutes != null;

  /// Start datetime when [isTimed]; otherwise null.
  DateTime? get plannedStart {
    if (!isTimed) return null;
    final d = dueDate!;
    return DateTime(d.year, d.month, d.day)
        .add(Duration(minutes: dueTimeMinutes!));
  }

  DateTime? get plannedEnd {
    final start = plannedStart;
    if (start == null) return null;
    return start.add(Duration(minutes: durationMinutes.clamp(5, 24 * 60)));
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    List<String>? tags,
    String? category,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? dueTimeMinutes,
    bool clearDueTimeMinutes = false,
    int? durationMinutes,
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
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTimeMinutes: clearDueTimeMinutes
          ? null
          : (dueTimeMinutes ?? this.dueTimeMinutes),
      durationMinutes: durationMinutes ?? this.durationMinutes,
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
        dueTimeMinutes,
        durationMinutes,
        completed,
        pinned,
        archived,
        isPrivate,
        voicePath,
        createdAt,
        updatedAt,
      ];
}
