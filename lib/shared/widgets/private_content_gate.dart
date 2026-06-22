import 'package:flutter/material.dart';

import '../../features/privacy/data/pin_storage_service.dart';
import '../../features/privacy/data/privacy_auth_service.dart';
import '../../features/privacy/presentation/widgets/pin_entry_pad.dart';

/// Masks private content until biometric or app PIN auth succeeds.
class PrivateContentGate extends StatefulWidget {
  const PrivateContentGate({
    super.key,
    required this.isPrivate,
    required this.title,
    required this.child,
    this.hiddenLabel = '🔒 Hidden Content',
  });

  final bool isPrivate;
  final String title;
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
      reason: 'Unlock "${widget.title}"',
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
              Text('Unlock "${widget.title}"'),
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

    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: const Text('Private Item'),
      subtitle: Text(widget.hiddenLabel),
      trailing: IconButton(
        icon: const Icon(Icons.lock_open_outlined),
        onPressed: _unlock,
      ),
      onTap: _unlock,
    );
  }
}
