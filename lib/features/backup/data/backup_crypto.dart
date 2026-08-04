import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

import '../../../core/utils/pbkdf2.dart';

/// SKYTBAK1 envelope: magic + flags + optional salt/iv + payload.
///
/// flags 0 = gzip JSON, 1 = AES-256-CBC(gzip JSON) with PBKDF2 key.
abstract final class BackupCrypto {
  static const magic = [0x53, 0x4B, 0x59, 0x54, 0x42, 0x41, 0x4B, 0x31]; // SKYTBAK1
  static const flagPlain = 0;
  static const flagEncrypted = 1;
  static const _iterations = 120000;
  static const _keyLen = 32;
  static const _saltLen = 16;
  static const _ivLen = 16;

  static bool looksLikeBackup(Uint8List bytes) {
    if (bytes.length < 9) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  static bool isPasswordProtected(Uint8List bytes) {
    if (!looksLikeBackup(bytes)) return false;
    return bytes[8] == flagEncrypted;
  }

  /// Packs gzip [payload] into a `.skytaskbak` file.
  static Uint8List pack({
    required Uint8List gzipPayload,
    String? password,
  }) {
    final out = BytesBuilder(copy: false);
    out.add(magic);

    if (password == null || password.isEmpty) {
      out.addByte(flagPlain);
      out.add(gzipPayload);
      return out.toBytes();
    }

    final salt = secureRandomBytes(_saltLen);
    final keyBytes = pbkdf2HmacSha256(
      password: utf8.encode(password),
      salt: salt,
      iterations: _iterations,
      length: _keyLen,
    );
    final key = enc.Key(keyBytes);
    final iv = enc.IV(secureRandomBytes(_ivLen));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(gzipPayload, iv: iv);

    out.addByte(flagEncrypted);
    out.add(salt);
    out.add(iv.bytes);
    out.add(encrypted.bytes);
    return out.toBytes();
  }

  /// Unpacks envelope to gzip bytes. Throws [BackupPasswordException] on bad password.
  static Uint8List unpack(Uint8List bytes, {String? password}) {
    if (!looksLikeBackup(bytes)) {
      throw const FormatException('Not a SkyTask backup file');
    }
    final flag = bytes[8];
    if (flag == flagPlain) {
      return Uint8List.sublistView(bytes, 9);
    }
    if (flag != flagEncrypted) {
      throw const FormatException('Unknown backup format flag');
    }
    if (password == null || password.isEmpty) {
      throw BackupPasswordException('Password required');
    }

    const header = 9 + _saltLen + _ivLen;
    if (bytes.length <= header) {
      throw const FormatException('Corrupt encrypted backup');
    }

    final salt = Uint8List.sublistView(bytes, 9, 9 + _saltLen);
    final ivBytes =
        Uint8List.sublistView(bytes, 9 + _saltLen, 9 + _saltLen + _ivLen);
    final cipher = Uint8List.sublistView(bytes, header);

    final keyBytes = pbkdf2HmacSha256(
      password: utf8.encode(password),
      salt: salt,
      iterations: _iterations,
      length: _keyLen,
    );
    final key = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    try {
      return Uint8List.fromList(
        encrypter.decryptBytes(enc.Encrypted(cipher), iv: iv),
      );
    } catch (_) {
      throw BackupPasswordException('Incorrect password');
    }
  }
}

class BackupPasswordException implements Exception {
  BackupPasswordException(this.message);
  final String message;

  @override
  String toString() => message;
}
