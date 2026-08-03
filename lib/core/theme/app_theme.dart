import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import 'app_typography.dart';

/// Material 3 theme with SkyTask brand identity.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final brand = AppColors.brandFor(brightness);
    final colorScheme = isLight ? _lightScheme() : _darkScheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.background : const Color(0xFF0F172A),
      textTheme: AppTypography.textTheme(brightness),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: isLight ? AppColors.card : const Color(0xFF1E293B),
        indicatorColor: brand.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        color: isLight ? AppColors.card : const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight
                ? brand.withValues(alpha: 0.12)
                : Colors.white12,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand,
        foregroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? Colors.white
            : const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brand.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brand.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: brand.withValues(alpha: 0.15),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: brand),
      ),
      chipTheme: ChipThemeData(
        selectedColor: brand.withValues(alpha: 0.25),
        checkmarkColor: brand,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: brand),
        side: BorderSide(color: brand.withValues(alpha: 0.25)),
      ),
    );
  }

  static ColorScheme _lightScheme() {
    return const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF1E293B),
      surface: AppColors.card,
      onSurface: AppColors.primaryText,
      error: AppColors.error,
      tertiary: AppColors.goldAccent,
    );
  }

  static ColorScheme _darkScheme() {
    return const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: Color(0xFF0F172A),
      secondary: AppColors.secondaryDark,
      onSecondary: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFE2E8F0),
      error: AppColors.error,
      tertiary: AppColors.goldAccent,
    );
  }
}
