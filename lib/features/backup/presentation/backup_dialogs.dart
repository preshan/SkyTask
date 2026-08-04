import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/content_providers.dart';
import '../../../core/di/providers.dart';
import '../../calendar/presentation/providers/calendar_providers.dart';
import '../data/backup_crypto.dart';
import '../data/backup_folder_service.dart';
import '../data/backup_models.dart';
import '../data/backup_service.dart';

Future<void> showPickBackupFolderFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final status = await BackupFolderService.instance.ensureStoragePermission();
  if (!context.mounted) return;

  if (status.isPermanentlyDenied) {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Storage permission'),
        content: const Text(
          'Allow storage access in system Settings so SkyTask can save backups '
          'to your chosen folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (open == true) await openAppSettings();
    return;
  }

  String? path;
  try {
    path = await BackupFolderService.instance.pickFolder();
  } on BackupFolderNotWritableException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
    return;
  }
  if (!context.mounted) return;
  if (path == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No folder selected')),
    );
    return;
  }
  ref.read(backupFolderPathProvider.notifier).state = path;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Backup folder set to ${p.basename(path)}')),
  );
}

Future<void> showExportBackupFlow(BuildContext context, WidgetRef ref) async {
  var folder = ref.read(backupFolderPathProvider) ??
      await BackupFolderService.instance.getPath();

  // Drop a previously saved folder Android will not let us write to (e.g. Alarms).
  if (folder != null &&
      !await BackupFolderService.instance.canWriteTo(folder)) {
    await BackupFolderService.instance.clear();
    ref.read(backupFolderPathProvider.notifier).state = null;
    folder = null;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Previous backup folder is not writable. '
            'Pick Download or Documents.',
          ),
        ),
      );
    }
  }

  if (folder == null || folder.isEmpty) {
    if (!context.mounted) return;
    final setNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose backup folder'),
        content: const Text(
          'Pick Download or Documents (not Alarms / Ringtones). '
          'You may be asked for storage permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choose folder'),
          ),
        ],
      ),
    );
    if (setNow != true || !context.mounted) return;
    await showPickBackupFolderFlow(context, ref);
    folder = ref.read(backupFolderPathProvider);
    if (folder == null || folder.isEmpty || !context.mounted) return;
  }
  if (!context.mounted) return;

  final choice = await showModalBottomSheet<_ExportChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.lock_open_outlined),
            title: const Text('Export without password'),
            onTap: () => Navigator.pop(ctx, _ExportChoice.plain),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Export with password'),
            onTap: () => Navigator.pop(ctx, _ExportChoice.password),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  String? password;
  if (choice == _ExportChoice.password) {
    password = await _askNewPassword(context);
    if (password == null || !context.mounted) return;
    await _waitForDialogSettle(context);
    if (!context.mounted) return;
  }

  try {
    late Uint8List bytes;
    await _runWithProgress(context, 'Creating backup…', () async {
      bytes = await BackupService().exportBytes(password: password);
    });
    if (!context.mounted) return;
    await _waitForDialogSettle(context);
    if (!context.mounted) return;

    // Save after progress closes — SAF save UI must not sit under an overlay.
    final file = await BackupService().saveBytesToUserLocation(
      bytes,
      directoryPath: folder,
    );
    if (!context.mounted) return;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save cancelled')),
      );
      return;
    }

    final action = await showDialog<_AfterExportAction>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup saved'),
        content: Text(file.path),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _AfterExportAction.done),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _AfterExportAction.share),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (!context.mounted || action != _AfterExportAction.share) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'SkyTask backup'),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not save backup: $e')),
    );
  }
}

Future<void> showImportBackupFlow(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.any,
    withData: true,
  );
  if (picked == null || picked.files.isEmpty || !context.mounted) return;
  final file = picked.files.first;
  Uint8List? bytes = file.bytes;
  if (bytes == null && file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null || !context.mounted) return;
  await _importBytesFlow(context, ref, Uint8List.fromList(bytes));
}

Future<void> _importBytesFlow(
  BuildContext context,
  WidgetRef ref,
  Uint8List bytes,
) async {
  if (!BackupCrypto.looksLikeBackup(bytes)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('That file is not a SkyTask backup')),
    );
    return;
  }

  String? password;
  if (BackupCrypto.isPasswordProtected(bytes)) {
    password = await _askUnlockPassword(context);
    if (password == null || !context.mounted) return;
    await _waitForDialogSettle(context);
    if (!context.mounted) return;
  }

  final mode = await showDialog<BackupImportMode>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      title: const Text('Import backup'),
      content: const Text(
        'Replace removes current tasks, reminders, ideas, and notes. '
        'Merge keeps existing items and updates matching ones by ID.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, BackupImportMode.merge),
          child: const Text('Merge'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, BackupImportMode.replace),
          child: const Text('Replace all'),
        ),
      ],
    ),
  );
  if (mode == null || !context.mounted) return;

  try {
    await _runWithProgress(context, 'Importing…', () async {
      await BackupService().importBytes(
        bytes,
        password: password,
        mode: mode,
      );
    });
    if (!context.mounted) return;
    refreshTasks(ref);
    refreshIdeas(ref);
    refreshNotes(ref);
    refreshReminders(ref);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup imported')),
    );
  } on BackupPasswordException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import failed: $e')),
    );
  }
}

Future<String?> _askNewPassword(BuildContext context) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => const _NewBackupPasswordDialog(),
  );
}

Future<String?> _askUnlockPassword(BuildContext context) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => const _UnlockBackupPasswordDialog(),
  );
}

/// Wait long enough for a dialog route + keyboard to finish leaving.
Future<void> _waitForDialogSettle(BuildContext context) async {
  FocusManager.instance.primaryFocus?.unfocus();
  // Material dialog transition is ~200ms; one frame is not enough.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (!context.mounted) return;
  await WidgetsBinding.instance.endOfFrame;
}

Future<void> _runWithProgress(
  BuildContext context,
  String label,
  Future<void> Function() work,
) async {
  await _waitForDialogSettle(context);
  if (!context.mounted) return;

  // Use an Overlay entry — not another Navigator dialog — so we never stack
  // on top of a password dialog that is still animating out.
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    await work();
    return;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Material(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 20),
                Flexible(child: Text(label)),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    await work();
  } finally {
    entry.remove();
    if (context.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}

enum _ExportChoice { plain, password }

enum _AfterExportAction { share, done }

class _NewBackupPasswordDialog extends StatefulWidget {
  const _NewBackupPasswordDialog();

  @override
  State<_NewBackupPasswordDialog> createState() =>
      _NewBackupPasswordDialogState();
}

class _NewBackupPasswordDialogState extends State<_NewBackupPasswordDialog> {
  late final TextEditingController _pass;
  late final TextEditingController _confirm;

  @override
  void initState() {
    super.initState();
    _pass = TextEditingController();
    _confirm = TextEditingController();
  }

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _continue() {
    if (_pass.text.isEmpty) return;
    if (_pass.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    final value = _pass.text;
    FocusScope.of(context).unfocus();
    Navigator.of(context, rootNavigator: true).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pass,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              onSubmitted: (_) => _continue(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _continue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _UnlockBackupPasswordDialog extends StatefulWidget {
  const _UnlockBackupPasswordDialog();

  @override
  State<_UnlockBackupPasswordDialog> createState() =>
      _UnlockBackupPasswordDialogState();
}

class _UnlockBackupPasswordDialogState
    extends State<_UnlockBackupPasswordDialog> {
  late final TextEditingController _pass;

  @override
  void initState() {
    super.initState();
    _pass = TextEditingController();
  }

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter backup password'),
      content: TextField(
        controller: _pass,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Password'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Unlock'),
        ),
      ],
    );
  }

  void _submit() {
    final value = _pass.text;
    FocusScope.of(context).unfocus();
    Navigator.of(context, rootNavigator: true).pop(value);
  }
}
