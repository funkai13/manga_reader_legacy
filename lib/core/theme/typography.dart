import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static final TextTheme mobileTextTheme = TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 0.4),
    displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.35),
    displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.3),
    headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.25),
    headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.15),
    bodyLarge: GoogleFonts.dmSans(
        fontSize: 17, fontWeight: FontWeight.normal, letterSpacing: 0.5),
    bodyMedium: GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.normal, letterSpacing: 0.25),
    labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    bodySmall: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.normal, letterSpacing: 0.4),
  );

  static final TextTheme tabletTextTheme = TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 0.4),
    displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 0.35),
    displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.3),
    headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 0.25),
    headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.15),
    bodyLarge: GoogleFonts.dmSans(
        fontSize: 19, fontWeight: FontWeight.normal, letterSpacing: 0.5),
    bodyMedium: GoogleFonts.dmSans(
        fontSize: 17, fontWeight: FontWeight.normal, letterSpacing: 0.25),
    labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    bodySmall: GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.normal, letterSpacing: 0.4),
  );
}
