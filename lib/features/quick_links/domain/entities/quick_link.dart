import 'package:equatable/equatable.dart';

import '../../../../core/constants/task_categories.dart';

class QuickLink extends Equatable {
  const QuickLink({
    required this.id,
    required this.title,
    required this.url,
    this.notes = '',
    this.category = TaskCategories.personal,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String url;
  final String notes;
  final String category;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuickLink copyWith({
    String? id,
    String? title,
    String? url,
    String? notes,
    String? category,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuickLink(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        notes,
        category,
        isPrivate,
        createdAt,
        updatedAt,
      ];
}
