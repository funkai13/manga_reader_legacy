import 'dart:io';

import 'package:flutter/services.dart';

bool _fontsLoaded = false;

/// Locates the Flutter SDK root (FLUTTER_ROOT or relative to flutter_tester).
Directory? _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && Directory(env).existsSync()) return Directory(env);

  // <root>/bin/cache/artifacts/engine/<platform>/flutter_tester(.exe)
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    if (Directory('${dir.path}/bin/cache/artifacts/material_fonts')
        .existsSync()) {
      return dir;
    }
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return null;
}

Future<ByteData> _read(File f) async {
  final bytes = await f.readAsBytes();
  return ByteData.view(Uint8List.fromList(bytes).buffer);
}

/// Loads Roboto and MaterialIcons from the Flutter SDK cache so widget and
/// golden tests render real glyphs instead of the square test font.
///
/// Silently does nothing if the SDK fonts cannot be found.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final root = _flutterRoot();
  if (root == null) return;
  final fontsDir = Directory('${root.path}/bin/cache/artifacts/material_fonts');
  if (!fontsDir.existsSync()) return;

  // 'Roboto' is what Material text themes request. Styles without a
  // fontFamily are handled by `withDeviceDefaultFont` in pump_app.dart.
  for (final family in const ['Roboto']) {
    final loader = FontLoader(family);
    for (final name in const [
      'roboto-thin.ttf',
      'roboto-light.ttf',
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf',
      'roboto-italic.ttf',
      'roboto-bolditalic.ttf',
    ]) {
      final f = File('${fontsDir.path}/$name');
      if (f.existsSync()) loader.addFont(_read(f));
    }
    await loader.load();
  }

  final iconsFile = File('${fontsDir.path}/materialicons-regular.otf');
  if (iconsFile.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(_read(iconsFile))).load();
  }
  _fontsLoaded = true;
}
