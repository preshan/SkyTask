import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Stable positive 32-bit ids for notifications / AlarmManager.
///
/// [String.hashCode] is not stable across isolates or app runs and can collide;
/// we derive from SHA-256 of the reminder UUID instead.
int stableNotificationId(String reminderId) {
  final bytes = sha256.convert(utf8.encode(reminderId)).bytes;
  final value =
      (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  return value & 0x7fffffff;
}
