import 'package:isar/isar.dart';

import '../../../../core/database/isar_collections.dart' as isar;
import '../../domain/entities/note.dart';

class NoteMapper {
  static Note fromCollection(isar.NoteCollection c) {
    return Note(
      id: c.uuid,
      title: c.title,
      content: c.content,
      attachments: List.from(c.attachments),
      isPrivate: c.isPrivate,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.NoteCollection toCollection(Note note) {
    return isar.NoteCollection()
      ..uuid = note.id
      ..title = note.title
      ..content = note.content
      ..attachments = List.from(note.attachments)
      ..isPrivate = note.isPrivate
      ..createdAt = note.createdAt
      ..updatedAt = note.updatedAt;
  }
}
