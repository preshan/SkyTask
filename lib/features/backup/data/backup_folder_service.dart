import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// Persists the user-chosen folder for `.skytaskbak` exports.
class BackupFolderService {
  BackupFolderService._();
  static final BackupFolderService instance = BackupFolderService._();

  /// Android media dirs that look selectable but reject app writes.
  static const _restrictedNameHints = [
    'alarms',
    'ringtones',
    'notifications',
    'podcasts',
    'audiobooks',
  ];

  Future<String?> getPath([SharedPreferences? prefs]) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    final path = store.getString(AppConstants.backupFolderPathKey);
    if (path == null || path.isEmpty) return null;
    return path;
  }

  Future<void> setPath(String path, [SharedPreferences? prefs]) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    await store.setString(AppConstants.backupFolderPathKey, path);
  }

  Future<void> clear([SharedPreferences? prefs]) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    await store.remove(AppConstants.backupFolderPathKey);
  }

  /// Requests storage access when the OS still uses legacy permissions.
  Future<PermissionStatus> ensureStoragePermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;

    var status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) return status;

    status = await Permission.storage.request();
    return status;
  }

  bool isLikelyRestricted(String path) {
    final name = p.basename(path).toLowerCase();
    return _restrictedNameHints.contains(name);
  }

  /// True if we can create a short-lived probe file in [directoryPath].
  Future<bool> canWriteTo(String directoryPath) async {
    if (directoryPath.isEmpty || directoryPath == '/') return false;
    if (isLikelyRestricted(directoryPath)) return false;
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final probe = File(
        p.join(directoryPath, '.skytask_write_probe'),
      );
      await probe.writeAsString('ok', flush: true);
      if (await probe.exists()) {
        await probe.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system folder picker. Returns path only if writable.
  /// Throws [BackupFolderNotWritableException] if the OS rejects writes.
  Future<String?> pickFolder() async {
    final status = await ensureStoragePermission();
    if (status.isPermanentlyDenied) {
      return null;
    }

    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose backup folder (Download or Documents)',
    );
    if (path == null || path.isEmpty || path == '/') return null;

    if (!await canWriteTo(path)) {
      throw BackupFolderNotWritableException(path);
    }

    await setPath(path);
    return path;
  }

  String displayLabel(String? path) {
    if (path == null || path.isEmpty) return 'Not set — tap to choose';
    final name = p.basename(path);
    if (name.isEmpty) return path;
    return name;
  }
}

class BackupFolderNotWritableException implements Exception {
  BackupFolderNotWritableException(this.path);
  final String path;

  @override
  String toString() =>
      'Android does not allow apps to write to “${p.basename(path)}”. '
      'Choose Download or Documents instead.';
}
