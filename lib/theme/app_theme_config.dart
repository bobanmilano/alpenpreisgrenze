import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppThemeConfig {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: AppTypography.headline3,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.cardBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: AppTypography.headline1,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: AppTypography.headline2,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: AppTypography.headline3,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: AppTypography.title,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTypography.bodyLarge,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTypography.body,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: AppTypography.bodySmall,
        color: AppColors.textDisabled,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: AppTypography.body,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
      ),
    ),
    cardTheme: CardThemeData( // ✅ Verwenden Sie CardThemeData, nicht CardTheme
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: AppColors.textDisabled.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: AppColors.textDisabled.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 2.0,
        ),
      ),
    ),
  );
}