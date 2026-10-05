import 'package:flutter/material.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';

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
        secondary: AppColorsLight.pinkColor,
        surface: AppColorsLight.cardColor,
        onPrimary: AppColorsLight.textColor,
        onSurface: AppColorsLight.textColor,
        error: AppColorsLight.errorColor,
      ),
      textTheme: textTheme.apply(
          bodyColor: AppColorsLight.textColor,
          displayColor: AppColorsLight.textColor),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.textColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.accentColor,
          foregroundColor: AppColorsLight.textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            side: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.textColor,
          side: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColorsLight.textColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(
            color: AppColorsLight.textColor,
            fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColorsLight.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsLight.borderColor,
        thickness: NeoConstants.borderWidth,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth + 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.accentColor,
        contentTextStyle: const TextStyle(color: AppColorsLight.textColor, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColorsLight.textColor,
        unselectedLabelColor: AppColorsLight.textColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsLight.surfaceColor,
        selectedColor: AppColorsLight.accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsLight.borderColor, width: NeoConstants.borderWidth),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColorsLight.textColor),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColorsLight.borderColor,
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
        secondary: AppColorsDark.pinkColor,
        surface: AppColorsDark.cardColor,
        onPrimary: AppColorsDark.primaryColor,
        onSurface: AppColorsDark.textColor,
        error: AppColorsDark.errorColor,
      ),
      textTheme: textTheme.apply(
          bodyColor: AppColorsDark.textColor,
          displayColor: AppColorsDark.textColor),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.textColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.accentColor,
          foregroundColor: AppColorsDark.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            side: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.textColor,
          side: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColorsDark.textColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(
            color: AppColorsDark.textColor,
            fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColorsDark.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.borderColor,
        thickness: NeoConstants.borderWidth,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth + 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.accentColor,
        contentTextStyle: const TextStyle(color: AppColorsDark.primaryColor, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColorsDark.textColor,
        unselectedLabelColor: AppColorsDark.textColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.surfaceColor,
        selectedColor: AppColorsDark.accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(color: AppColorsDark.borderColor, width: NeoConstants.borderWidth),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColorsDark.textColor),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColorsDark.borderColor,
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
