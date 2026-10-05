import 'package:flutter/material.dart';

abstract class NeoColors {
  /// Deep rich ink for light mode borders and drop shadows
  static const Color ink = Color(0xFF121316);
  static const Color darkBorder = Color(0xFF383B44);
  static const Color darkShadow = Color(0xFF0D0E10);

  /// Hard drop shadow color
  static const Color hardShadowColor = ink;
  static const double borderWidth = 2.0;
  static const Offset shadowOffset = Offset(2.5, 2.5);

  /// Brand Accents
  static const Color terracotta = Color(0xFFD96B43);
  static const Color mutedIndigo = Color(0xFF3E54A3);
  static const Color mutedIndigoLight = Color(0xFF4D67BE);
  static const Color paperWhite = Color(0xFFF5F3EC);
  static const Color surfaceWarm = Color(0xFFECEAE0);
  static const Color surfaceDeep = Color(0xFFE2DFD2);
}

class AppColorsLight {
  // Canvas & Surfaces
  static const Color backgroundColor = Color(0xFFF5F3EC); // Paper
  static const Color surfaceColor = Color(0xFFECEAE0); // Elevated 1
  static const Color cardColor = Color(0xFFFFFFFF); // Pure paper card
  static const Color surfaceDeep = Color(0xFFE2DFD2); // Nested panels

  // Ink & Borders
  static const Color primaryColor = Color(0xFF121316); // Deep rich ink
  static const Color textColor = Color(0xFF121316);
  static const Color textSecondary = Color(0xFF5C5E66);
  static const Color borderColor = Color(0xFF121316);
  static const Color dividerColor = Color(0x4D2B2D31); // 30% ink rule

  // Accents
  static const Color accentColor = Color(0xFFD96B43); // Terracotta
  static const Color secondaryColor = Color(0xFF3E54A3); // Muted Indigo
  static const Color buttonColor = Color(0xFFD96B43);
  static const Color terracotta = Color(0xFFD96B43);
  static const Color indigo = Color(0xFF3E54A3);

  // Status & Badges
  static const Color successColor = Color(0xFF3E8E5A);
  static const Color warningColor = Color(0xFFD97724);
  static const Color errorColor = Color(0xFFCC3333);
  static const Color infoColor = Color(0xFF3E54A3);
  static const Color pinkColor = Color(0xFFD96B43);
}

class AppColorsDark {
  // Canvas & Surfaces
  static const Color backgroundColor = Color(0xFF161719); // Night Inking Base
  static const Color surfaceColor = Color(0xFF212328); // Surface Panels
  static const Color cardColor = Color(0xFF212328);
  static const Color surfaceDeep = Color(0xFF2A2D35); // Elevated panels

  // Ink & Borders
  static const Color primaryColor = Color(0xFFE8E6E1); // Text primary
  static const Color textColor = Color(0xFFE8E6E1);
  static const Color textSecondary = Color(0xFF9DA1AA);
  static const Color borderColor = Color(0xFF383B44); // Panel lines
  static const Color dividerColor = Color(0xFF383B44);

  // Accents
  static const Color accentColor = Color(0xFFD96B43); // Terracotta
  static const Color secondaryColor = Color(0xFF4D67BE); // Muted Indigo Light
  static const Color buttonColor = Color(0xFFD96B43);
  static const Color terracotta = Color(0xFFD96B43);
  static const Color indigo = Color(0xFF4D67BE);

  // Status & Badges
  static const Color successColor = Color(0xFF4E9F6E);
  static const Color warningColor = Color(0xFFE68A36);
  static const Color errorColor = Color(0xFFE04848);
  static const Color infoColor = Color(0xFF4D67BE);
  static const Color pinkColor = Color(0xFFD96B43);
}
