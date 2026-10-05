import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Mobile Text Theme
  static final TextTheme mobileTextTheme = TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.64, // -0.02em
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.52,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.44,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.36,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.34,
    ),
    titleMedium: GoogleFonts.spaceGrotesk(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    titleSmall: GoogleFonts.spaceGrotesk(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.26,
    ),
    bodyLarge: GoogleFonts.workSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    bodyMedium: GoogleFonts.workSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    bodySmall: GoogleFonts.workSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    labelLarge: GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.jetBrainsMono(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Tablet Text Theme
  static final TextTheme tabletTextTheme = TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 38,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.76,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.64,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.52,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.48,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.44,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleMedium: GoogleFonts.spaceGrotesk(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.34,
    ),
    titleSmall: GoogleFonts.spaceGrotesk(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    bodyLarge: GoogleFonts.workSans(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    bodyMedium: GoogleFonts.workSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    bodySmall: GoogleFonts.workSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    labelLarge: GoogleFonts.jetBrainsMono(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  /// Helper for display headings in Space Grotesk
  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? (-0.02 * fontSize),
    );
  }

  /// Helper for body text in Work Sans
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.workSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Helper for labels, badges and counters in JetBrains Mono
  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = 0.5,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }
}
