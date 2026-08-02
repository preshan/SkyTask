import '../../../../core/database/isar_collections.dart' as isar;
import '../../../../core/services/private_crypto_service.dart';
import '../../domain/entities/note.dart';

class NoteMapper {
  static final _crypto = PrivateCryptoService.instance;

  static Note fromCollection(isar.NoteCollection c) {
    return Note(
      id: c.uuid,
      title: _crypto.reveal(c.title) ?? c.title,
      content: _crypto.reveal(c.content) ?? c.content,
      attachments: List.from(c.attachments),
      isPrivate: c.isPrivate,
      voicePath: c.voicePath,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  static isar.NoteCollection toCollection(Note note) {
    final private = note.isPrivate;
    return isar.NoteCollection()
      ..uuid = note.id
      ..title = _crypto.protect(note.title, isPrivate: private) ?? note.title
      ..content =
          _crypto.protect(note.content, isPrivate: private) ?? note.content
      ..attachments = List.from(note.attachments)
      ..isPrivate = note.isPrivate
      ..voicePath = note.voicePath
      ..createdAt = note.createdAt
      ..updatedAt = note.updatedAt;
  }
}
