import 'package:isar/isar.dart';

import '../../../../core/database/isar_collections.dart' as isar;
import '../../domain/entities/idea.dart';

class IdeaMapper {
  static Idea fromCollection(isar.IdeaCollection c) {
    return Idea(
      id: c.uuid,
      title: c.title,
      content: c.content,
      tags: List.from(c.tags),
      isPrivate: c.isPrivate,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.IdeaCollection toCollection(Idea idea) {
    return isar.IdeaCollection()
      ..uuid = idea.id
      ..title = idea.title
      ..content = idea.content
      ..tags = List.from(idea.tags)
      ..isPrivate = idea.isPrivate
      ..createdAt = idea.createdAt
      ..updatedAt = idea.updatedAt;
  }
}
