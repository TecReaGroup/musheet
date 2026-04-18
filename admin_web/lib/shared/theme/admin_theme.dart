import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData get adminTheme => AdminTheme.lightTheme;

class AdminTheme {
  static const String fontFamily = '.SF Pro Text';

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
  );

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.blue600,
      secondary: AppColors.emerald600,
      surface: Colors.white,
      error: AppColors.red500,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.gray900,
      onError: Colors.white,
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6FAFF),
      canvasColor: Colors.white,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme.apply(
        bodyColor: AppColors.gray900,
        displayColor: AppColors.gray900,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.gray700),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray900,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x140F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.gray200),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.gray600),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray400,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray600,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.blue600,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: inputBorder(AppColors.gray200),
        enabledBorder: inputBorder(AppColors.gray200),
        focusedBorder: inputBorder(AppColors.blue300, width: 2),
        errorBorder: inputBorder(AppColors.red300),
        focusedErrorBorder: inputBorder(AppColors.red500, width: 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gray800,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.gray200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue600,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.gray700,
          backgroundColor: Colors.transparent,
          hoverColor: AppColors.gray100,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        disabledColor: AppColors.gray100,
        selectedColor: AppColors.blue50,
        secondarySelectedColor: AppColors.blue50,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray800,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray900,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray600,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray800,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.gray50),
        headingTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          color: AppColors.gray600,
          fontSize: 12,
        ),
        dataTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gray800,
          fontSize: 14,
        ),
        dividerThickness: 1,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 72,
        horizontalMargin: 16,
        columnSpacing: 20,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: AppColors.gray300),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.blue600;
          }
          return Colors.white;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.blue600;
          }
          return AppColors.gray300;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue600,
        linearTrackColor: AppColors.gray200,
        circularTrackColor: AppColors.gray200,
      ),
    );
  }
}
