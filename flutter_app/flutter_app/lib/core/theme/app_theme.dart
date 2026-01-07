import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Colors - Using AppColors constants
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.accent;
  static const Color errorColor = AppColors.error;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color cardColor = AppColors.elevated;
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: AppColors.background,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textMain,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textMain,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSec,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.textMain,
      onSecondary: AppColors.textMain,
      onSurface: AppColors.textMain,
      onError: AppColors.textMain,
      background: AppColors.background,
      onBackground: AppColors.textMain,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.defaultRadius),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textMain),
      titleTextStyle: TextStyle(
        color: AppColors.textMain,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textMain,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSec,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.textMeta,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.defaultRadius),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.defaultRadius),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.defaultRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textMeta),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textMain,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.defaultRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textMain,
    ),
  );
}

