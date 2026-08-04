import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthMethod { biometric, pin }

/// Stores app PIN verifier and unlock method in secure storage.
///
/// PIN format:
/// - `v2:<base64-salt>:<hex-dk>` — PBKDF2-HMAC-SHA256 (preferred)
/// - legacy: unsalted SHA-256 hex (upgraded on next successful unlock)
class PinStorageService {
  PinStorageService._();
  static final PinStorageService instance = PinStorageService._();

  static const _pinHashKey = 'app_pin_hash';
  static const _authMethodKey = 'auth_method';
  static const _pbkdf2Iterations = 120000;
  static const _dkLen = 32;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<AuthMethod?> getAuthMethod() async {
    final value = await _storage.read(key: _authMethodKey);
    return switch (value) {
      'biometric' => AuthMethod.biometric,
      'pin' => AuthMethod.pin,
      _ => null,
    };
  }

  Future<void> savePin(String pin) async {
    final encoded = _hashPinV2(pin);
    await _storage.write(key: _pinHashKey, value: encoded);
    await _storage.write(key: _authMethodKey, value: 'pin');
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null) return false;

    if (stored.startsWith('v2:')) {
      return _verifyV2(pin, stored);
    }

    // Legacy unsalted SHA-256 — accept once, then upgrade at rest.
    final legacy = sha256.convert(utf8.encode(pin)).toString();
    if (!_constantTimeEquals(legacy, stored)) return false;
    await savePin(pin);
    return true;
  }

  Future<void> setBiometricMethod() async {
    // Keep any existing PIN hash so users can fall back if biometrics fail.
    await _storage.write(key: _authMethodKey, value: 'biometric');
  }

  Future<void> clear() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _authMethodKey);
  }

  String _hashPinV2(String pin) {
    final salt = _randomBytes(16);
    final dk = _pbkdf2(
      password: utf8.encode(pin),
      salt: salt,
      iterations: _pbkdf2Iterations,
      length: _dkLen,
    );
    return 'v2:${base64Encode(salt)}:${_toHex(dk)}';
  }

  bool _verifyV2(String pin, String stored) {
    final parts = stored.split(':');
    if (parts.length != 3) return false;
    try {
      final salt = base64Decode(parts[1]);
      final expected = parts[2];
      final dk = _pbkdf2(
        password: utf8.encode(pin),
        salt: salt,
        iterations: _pbkdf2Iterations,
        length: _dkLen,
      );
      return _constantTimeEquals(_toHex(dk), expected);
    } catch (_) {
      return false;
    }
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018) — slows offline guessing of a short PIN.
  Uint8List _pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    final hmac = Hmac(sha256, password);
    final blockCount = (length + 31) ~/ 32;
    final output = BytesBuilder(copy: false);

    for (var block = 1; block <= blockCount; block++) {
      final blockSalt = BytesBuilder(copy: false)
        ..add(salt)
        ..add([(block >> 24) & 0xff, (block >> 16) & 0xff, (block >> 8) & 0xff, block & 0xff]);
      var u = Uint8List.fromList(hmac.convert(blockSalt.toBytes()).bytes);
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.add(t);
    }

    return Uint8List.fromList(output.toBytes().sublist(0, length));
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
