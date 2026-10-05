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
      primaryColor: AppColorsLight.terracotta,
      scaffoldBackgroundColor: AppColorsLight.backgroundColor,
      cardColor: AppColorsLight.surfaceColor,
      dividerColor: AppColorsLight.dividerColor,
      colorScheme: const ColorScheme.light(
        primary: AppColorsLight.terracotta,
        secondary: AppColorsLight.indigo,
        surface: AppColorsLight.surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsLight.textColor,
        error: AppColorsLight.errorColor,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColorsLight.textColor,
        displayColor: AppColorsLight.textColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.textColor,
          textStyle: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            side: const BorderSide(
              color: AppColorsLight.borderColor,
              width: NeoConstants.borderWidth,
            ),
          ),
          textStyle: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.textColor,
          side: const BorderSide(
            color: AppColorsLight.borderColor,
            width: NeoConstants.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          ),
          textStyle: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColorsLight.textColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColorsLight.textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColorsLight.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsLight.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsLight.dividerColor,
        thickness: 1.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.cardColor,
        labelStyle: AppTypography.body(color: AppColorsLight.textSecondary),
        hintStyle: AppTypography.body(color: AppColorsLight.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppColorsLight.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppColorsLight.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppColorsLight.indigo,
            width: NeoConstants.borderWidth + 0.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.surfaceColor,
        contentTextStyle: AppTypography.heading(fontSize: 14, color: AppColorsLight.textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsLight.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsLight.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColorsLight.textColor,
        unselectedLabelColor: AppColorsLight.textSecondary,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColorsLight.terracotta,
            width: 3.0,
          ),
        ),
        labelStyle: AppTypography.heading(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.heading(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsLight.surfaceColor,
        selectedColor: AppColorsLight.terracotta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsLight.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        labelStyle: AppTypography.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textColor,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColorsLight.terracotta,
        selectionColor: Color(0x40D96B43),
        selectionHandleColor: AppColorsLight.terracotta,
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    final textTheme = _getTextTheme(context);
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColorsDark.terracotta,
      scaffoldBackgroundColor: AppColorsDark.backgroundColor,
      cardColor: AppColorsDark.cardColor,
      dividerColor: AppColorsDark.dividerColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.terracotta,
        secondary: AppColorsDark.indigo,
        surface: AppColorsDark.cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsDark.textColor,
        error: AppColorsDark.errorColor,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColorsDark.textColor,
        displayColor: AppColorsDark.textColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.textColor,
          textStyle: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            side: const BorderSide(
              color: AppColorsDark.borderColor,
              width: NeoConstants.borderWidth,
            ),
          ),
          textStyle: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.textColor,
          side: const BorderSide(
            color: AppColorsDark.borderColor,
            width: NeoConstants.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          ),
          textStyle: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColorsDark.textColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColorsDark.textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColorsDark.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsDark.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.dividerColor,
        thickness: 1.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceDeep,
        labelStyle: AppTypography.body(color: AppColorsDark.textSecondary),
        hintStyle: AppTypography.body(color: AppColorsDark.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppColorsDark.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppColorsDark.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: const BorderSide(
            color: AppColorsDark.indigo,
            width: NeoConstants.borderWidth + 0.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.surfaceColor,
        contentTextStyle: AppTypography.heading(fontSize: 14, color: AppColorsDark.textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsDark.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsDark.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColorsDark.textColor,
        unselectedLabelColor: AppColorsDark.textSecondary,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColorsDark.terracotta,
            width: 3.0,
          ),
        ),
        labelStyle: AppTypography.heading(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.heading(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.surfaceColor,
        selectedColor: AppColorsDark.terracotta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          side: const BorderSide(
            color: AppColorsDark.borderColor,
            width: NeoConstants.borderWidth,
          ),
        ),
        labelStyle: AppTypography.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColorsDark.textColor,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColorsDark.terracotta,
        selectionColor: Color(0x40D96B43),
        selectionHandleColor: AppColorsDark.terracotta,
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
