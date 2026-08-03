import 'package:flutter/material.dart';

/// SkyTask brand palette — navy/sky primary, amber secondary.
abstract final class AppColors {
  /// Light-theme brand (navy).
  static const Color primary = Color(0xFF000080);

  /// Dark-theme brand (sky blue) — readable on dark surfaces.
  static const Color primaryDark = Color(0xFF6EC6FF);

  /// Amber secondary (light).
  static const Color secondary = Color(0xFFF59E0B);

  /// Amber secondary (dark theme — slightly brighter).
  static const Color secondaryDark = Color(0xFFFBBF24);

  static const Color background = Color(0xFFF4F6F9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color goldAccent = Color(0xFFF4C542);
  static const Color completedGold = Color(0xFFD4AF37);
  static const Color primaryText = Color(0xFF1E293B);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  /// Brand accent for the current theme.
  static Color brand(BuildContext context) =>
      brandFor(Theme.of(context).brightness);

  static Color brandFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primary;

  static Color brandSecondary(BuildContext context) =>
      brandSecondaryFor(Theme.of(context).brightness);

  static Color brandSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryDark : secondary;

  static LinearGradient skyGradientFor(Brightness brightness) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brandFor(brightness),
          brandSecondaryFor(brightness),
        ],
      );

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAccent, completedGold],
  );
}
