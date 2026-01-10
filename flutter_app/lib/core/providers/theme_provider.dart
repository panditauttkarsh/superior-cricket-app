import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

// State provider to manage dark mode toggle
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// Theme provider that depends on isDarkModeProvider
final themeProvider = Provider<ThemeData>((ref) {
  final isDarkMode = ref.watch(isDarkModeProvider);
  return isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
});
