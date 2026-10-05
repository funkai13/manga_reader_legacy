import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/colors.dart';

void main() {
  group('NeoColors', () {
    test('defines required brand and base ink colors', () {
      expect(NeoColors.ink, const Color(0xFF121316));
      expect(NeoColors.darkBorder, const Color(0xFF383B44));
      expect(NeoColors.darkShadow, const Color(0xFF0D0E10));
      expect(NeoColors.hardShadowColor, NeoColors.ink);
      expect(NeoColors.borderWidth, 2.0);
      expect(NeoColors.shadowOffset, const Offset(2.5, 2.5));
      expect(NeoColors.terracotta, const Color(0xFFD96B43));
      expect(NeoColors.mutedIndigo, const Color(0xFF3E54A3));
      expect(NeoColors.mutedIndigoLight, const Color(0xFF4D67BE));
      expect(NeoColors.paperWhite, const Color(0xFFF5F3EC));
      expect(NeoColors.surfaceWarm, const Color(0xFFECEAE0));
      expect(NeoColors.surfaceDeep, const Color(0xFFE2DFD2));
    });
  });

  group('AppColorsLight', () {
    test('defines light palette surfaces, ink, accents, and status colors', () {
      expect(AppColorsLight.backgroundColor, const Color(0xFFF5F3EC));
      expect(AppColorsLight.surfaceColor, const Color(0xFFECEAE0));
      expect(AppColorsLight.cardColor, const Color(0xFFFFFFFF));
      expect(AppColorsLight.primaryColor, const Color(0xFF121316));
      expect(AppColorsLight.accentColor, const Color(0xFFD96B43));
      expect(AppColorsLight.secondaryColor, const Color(0xFF3E54A3));
      expect(AppColorsLight.buttonColor, AppColorsLight.terracotta);
      expect(AppColorsLight.successColor, const Color(0xFF3E8E5A));
      expect(AppColorsLight.warningColor, const Color(0xFFD97724));
      expect(AppColorsLight.errorColor, const Color(0xFFCC3333));
    });
  });

  group('AppColorsDark', () {
    test('defines dark palette surfaces, ink, accents, and status colors', () {
      expect(AppColorsDark.backgroundColor, const Color(0xFF161719));
      expect(AppColorsDark.surfaceColor, const Color(0xFF212328));
      expect(AppColorsDark.cardColor, const Color(0xFF212328));
      expect(AppColorsDark.primaryColor, const Color(0xFFE8E6E1));
      expect(AppColorsDark.accentColor, const Color(0xFFD96B43));
      expect(AppColorsDark.secondaryColor, const Color(0xFF4D67BE));
      expect(AppColorsDark.buttonColor, AppColorsDark.terracotta);
      expect(AppColorsDark.successColor, const Color(0xFF4E9F6E));
      expect(AppColorsDark.warningColor, const Color(0xFFE68A36));
      expect(AppColorsDark.errorColor, const Color(0xFFE04848));
    });
  });
}
