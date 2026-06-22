import 'package:equatable/equatable.dart';

class Idea extends Equatable {
  const Idea({
    required this.id,
    required this.title,
    this.content = '',
    this.tags = const [],
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Idea copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, content, tags, isPrivate, createdAt, updatedAt];
}
