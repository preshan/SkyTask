import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/sky_icon.dart';
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
  bool _hasPin = false;
  bool _usePinFallback = false;
  String? _error;
  final _pinPadKey = GlobalKey<PinEntryPadState>();

  @override
  void initState() {
    super.initState();
    _loadAuthMethod();
  }

  Future<void> _loadAuthMethod() async {
    final method = await PinStorageService.instance.getAuthMethod();
    final hasPin = await PinStorageService.instance.hasPin();
    if (!mounted) return;
    setState(() {
      _authMethod = method;
      _hasPin = hasPin;
    });
    if (method == AuthMethod.biometric) {
      // Prompt fingerprint as soon as the lock screen appears.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_usePinFallback) _unlockWithBiometrics();
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final lock = ref.read(privacyLockProvider.notifier);
    lock.setAuthInProgress(true);
    try {
      final ok = await PrivacyAuthService.instance.authenticateWithBiometrics(
        reason: 'Unlock SkyTask',
      );
      if (ok) {
        lock.unlock();
      } else if (mounted) {
        setState(() => _error = 'Authentication failed. Try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Biometrics unavailable.');
      }
    } finally {
      lock.setAuthInProgress(false);
    }
  }

  Future<void> _unlockWithPin(String pin) async {
    final lock = ref.read(privacyLockProvider.notifier);
    lock.setAuthInProgress(true);
    try {
      final ok = await PrivacyAuthService.instance.verifyPin(pin);
      if (!mounted) return;
      if (ok) {
        lock.unlock();
      } else {
        setState(() => _error = 'Incorrect PIN. Try again.');
        _pinPadKey.currentState?.clear();
      }
    } finally {
      lock.setAuthInProgress(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPin = _authMethod == AuthMethod.pin || _usePinFallback;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _authMethod == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : showPin
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
        const SkyIcon(SkyIcons.lock, size: 72, color: Colors.white),
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
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _unlockWithBiometrics,
          icon: SkyIcon(
            SkyIcons.fingerprint,
            color: AppColors.brand(context),
          ),
          label: const Text('Unlock'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.brand(context),
            minimumSize: const Size(200, 48),
          ),
        ),
        if (_hasPin) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _usePinFallback = true;
              _error = null;
            }),
            child: const Text(
              'Use PIN instead',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinUnlock(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SkyIcon(SkyIcons.lock, size: 56, color: Colors.white),
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
            lightOnDark: true,
            errorText: _error,
            onCompleted: (pin) {
              setState(() => _error = null);
              _unlockWithPin(pin);
            },
          ),
        ),
        if (_authMethod == AuthMethod.biometric && _usePinFallback) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() {
              _usePinFallback = false;
              _error = null;
            }),
            child: const Text(
              'Use fingerprint instead',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ],
    );
  }
}
