import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Simple AES-CBC encryption for private item *text fields* at the data layer.
///
/// Important limitations (by design today):
/// - Decrypt-on-read is eager in mappers; [PrivateContentGate] is UI masking only.
/// - Voice `.m4a` paths are not encrypted on disk.
/// - CBC has no integrity tag; prefer AES-GCM in a future migration.
///
/// Key lives in [FlutterSecureStorage]. Ciphertext is marked with [prefix]
/// so older plaintext rows still load after migration.
class PrivateCryptoService {
  PrivateCryptoService._();
  static final PrivateCryptoService instance = PrivateCryptoService._();

  static const prefix = 'enc:v1:';
  static const _keyStorageKey = 'private_content_aes_key';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  enc.Key? _key;
  bool _ready = false;

  bool get isReady => _ready;

  /// Load or create the AES-256 key. Call once at app startup.
  Future<void> init() async {
    if (_ready) return;
    var raw = await _storage.read(key: _keyStorageKey);
    if (raw == null || raw.isEmpty) {
      final bytes = _randomBytes(32);
      raw = base64Encode(bytes);
      await _storage.write(key: _keyStorageKey, value: raw);
    }
    _key = enc.Key.fromBase64(raw);
    _ready = true;
  }

  String? protect(String? plain, {required bool isPrivate}) {
    if (plain == null) return null;
    if (!isPrivate) {
      // Turning privacy off: store plaintext (decrypt if previously encrypted).
      return reveal(plain);
    }
    if (plain.isEmpty) return plain;
    if (plain.startsWith(prefix)) return plain;
    return encrypt(plain);
  }

  String? reveal(String? stored, {bool isPrivate = true}) {
    if (stored == null) return null;
    if (!stored.startsWith(prefix)) return stored;
    return decrypt(stored);
  }

  List<String> protectList(List<String> values, {required bool isPrivate}) {
    return values
        .map((v) => protect(v, isPrivate: isPrivate) ?? v)
        .toList(growable: false);
  }

  List<String> revealList(List<String> values) {
    return values.map((v) => reveal(v) ?? v).toList(growable: false);
  }

  String encrypt(String plain) {
    _ensureReady();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    return '$prefix${iv.base64}:${encrypted.base64}';
  }

  String decrypt(String cipher) {
    _ensureReady();
    if (!cipher.startsWith(prefix)) return cipher;
    final payload = cipher.substring(prefix.length);
    final parts = payload.split(':');
    if (parts.length != 2) return cipher;
    try {
      final iv = enc.IV.fromBase64(parts[0]);
      final data = enc.Encrypted.fromBase64(parts[1]);
      final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
      return encrypter.decrypt(data, iv: iv);
    } catch (_) {
      // Corrupt/legacy payload — surface a safe placeholder rather than crash.
      return '[Encrypted]';
    }
  }

  void _ensureReady() {
    if (!_ready || _key == null) {
      throw StateError('PrivateCryptoService.init() must be called first');
    }
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
