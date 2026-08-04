import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 (RFC 8018).
Uint8List pbkdf2HmacSha256({
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
      ..add([
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ]);
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

Uint8List secureRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256)),
  );
}
