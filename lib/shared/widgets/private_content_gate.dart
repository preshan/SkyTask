import 'package:flutter/material.dart';

import '../../features/privacy/data/pin_storage_service.dart';
import '../../features/privacy/data/privacy_auth_service.dart';
import '../../features/privacy/presentation/widgets/pin_entry_pad.dart';
import 'sky_icon.dart';

/// Masks private content until biometric or app PIN auth succeeds.
///
/// Pass the real content as [child] — this gate shows a lock tile until unlock,
/// then reveals [child] unchanged.
class PrivateContentGate extends StatefulWidget {
  const PrivateContentGate({
    super.key,
    required this.isPrivate,
    required this.child,
    this.hiddenLabel = 'Hidden Content',
  });

  final bool isPrivate;
  final Widget child;
  final String hiddenLabel;

  @override
  State<PrivateContentGate> createState() => _PrivateContentGateState();
}

class _PrivateContentGateState extends State<PrivateContentGate> {
  bool _unlocked = false;
  bool _showPinPad = false;
  String? _error;

  Future<void> _unlockWithBiometrics() async {
    final ok = await PrivacyAuthService.instance.authenticateWithBiometrics(
      reason: 'Unlock private item',
    );
    if (ok && mounted) setState(() => _unlocked = true);
  }

  Future<void> _unlockWithPin(String pin) async {
    final ok = await PrivacyAuthService.instance.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _unlocked = true;
        _showPinPad = false;
      });
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  Future<void> _unlock() async {
    final method = await PinStorageService.instance.getAuthMethod();
    if (!mounted) return;
    if (method == AuthMethod.pin) {
      setState(() {
        _showPinPad = true;
        _error = null;
      });
    } else {
      await _unlockWithBiometrics();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPrivate || _unlocked) return widget.child;

    if (_showPinPad) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unlock private item'),
              const SizedBox(height: 16),
              PinEntryPad(
                errorText: _error,
                onCompleted: _unlockWithPin,
              ),
              TextButton(
                onPressed: () => setState(() => _showPinPad = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }

    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.15,
          fontWeight: FontWeight.w600,
        );

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      minVerticalPadding: 4,
      title: Text(
        'Private Item',
        style: titleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            SkyIcon(SkyIcons.lock, size: 14, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.hiddenLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: muted,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      trailing: const SkyIcon(SkyIcons.chevronRight, size: 18),
      onTap: _unlock,
    );
  }
}
