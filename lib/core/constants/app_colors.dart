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

  /// Soft day-sky blues / cream horizon.
  static const Color daySkyTop = Color(0xFF87CEEB);
  static const Color daySkyMid = Color(0xFFB8D4F0);
  static const Color daySkyHorizon = Color(0xFFF5E6D3);

  /// Night sky depths.
  static const Color nightSkyTop = Color(0xFF020617);
  static const Color nightSkyMid = Color(0xFF0F172A);
  static const Color nightSkyHorizon = Color(0xFF1E1B4B);

  /// Brand accent for the current theme.
  static Color brand(BuildContext context) =>
      brandFor(Theme.of(context).brightness);

  static Color brandFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primary;

  static Color brandSecondary(BuildContext context) =>
      brandSecondaryFor(Theme.of(context).brightness);

  static Color brandSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryDark : secondary;

  /// Splash / lock brand gradient (navy/sky → amber).
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

  /// App shell atmosphere — day sky or night sky.
  static LinearGradient atmosphereGradientFor(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [nightSkyTop, nightSkyMid, nightSkyHorizon],
        stops: [0.0, 0.55, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [daySkyTop, daySkyMid, daySkyHorizon],
      stops: [0.0, 0.45, 1.0],
    );
  }

  /// Translucent fill for frosted cards / tiles.
  static Color glassFillFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.45);

  /// Slightly stronger glass for bottom nav / elevated panels.
  static Color glassFillElevatedFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF1E293B).withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.55);

  static Color glassBorderFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.14)
          : brandFor(brightness).withValues(alpha: 0.14);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAccent, completedGold],
  );
}
