import 'package:local_auth/local_auth.dart';

import 'pin_storage_service.dart';

/// Biometric + app PIN authentication for app lock and private content.
class PrivacyAuthService {
  PrivacyAuthService._();
  static final PrivacyAuthService instance = PrivacyAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();
  final PinStorageService _pinStorage = PinStorageService.instance;

  Future<bool> get canUseBiometrics async {
    final canCheck = await _auth.canCheckBiometrics;
    return canCheck && (await _auth.getAvailableBiometrics()).isNotEmpty;
  }

  Future<bool> get canAuthenticate async {
    final method = await _pinStorage.getAuthMethod();
    if (method == AuthMethod.pin) return true;
    return await canUseBiometrics || await _auth.isDeviceSupported();
  }

  Future<List<BiometricType>> get availableBiometrics =>
      _auth.getAvailableBiometrics();

  Future<AuthMethod?> get authMethod => _pinStorage.getAuthMethod();

  Future<bool> authenticateWithBiometrics({String? reason}) async {
    return _auth.authenticate(
      localizedReason: reason ?? 'Authenticate to unlock SkyTask',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  }

  Future<bool> verifyPin(String pin) => _pinStorage.verifyPin(pin);

  Future<bool> unlock({String? reason, String? pin}) async {
    final method = await _pinStorage.getAuthMethod();
    return switch (method) {
      AuthMethod.biometric =>
        await authenticateWithBiometrics(reason: reason),
      AuthMethod.pin => pin != null && await verifyPin(pin),
      null => false,
    };
  }
}
