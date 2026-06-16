import 'package:flutter/material.dart';

/// Design tokens from the original Kivy ui.py
class AppColors {
  static const bg = Color(0xFF0E0F15);
  static const surf = Color(0xFF171922);
  static const card = Color(0xFF1E212D);
  static const elev = Color(0xFF252836);
  static const accent = Color(0xFF6A8BFF);
  static const accentDim = Color(0xFF475EB7);
  static const success = Color(0xFF2CB870);
  static const danger = Color(0xFFD44545);
  static const warn = Color(0xFFDE9615);
  static const fg = Color(0xFFF0F2F6);
  static const fg2 = Color(0xFF9BA3B6);
  static const dim = Color(0xFF5E6678);
  static const border = Color(0xFF333749);
  static const btn = Color(0xFF2D3141);
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Segoe UI',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surf,
      onSurface: AppColors.fg,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.accent,
      overlayColor: AppColors.accent.withValues(alpha: 0.2),
    ),
    dividerColor: AppColors.border,
  );
}
