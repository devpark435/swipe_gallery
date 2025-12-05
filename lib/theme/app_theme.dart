import 'package:flutter/material.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColorTheme.primary,
        primary: AppColorTheme.primary,
        secondary: AppColorTheme.secondary,
        background: AppColorTheme.background,
        surface: AppColorTheme.surface,
        onPrimary: AppColorTheme.surface,
        onSecondary: AppColorTheme.surface,
        onBackground: AppColorTheme.textPrimary,
        onSurface: AppColorTheme.textPrimary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColorTheme.background,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColorTheme.background,
        foregroundColor: AppColorTheme.textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextTheme.displayLarge,
        headlineMedium: AppTextTheme.headlineMedium,
        bodyLarge: AppTextTheme.bodyLarge,
        bodyMedium: AppTextTheme.bodyMedium,
        labelLarge: AppTextTheme.labelLarge,
      ),
      cardTheme: CardTheme(
        color: AppColorTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        margin: EdgeInsets.zero,
        shadowColor: AppColorTheme.textSecondary.withOpacity(0.12),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColorTheme.textPrimary,
        contentTextStyle: TextStyle(
          color: AppColorTheme.surface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
