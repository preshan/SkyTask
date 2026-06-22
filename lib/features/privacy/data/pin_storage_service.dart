import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthMethod { biometric, pin }

/// Stores app PIN hash and chosen unlock method in secure storage.
class PinStorageService {
  PinStorageService._();
  static final PinStorageService instance = PinStorageService._();

  static const _pinHashKey = 'app_pin_hash';
  static const _authMethodKey = 'auth_method';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AuthMethod?> getAuthMethod() async {
    final value = await _storage.read(key: _authMethodKey);
    return switch (value) {
      'biometric' => AuthMethod.biometric,
      'pin' => AuthMethod.pin,
      _ => null,
    };
  }

  Future<void> savePin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _authMethodKey, value: 'pin');
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return stored == hash;
  }

  Future<void> setBiometricMethod() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.write(key: _authMethodKey, value: 'biometric');
  }

  Future<void> clear() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _authMethodKey);
  }
}
