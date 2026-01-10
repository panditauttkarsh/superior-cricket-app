import 'package:flutter/material.dart';

/// App Color Scheme - Off-White Theme
class AppColors {
  // Background Colors
  static const Color background = Color(0xFFFAFAFA); // Main Background (Off-White)
  static const Color surface = Color(0xFFFFFFFF); // Card Surface (White)
  static const Color elevated = Color(0xFFF5F5F5); // Elevated cards (Light Grey)
  static const Color divider = Color(0xFFE5E5E5); // Subtle divider (Light Grey)

  // Accent Colors
  static const Color primary = Color(0xFF2563EB); // Primary Accent (Darker Blue)
  static const Color urgent = Color(0xFFEF4444); // Live Highlight (Professional red)
  static const Color accent = Color(0xFF38BDF8); // Secondary Accent (Sky Blue)

  // Text Colors
  static const Color textMain = Color(0xFF1E293B); // Primary text (Dark Slate)
  static const Color textSec = Color(0xFF475569); // Secondary Text (Medium Grey)
  static const Color textMeta = Color(0xFF64748B); // Muted text (Slate 500)

  // Additional utility colors
  static const Color success = Color(0xFF10B981); // Green for success states
  static const Color warning = Color(0xFFF59E0B); // Amber for warnings
  static const Color error = Color(0xFFEF4444); // Red for errors (same as urgent)

  // Border colors
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color borderDark = Color(0xFFD1D5DB);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF222020);
  static const Color surfaceDark = Color(0xFF474747);
  static const Color textMainDark = Color(0xFFE5E5E5);
  static const Color textSecDark = Color(0xFFA3A3A3);

  // Overlay colors
  static Color overlay = Colors.black.withOpacity(0.5);
  static Color overlayLight = Colors.black.withOpacity(0.2);
}

/// App Theme Configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textMain,
        onError: Colors.white,
        background: AppColors.background,
        onBackground: AppColors.textMain,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
        displayLarge: TextStyle(color: AppColors.textMain),
        displayMedium: TextStyle(color: AppColors.textMain),
        displaySmall: TextStyle(color: AppColors.textMain),
        headlineLarge: TextStyle(color: AppColors.textMain),
        headlineMedium: TextStyle(color: AppColors.textMain),
        headlineSmall: TextStyle(color: AppColors.textMain),
        titleLarge: TextStyle(color: AppColors.textMain),
        titleMedium: TextStyle(color: AppColors.textMain),
        titleSmall: TextStyle(color: AppColors.textMain),
        bodyLarge: TextStyle(color: AppColors.textMain),
        bodyMedium: TextStyle(color: AppColors.textSec),
        bodySmall: TextStyle(color: AppColors.textMeta),
        labelLarge: TextStyle(color: AppColors.textMain),
        labelMedium: TextStyle(color: AppColors.textSec),
        labelSmall: TextStyle(color: AppColors.textMeta),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textMainDark,
        onError: Colors.white,
        background: AppColors.backgroundDark,
        onBackground: AppColors.textMainDark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMainDark),
        titleTextStyle: TextStyle(
          color: AppColors.textMainDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textMainDark),
        displayMedium: TextStyle(color: AppColors.textMainDark),
        displaySmall: TextStyle(color: AppColors.textMainDark),
        headlineLarge: TextStyle(color: AppColors.textMainDark),
        headlineMedium: TextStyle(color: AppColors.textMainDark),
        headlineSmall: TextStyle(color: AppColors.textMainDark),
        titleLarge: TextStyle(color: AppColors.textMainDark),
        titleMedium: TextStyle(color: AppColors.textMainDark),
        titleSmall: TextStyle(color: AppColors.textMainDark),
        bodyLarge: TextStyle(color: AppColors.textMainDark),
        bodyMedium: TextStyle(color: AppColors.textSecDark),
        bodySmall: TextStyle(color: AppColors.textSecDark),
        labelLarge: TextStyle(color: AppColors.textMainDark),
        labelMedium: TextStyle(color: AppColors.textSecDark),
        labelSmall: TextStyle(color: AppColors.textSecDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecDark),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceDark,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textMainDark,
      ),
    );
  }
}

/// Border Radius Constants
class AppBorderRadius {
  static const double defaultRadius = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;

  static BorderRadius get defaultBorder => BorderRadius.circular(defaultRadius);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
  static BorderRadius get xxlBorder => BorderRadius.circular(xxl);
  static BorderRadius get xxxlBorder => BorderRadius.circular(xxxl);
}

/// Box Shadow Constants
class AppShadows {
  static BoxShadow get glow => BoxShadow(
        color: AppColors.primary.withOpacity(0.35),
        blurRadius: 20,
        spreadRadius: 0,
      );

  static BoxShadow get card => BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
      );

  static BoxShadow get elevated => BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 6),
      );
}

