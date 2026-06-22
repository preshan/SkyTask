import 'package:flutter/material.dart';

/// SkyTask brand palette — calm, premium sky-blue theme.
abstract final class AppColors {
  static const Color primary = Color(0xFF6EC6FF);
  static const Color secondary = Color(0xFF9BE7FF);
  static const Color background = Color(0xFFF5FBFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color goldAccent = Color(0xFFF4C542);
  static const Color completedGold = Color(0xFFD4AF37);
  static const Color primaryText = Color(0xFF1E293B);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAccent, completedGold],
  );
}
