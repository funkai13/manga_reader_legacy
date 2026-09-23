import 'package:flutter/material.dart';
import 'package:manga_reader/core/theme/typography.dart';

import '../utils/constanst.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    final textTheme = _getTextTheme(context);
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColorsLight.primaryColor,
      scaffoldBackgroundColor: AppColorsLight.backgroundColor,
      cardColor: AppColorsLight.cardColor,
      dividerColor: AppColorsLight.dividerColor,
      colorScheme: const ColorScheme.light(
        primary: AppColorsLight.accentColor,
        secondary: AppColorsLight.accentColor,
        surface: AppColorsLight.cardColor,
        onPrimary: Colors.white,
        onSurface: AppColorsLight.textColor,
      ),
      textTheme: textTheme.apply(
          bodyColor: AppColorsLight.textColor,
          displayColor: AppColorsLight.textColor),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.accentColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.buttonColor,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.accentColor,
          side: const BorderSide(color: AppColorsLight.accentColor, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColorsLight.textColor),
        titleTextStyle: TextStyle(
            color: AppColorsLight.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0.2,
        color: AppColorsLight.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsLight.dividerColor,
        thickness: 0.5,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColorsLight.accentColor,
        selectionColor: AppColorsLight.accentColor.withValues(alpha: 0.3),
        selectionHandleColor: AppColorsLight.accentColor,
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    final textTheme = _getTextTheme(context);
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColorsDark.primaryColor,
      scaffoldBackgroundColor: AppColorsDark.backgroundColor,
      cardColor: AppColorsDark.cardColor,
      dividerColor: AppColorsDark.dividerColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.accentColor,
        secondary: AppColorsDark.accentColor,
        surface: AppColorsDark.cardColor,
        onPrimary: AppColorsDark.primaryColor,
        onSurface: AppColorsDark.textColor,
      ),
      textTheme: textTheme.apply(
          bodyColor: AppColorsDark.textColor,
          displayColor: AppColorsDark.textColor),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.accentColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.buttonColor,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.accentColor,
          side: const BorderSide(color: AppColorsDark.accentColor, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColorsDark.textColor),
        titleTextStyle: TextStyle(
            color: AppColorsDark.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColorsDark.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.dividerColor,
        thickness: 0.5,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColorsDark.accentColor,
        selectionColor: AppColorsDark.accentColor.withValues(alpha: 0.3),
        selectionHandleColor: AppColorsDark.accentColor,
      ),
    );
  }

  static TextTheme _getTextTheme(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return screenWidth >= Breakpoints.mobile
        ? AppTypography.tabletTextTheme
        : AppTypography.mobileTextTheme;
  }
}
