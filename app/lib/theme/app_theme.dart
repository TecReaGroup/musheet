import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // SF Pro style font configuration
  // Uses system default font which is SF Pro on iOS/macOS
  static const String fontFamily = '.SF Pro Text';
  
  static TextTheme get _textTheme {
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
      displaySmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.light(
        primary: AppColors.blue600,
        secondary: AppColors.emerald600,
        surface: Colors.white,
        error: AppColors.red500,
      ),
      scaffoldBackgroundColor: AppColors.gray50,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gray700),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray900,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.blue600,
        unselectedItemColor: AppColors.gray500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.gray200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(fontFamily: fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue400, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}