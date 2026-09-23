import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget/fonts.dart';

/// Loads real fonts (Roboto + MaterialIcons from the Flutter SDK) so layout
/// in widget tests matches the device instead of the square test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  await testMain();
}
