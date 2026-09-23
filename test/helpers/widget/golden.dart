import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';
import 'test_images.dart';

/// A device/theme combination a golden is rendered with.
class GoldenVariant {
  const GoldenVariant(this.device, this.size, this.themeMode);

  final String device;
  final Size size;
  final ThemeMode themeMode;

  bool get isTablet => size.shortestSide >= 600;
  double get scale => isTablet ? 0.8 : 1.0;
  String get theme => themeMode == ThemeMode.dark ? 'dark' : 'light';

  /// e.g. `goldens/comic_card_phone_light.png`
  String file(String name) => 'goldens/${name}_${device}_$theme.png';

  @override
  String toString() => '$device/$theme';
}

const goldenVariants = <GoldenVariant>[
  GoldenVariant('phone', kPhoneSize, ThemeMode.light),
  GoldenVariant('phone', kPhoneSize, ThemeMode.dark),
  GoldenVariant('tablet', kTabletSize, ThemeMode.light),
  GoldenVariant('tablet', kTabletSize, ThemeMode.dark),
];

/// Pumps [child] with the app shell for [variant] and settles.
///
/// Real shadows are enabled (flutter_test replaces them with solid black
/// outlines by default); [expectGolden] restores the default afterwards.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child,
  GoldenVariant variant, {
  List<Override> overrides = const [],
  bool wrapInScaffold = false,
}) async {
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = true);
  await pumpApp(
    tester,
    child,
    overrides: overrides,
    themeMode: variant.themeMode,
    size: variant.size,
    wrapInScaffold: wrapInScaffold,
  );
  await tester.pumpAndSettle();
  // Widgets decode files at their display size (ResizeImage), a cache key
  // that precache can't know in advance; let those real decodes finish.
  await settleRealIo(tester, rounds: 20);
  await tester.pumpAndSettle();
}

/// Compares [finder] against the golden [file] and restores
/// [debugDisableShadows] so flutter_test's invariant check passes.
Future<void> expectGolden(Finder finder, String file) async {
  try {
    await expectLater(finder, matchesGoldenFile(file));
  } finally {
    debugDisableShadows = true;
  }
}

/// Cover images generated once per test file (dart:ui, real async).
class GoldenCovers {
  GoldenCovers._(this.dir, this.paths);

  final TestImageDir dir;
  final Map<int, String> paths;

  static const _palette = <(Color, Color)>[
    (Color(0xFF1A237E), Color(0xFFE91E63)),
    (Color(0xFF212121), Color(0xFFFFC107)),
    (Color(0xFFB71C1C), Color(0xFFFF8A65)),
    (Color(0xFF004D40), Color(0xFF80CBC4)),
    (Color(0xFF4A148C), Color(0xFFCE93D8)),
    (Color(0xFF0D47A1), Color(0xFF81D4FA)),
  ];

  static Future<GoldenCovers> create({int count = 6}) async {
    final dir = TestImageDir.create();
    final paths = <int, String>{};
    for (var i = 0; i < count; i++) {
      final (top, bottom) = _palette[i % _palette.length];
      final Uint8List bytes = await generateGradientPng(
          width: 90, height: 120, top: top, bottom: bottom);
      paths[i + 1] = dir.write('cover_${i + 1}.png', bytes).path;
    }
    return GoldenCovers._(dir, paths);
  }

  String pathFor(int id) => paths[((id - 1) % paths.length) + 1]!;

  List<File> get files => paths.values.map(File.new).toList();

  /// Loads all covers into the image cache (call before pumping).
  Future<void> precache(WidgetTester tester) =>
      precacheFileImages(tester, files);

  void delete() => dir.delete();
}
