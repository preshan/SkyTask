import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory {
  work,
  personal,
  health,
  finance,
  study,
  shopping,
  custom,
}

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.tags = const [],
    this.category = TaskCategory.personal,
    this.dueDate,
    this.completed = false,
    this.pinned = false,
    this.archived = false,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final List<String> tags;
  final TaskCategory category;
  final DateTime? dueDate;
  final bool completed;
  final bool pinned;
  final bool archived;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    List<String>? tags,
    TaskCategory? category,
    DateTime? dueDate,
    bool? completed,
    bool? pinned,
    bool? archived,
    bool? isPrivate,
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
        createdAt,
        updatedAt,
      ];
}
