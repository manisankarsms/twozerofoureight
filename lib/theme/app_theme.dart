import 'package:flutter/material.dart';

/// Centralised design tokens with light/dark palette support.
class AppColors {
  AppColors._();

  static bool _isDark = false;
  static bool get isDark => _isDark;

  static void setDark(bool dark) {
    _isDark = dark;
  }

  // --- Adaptive colors ---

  /// Background.
  static Color get background =>
      _isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFAF8EF);

  /// Board background.
  static Color get boardBackground =>
      _isDark ? const Color(0xFF2D2D44) : const Color(0xFFBBADA0);

  /// Empty cell.
  static Color get emptyCell =>
      _isDark ? const Color(0xFF3D3D5C) : const Color(0xFFCDC1B4);

  /// Primary text.
  static Color get textDark =>
      _isDark ? const Color(0xFFEDE4DA) : const Color(0xFF776E65);

  /// Light text (for dark tiles).
  static Color get textLight => const Color(0xFFF9F6F2);

  /// Button / accent.
  static Color get accent =>
      _isDark ? const Color(0xFFF2B179) : const Color(0xFF8F7A66);

  /// Score header.
  static Color get scoreBackground =>
      _isDark ? const Color(0xFF3D3D5C) : const Color(0xFFBBADA0);

  /// Title text.
  static Color get title =>
      _isDark ? const Color(0xFFEDE4DA) : const Color(0xFF776E65);

  /// Returns tile background color based on value.
  static Color tileColor(int value) {
    switch (value) {
      case 2:
        return _isDark ? const Color(0xFF4A4A6A) : const Color(0xFFEEE4DA);
      case 4:
        return _isDark ? const Color(0xFF5A5A7A) : const Color(0xFFEDE0C8);
      case 8:
        return _isDark ? const Color(0xFFF2B179) : const Color(0xFFF2B179);
      case 16:
        return _isDark ? const Color(0xFFF59563) : const Color(0xFFF59563);
      case 32:
        return _isDark ? const Color(0xFFF67C5F) : const Color(0xFFF67C5F);
      case 64:
        return _isDark ? const Color(0xFFF65E3B) : const Color(0xFFF65E3B);
      case 128:
        return _isDark ? const Color(0xFFEDCF72) : const Color(0xFFEDCF72);
      case 256:
        return _isDark ? const Color(0xFFEDCC61) : const Color(0xFFEDCC61);
      case 512:
        return _isDark ? const Color(0xFFEDC850) : const Color(0xFFEDC850);
      case 1024:
        return _isDark ? const Color(0xFFEDC53F) : const Color(0xFFEDC53F);
      case 2048:
        return _isDark ? const Color(0xFFEDC22E) : const Color(0xFFEDC22E);
      default:
        return _isDark ? const Color(0xFF3C3A32) : const Color(0xFF3C3A32);
    }
  }

  /// Returns tile text color based on value.
  static Color tileTextColor(int value) {
    return value <= 4 ? textDark : textLight;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF8F7A66),
        surface: AppColors.background,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFFF2B179),
        surface: AppColors.background,
      ),
    );
  }

  static TextStyle get title => TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.title,
      );

  static TextStyle get subtitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle tileText(int value) {
    double fontSize;
    if (value < 100) {
      fontSize = 36;
    } else if (value < 1000) {
      fontSize = 30;
    } else if (value < 10000) {
      fontSize = 24;
    } else {
      fontSize = 20;
    }
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: AppColors.tileTextColor(value),
    );
  }
}
