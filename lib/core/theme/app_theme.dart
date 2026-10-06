import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.teal,
      onPrimary: Colors.white,
      primaryContainer: AppColors.tealSoft,
      onPrimaryContainer: AppColors.teal,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      outline: AppColors.line,
      error: AppColors.high,
      onError: Colors.white,
    );

    const label = TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      dividerColor: AppColors.line,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -0.4,
            color: AppColors.ink),
        titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.2,
            color: AppColors.ink),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
        bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: AppColors.ink),
        bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: AppColors.ink),
        bodySmall:
            TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
        labelLarge: label,
        labelSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.tealSoft,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
              color: selected ? AppColors.teal : AppColors.muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.teal : AppColors.muted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: AppColors.line),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: AppColors.paper),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.teal : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.tealSoft : null),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.teal),
    );
  }
}
