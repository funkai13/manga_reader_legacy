import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTypography', () {
    test('text themes are configured for mobile and tablet', () {
      expect(AppTypography.mobileTextTheme.displayLarge?.fontSize, 32);
      expect(AppTypography.tabletTextTheme.displayLarge?.fontSize, 38);

      expect(AppTypography.mobileTextTheme.bodyMedium?.fontSize, 14);
      expect(AppTypography.tabletTextTheme.bodyMedium?.fontSize, 16);

      expect(AppTypography.mobileTextTheme.labelMedium?.fontWeight,
          FontWeight.w600);
    });

    test('heading helper generates Space Grotesk TextStyle', () {
      final style = AppTypography.heading(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      );
      expect(style.fontSize, 24);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, Colors.red);
      expect(style.letterSpacing, -0.02 * 24);
    });

    test('heading helper accepts explicit letterSpacing', () {
      final style = AppTypography.heading(fontSize: 18, letterSpacing: 1.5);
      expect(style.letterSpacing, 1.5);
    });

    test('body helper generates Work Sans TextStyle', () {
      final style = AppTypography.body(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.blue,
        height: 1.4,
      );
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, Colors.blue);
      expect(style.height, 1.4);
    });

    test('mono helper generates JetBrains Mono TextStyle', () {
      final style = AppTypography.mono(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.green,
        letterSpacing: 0.8,
      );
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, Colors.green);
      expect(style.letterSpacing, 0.8);
    });
  });
}
