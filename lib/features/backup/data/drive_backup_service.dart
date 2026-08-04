import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'backup_models.dart';

/// Google Drive storage under a "SkyTask Backups" folder (drive.file scope).
class DriveBackupService {
  DriveBackupService._();
  static final DriveBackupService instance = DriveBackupService._();

  static const folderName = 'SkyTask Backups';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    final existing = _googleSignIn.currentUser;
    if (existing != null) return existing;
    return _googleSignIn.signIn();
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _api() async {
    final account = await signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled');
    }
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw StateError('Could not authorize Google Drive');
    }
    return drive.DriveApi(client);
  }

  Future<String> _ensureFolderId(drive.DriveApi api) async {
    final listed = await api.files.list(
      q: "name = '$folderName' and "
          "mimeType = 'application/vnd.google-apps.folder' and "
          'trashed = false',
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    final existing = listed.files;
    if (existing != null && existing.isNotEmpty && existing.first.id != null) {
      return existing.first.id!;
    }

    final created = await api.files.create(
      drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    if (created.id == null) {
      throw StateError('Could not create Drive folder');
    }
    return created.id!;
  }

  Future<drive.File> uploadBackup({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final api = await _api();
    final folderId = await _ensureFolderId(api);
    final media = drive.Media(
      Stream<List<int>>.fromIterable([bytes]),
      bytes.length,
      contentType: 'application/octet-stream',
    );
    return api.files.create(
      drive.File()
        ..name = fileName
        ..parents = [folderId],
      uploadMedia: media,
    );
  }

  Future<List<DriveBackupItem>> listBackups({int pageSize = 20}) async {
    final api = await _api();
    final folderId = await _ensureFolderId(api);
    final listed = await api.files.list(
      q: "'$folderId' in parents and trashed = false",
      orderBy: 'modifiedTime desc',
      pageSize: pageSize,
      $fields: 'files(id, name, modifiedTime, size)',
    );
    final files = listed.files ?? [];
    return files
        .where((f) => f.id != null && f.name != null)
        .map(
          (f) => DriveBackupItem(
            id: f.id!,
            name: f.name!,
            modifiedTime: f.modifiedTime,
            size: int.tryParse(f.size ?? ''),
          ),
        )
        .toList();
  }

  Future<Uint8List> downloadBackup(String fileId) async {
    final api = await _api();
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }
}
