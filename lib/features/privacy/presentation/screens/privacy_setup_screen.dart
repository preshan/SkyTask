import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/sky_atmosphere_background.dart';
import '../../../../shared/widgets/sky_icon.dart';
import '../../data/pin_storage_service.dart';
import '../../data/privacy_auth_service.dart';
import '../widgets/pin_entry_pad.dart';

enum _SetupStep { choose, createPin, confirmPin }

class PrivacySetupScreen extends ConsumerStatefulWidget {
  const PrivacySetupScreen({super.key});

  @override
  ConsumerState<PrivacySetupScreen> createState() => _PrivacySetupScreenState();
}

class _PrivacySetupScreenState extends ConsumerState<PrivacySetupScreen> {
  _SetupStep _step = _SetupStep.choose;
  String? _draftPin;
  String? _error;
  bool _loading = false;
  bool? _biometricsAvailable;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await PrivacyAuthService.instance.canUseBiometrics;
    if (mounted) setState(() => _biometricsAvailable = available);
  }

  Future<void> _finishSetup() async {
    setState(() => _loading = true);
    try {
      await ref.read(privacySetupCompleteProvider.notifier).complete();
      await ref.read(appLockEnabledProvider.notifier).setEnabled(true);
      ref.read(privacyLockProvider.notifier).lock();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not finish setup. Try again.';
        });
      }
    }
  }

  Future<void> _useBiometrics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await PrivacyAuthService.instance.authenticateWithBiometrics(
        reason: 'Confirm biometrics to secure SkyTask',
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _loading = false;
          _error = 'Biometric authentication failed. Try again or create a PIN.';
        });
        return;
      }
      await PinStorageService.instance.setBiometricMethod();
      await _finishSetup();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Biometrics unavailable. Create a PIN instead.';
      });
    }
  }

  Future<void> _onPinConfirmed(String pin) async {
    if (_loading) return;
    if (pin != _draftPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _step = _SetupStep.createPin;
        _draftPin = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await PinStorageService.instance.savePin(pin);
      await _finishSetup();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not save PIN. Try again.';
      });
    }
  }

  void _onPinCreated(String pin) {
    if (_loading) return;
    setState(() {
      _draftPin = pin;
      _step = _SetupStep.confirmPin;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SkyAtmosphereBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_step) {
              _SetupStep.choose => _buildChooseStep(context),
              _SetupStep.createPin => _buildPinStep(
                  title: 'Create your PIN',
                  subtitle:
                      'Choose a ${AppConstants.pinLength}-digit PIN to unlock SkyTask',
                  onCompleted: _onPinCreated,
                ),
              _SetupStep.confirmPin => _buildPinStep(
                  title: 'Confirm your PIN',
                  subtitle: 'Enter the same PIN again',
                  onCompleted: _onPinConfirmed,
                ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChooseStep(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        SkyIcon(SkyIcons.shield, size: 72, color: AppColors.brand(context)),
        const SizedBox(height: 24),
        Text(
          'Secure SkyTask',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Choose how you want to unlock the app. No account or Google sign-in required.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: onSurface.withValues(alpha: 0.75),
              ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        if (_biometricsAvailable == true)
          FilledButton.icon(
            onPressed: _loading ? null : _useBiometrics,
            icon: SkyIcon(
              SkyIcons.fingerprint,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: const Text('Use biometrics'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand(context),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        if (_biometricsAvailable == true) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _loading
              ? null
              : () => setState(() {
                    _step = _SetupStep.createPin;
                    _error = null;
                  }),
          icon: SkyIcon(SkyIcons.lock, color: AppColors.brand(context)),
          label: const Text('Create a PIN'),
          style: OutlinedButton.styleFrom(
            foregroundColor: onSurface,
            side: BorderSide(color: AppColors.brand(context)),
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        if (_loading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPinStep({
    required String title,
    required String subtitle,
    required ValueChanged<String> onCompleted,
  }) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _step = _SetupStep.choose;
                      _draftPin = null;
                      _error = null;
                    }),
            icon: SkyIcon(
              SkyIcons.arrowBack,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const Spacer(),
        PinEntryPad(
          key: ValueKey(_step),
          title: title,
          subtitle: subtitle,
          errorText: _error,
          onCompleted: onCompleted,
        ),
        if (_loading) ...[
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
        const Spacer(flex: 2),
      ],
    );
  }
}