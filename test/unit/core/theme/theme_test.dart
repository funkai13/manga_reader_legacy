import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/theme.dart';
import 'package:manga_reader/core/utils/constanst.dart';

void main() {
  testWidgets('AppTheme.lightTheme builds valid ThemeData for mobile and tablet',
      (tester) async {
    late ThemeData mobileTheme;
    late ThemeData tabletTheme;

    // Mobile width (< 600)
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            mobileTheme = AppTheme.lightTheme(context);
            return const Placeholder();
          },
        ),
      ),
    );

    expect(mobileTheme.brightness, Brightness.light);
    expect(mobileTheme.primaryColor, AppColorsLight.terracotta);
    expect(mobileTheme.scaffoldBackgroundColor, AppColorsLight.backgroundColor);
    expect(mobileTheme.colorScheme.primary, AppColorsLight.terracotta);
    expect(mobileTheme.colorScheme.secondary, AppColorsLight.indigo);
    expect(mobileTheme.colorScheme.surface, AppColorsLight.surfaceColor);
    expect(mobileTheme.textTheme.displayLarge?.fontSize, 32);

    // Tablet width (>= 600)
    tester.view.physicalSize = const Size(Breakpoints.mobile + 50, 1024);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            tabletTheme = AppTheme.lightTheme(context);
            return const Placeholder();
          },
        ),
      ),
    );

    expect(tabletTheme.textTheme.displayLarge?.fontSize, 38);
  });

  testWidgets('AppTheme.darkTheme builds valid ThemeData for mobile and tablet',
      (tester) async {
    late ThemeData darkTheme;

    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            darkTheme = AppTheme.darkTheme(context);
            return const Placeholder();
          },
        ),
      ),
    );

    expect(darkTheme.brightness, Brightness.dark);
    expect(darkTheme.scaffoldBackgroundColor, AppColorsDark.backgroundColor);
    expect(darkTheme.cardColor, AppColorsDark.surfaceColor);
    expect(darkTheme.colorScheme.primary, AppColorsDark.terracotta);
    expect(darkTheme.colorScheme.secondary, AppColorsDark.secondaryColor);
    expect(darkTheme.colorScheme.surface, AppColorsDark.surfaceColor);
  });
}
