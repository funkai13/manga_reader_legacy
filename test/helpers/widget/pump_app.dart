import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/theme.dart';

/// Logical sizes used across widget and golden tests.
const Size kPhoneSize = Size(390, 844);
const Size kTabletSize = Size(820, 1180);

/// Same design size used by `main.dart`.
const Size kDesignSize = Size(360, 690);

/// Sets the test surface to [size] (logical pixels) and resets it on teardown.
void setSurfaceSize(WidgetTester tester, Size size, {double dpr = 1.0}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
  addTearDown(tester.view.reset);
}

/// On Android the platform default font is Roboto, so theme styles that
/// omit `fontFamily` (the app's `AppBarTheme.titleTextStyle`) render in
/// Roboto on a device. The test engine instead falls back to its square test
/// font, so we fill in Roboto only where the family is missing.
ThemeData withDeviceDefaultFont(ThemeData theme) {
  final title = theme.appBarTheme.titleTextStyle;
  if (title == null || title.fontFamily != null) return theme;
  return theme.copyWith(
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: title.copyWith(fontFamily: 'Roboto'),
    ),
  );
}

/// Builds the full app shell used by the real app (ProviderScope +
/// ScreenUtilInit + MaterialApp with [AppTheme]) around [child].
Widget buildTestApp(
  Widget child, {
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  List<NavigatorObserver> navigatorObservers = const [],
  bool wrapInScaffold = false,
}) {
  return ProviderScope(
    overrides: overrides,
    retry: (retryCount, error) => null,
    child: ScreenUtilInit(
      designSize: kDesignSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: withDeviceDefaultFont(AppTheme.lightTheme(context)),
          darkTheme: withDeviceDefaultFont(AppTheme.darkTheme(context)),
          themeMode: themeMode,
          navigatorObservers: navigatorObservers,
          home: wrapInScaffold ? Scaffold(body: child) : child,
        );
      },
    ),
  );
}

/// Pumps [child] inside the app shell on a phone-sized surface by default.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  Size size = kPhoneSize,
  List<NavigatorObserver> navigatorObservers = const [],
  bool wrapInScaffold = false,
  bool settle = false,
}) async {
  setSurfaceSize(tester, size);
  await tester.pumpWidget(
    buildTestApp(
      child,
      overrides: overrides,
      themeMode: themeMode,
      navigatorObservers: navigatorObservers,
      wrapInScaffold: wrapInScaffold,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps a home page with a single button that pushes [screen]. Useful to
/// test screens that call `Navigator.pop`.
Future<void> pumpPushedScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  Size size = kPhoneSize,
}) async {
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => screen),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    overrides: overrides,
    themeMode: themeMode,
    size: size,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Navigator observer that records pushed/popped routes.
class RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];
  final List<Route<dynamic>> popped = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route);
  }
}
