import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFF5EEAD4);
  static const Color accentColor = Color(0xFFF97316);
  static const Color backgroundColor = Color(0xFFF4F7F6);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color canvasColor = Color(0xFFE8F3F1);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFF0F766E),
      Color(0xFF14B8A6),
      Color(0xFF67E8F9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryLight,
      secondary: accentColor,
      secondaryContainer: const Color(0xFFFED7AA),
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withValues(alpha: 0.86),
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: primaryDark.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: primaryDark.withValues(alpha: 0.18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.84),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: primaryDark,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: primaryDark.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: primaryDark.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      dividerColor: primaryDark.withValues(alpha: 0.08),
      chipTheme: ChipThemeData(
        backgroundColor: canvasColor,
        selectedColor: primaryLight.withValues(alpha: 0.6),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  static const TextStyle headingLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.4,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.35,
    color: textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
