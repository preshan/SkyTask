import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/providers.dart';
import '../../data/pin_storage_service.dart';
import '../../data/privacy_auth_service.dart';
import '../widgets/pin_entry_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  AuthMethod? _authMethod;
  String? _error;
  final _pinPadKey = GlobalKey<PinEntryPadState>();

  @override
  void initState() {
    super.initState();
    _loadAuthMethod();
  }

  Future<void> _loadAuthMethod() async {
    final method = await PinStorageService.instance.getAuthMethod();
    if (mounted) setState(() => _authMethod = method);
  }

  Future<void> _unlockWithBiometrics() async {
    final ok = await PrivacyAuthService.instance.authenticateWithBiometrics(
      reason: 'Unlock SkyTask',
    );
    if (ok) ref.read(privacyLockProvider.notifier).unlock();
  }

  Future<void> _unlockWithPin(String pin) async {
    final ok = await PrivacyAuthService.instance.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      ref.read(privacyLockProvider.notifier).unlock();
    } else {
      setState(() => _error = 'Incorrect PIN. Try again.');
      _pinPadKey.currentState?.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _authMethod == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _authMethod == AuthMethod.pin
                      ? _buildPinUnlock(context)
                      : _buildBiometricUnlock(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricUnlock(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 72, color: Colors.white),
        const SizedBox(height: 24),
        Text(
          'SkyTask Locked',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Use fingerprint or face to unlock',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _unlockWithBiometrics,
          icon: const Icon(Icons.fingerprint),
          label: const Text('Unlock'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            minimumSize: const Size(200, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildPinUnlock(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 56, color: Colors.white),
        const SizedBox(height: 16),
        Text(
          'Enter your PIN',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 32),
        Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
          ),
          child: PinEntryPad(
            key: _pinPadKey,
            errorText: _error,
            onCompleted: (pin) {
              setState(() => _error = null);
              _unlockWithPin(pin);
            },
          ),
        ),
      ],
    );
  }
}
