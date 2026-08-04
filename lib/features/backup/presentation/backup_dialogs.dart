import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/content_providers.dart';
import '../../calendar/presentation/providers/calendar_providers.dart';
import '../data/backup_crypto.dart';
import '../data/backup_models.dart';
import '../data/backup_service.dart';
import '../data/drive_backup_service.dart';

Future<void> showExportBackupFlow(BuildContext context, WidgetRef ref) async {
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
  }

  await _runWithProgress(context, 'Creating backup…', () async {
    final service = BackupService();
    final file = await service.exportToFile(password: password);
    if (!context.mounted) return;
    final action = await showDialog<_AfterExportAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup ready'),
        content: Text(p.basename(file.path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _AfterExportAction.share),
            child: const Text('Share / save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _AfterExportAction.drive),
            child: const Text('Upload to Drive'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _AfterExportAction.done),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == _AfterExportAction.share) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'SkyTask backup'),
      );
    } else if (action == _AfterExportAction.drive) {
      await _uploadFileToDrive(context, file);
    }
  });
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

Future<void> showDriveBackupsSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _DriveBackupsSheet(),
  );
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
  }

  final mode = await showDialog<BackupImportMode>(
    context: context,
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

Future<void> _uploadFileToDrive(BuildContext context, File file) async {
  try {
    await _runWithProgress(context, 'Uploading to Google Drive…', () async {
      final bytes = await file.readAsBytes();
      await DriveBackupService.instance.uploadBackup(
        fileName: p.basename(file.path),
        bytes: Uint8List.fromList(bytes),
      );
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploaded to Google Drive → SkyTask Backups')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Drive upload failed: $e')),
    );
  }
}

Future<String?> _askNewPassword(BuildContext context) async {
  final pass = TextEditingController();
  final confirm = TextEditingController();
  try {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pass,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (pass.text.isEmpty) return;
              if (pass.text != confirm.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(ctx, pass.text);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  } finally {
    Future<void>.delayed(const Duration(seconds: 1), () {
      pass.dispose();
      confirm.dispose();
    });
  }
}

Future<String?> _askUnlockPassword(BuildContext context) async {
  final pass = TextEditingController();
  try {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter backup password'),
        content: TextField(
          controller: pass,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, pass.text),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  } finally {
    Future<void>.delayed(const Duration(seconds: 1), pass.dispose);
  }
}

Future<void> _runWithProgress(
  BuildContext context,
  String label,
  Future<void> Function() work,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    ),
  );
  try {
    await work();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

enum _ExportChoice { plain, password }

enum _AfterExportAction { share, drive, done }

class _DriveBackupsSheet extends ConsumerStatefulWidget {
  const _DriveBackupsSheet();

  @override
  ConsumerState<_DriveBackupsSheet> createState() => _DriveBackupsSheetState();
}

class _DriveBackupsSheetState extends ConsumerState<_DriveBackupsSheet> {
  bool _loading = true;
  String? _error;
  List<DriveBackupItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await DriveBackupService.instance.signIn();
      final items = await DriveBackupService.instance.listBackups();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _uploadNew() async {
    final navigator = Navigator.of(context);
    final choice = await showModalBottomSheet<_ExportChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Without password'),
              onTap: () => Navigator.pop(ctx, _ExportChoice.plain),
            ),
            ListTile(
              title: const Text('With password'),
              onTap: () => Navigator.pop(ctx, _ExportChoice.password),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    String? password;
    if (choice == _ExportChoice.password) {
      password = await _askNewPassword(context);
      if (password == null || !mounted) return;
    }
    try {
      await _runWithProgress(context, 'Uploading…', () async {
        final file = await BackupService().exportToFile(password: password);
        final bytes = await file.readAsBytes();
        await DriveBackupService.instance.uploadBackup(
          fileName: p.basename(file.path),
          bytes: Uint8List.fromList(bytes),
        );
      });
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
    // Keep sheet open.
    if (!mounted) navigator;
  }

  Future<void> _restore(DriveBackupItem item) async {
    try {
      late Uint8List bytes;
      await _runWithProgress(context, 'Downloading…', () async {
        bytes = await DriveBackupService.instance.downloadBackup(item.id);
      });
      if (!mounted) return;
      await _importBytesFlow(context, ref, bytes);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brand(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Google Drive backups',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _loading ? null : _uploadNew,
                icon: Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.onPrimary),
                label: const Text('Create & upload backup'),
                style: FilledButton.styleFrom(backgroundColor: brand),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty)
              const Expanded(
                child: Center(child: Text('No backups in SkyTask Backups yet')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    final when = item.modifiedTime?.toLocal().toString() ?? '';
                    return ListTile(
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: Text(item.name),
                      subtitle: Text(when),
                      onTap: () => _restore(item),
                    );
                  },
                ),
              ),
            TextButton(
              onPressed: () async {
                await DriveBackupService.instance.signOut();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Sign out of Google'),
            ),
          ],
        ),
      ),
    );
  }
}
