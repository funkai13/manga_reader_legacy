import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A valid 1x1 PNG, used as in-memory comic page / cover bytes.
final Uint8List kOnePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Generates a PNG of [width]x[height] with a vertical gradient between
/// [top] and [bottom] using dart:ui. Must run outside of the fake-async zone
/// (in `setUpAll` or inside `tester.runAsync`).
Future<Uint8List> generateGradientPng({
  int width = 60,
  int height = 80,
  Color top = const Color(0xFF3F51B5),
  Color bottom = const Color(0xFFE91E63),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  final paint = Paint()
    ..shader = ui.Gradient.linear(
      rect.topCenter,
      rect.bottomCenter,
      [top, bottom],
    );
  canvas.drawRect(rect, paint);
  // A simple "panel" border so covers look like comic pages.
  canvas.drawRect(
    rect.deflate(4),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xCCFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

/// Temporary directory holding image files for `Image.file` based widgets.
class TestImageDir {
  TestImageDir._(this.dir);

  final Directory dir;

  static TestImageDir create() =>
      TestImageDir._(Directory.systemTemp.createTempSync('manga_reader_test_'));

  File write(String name, [Uint8List? bytes]) {
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    file.writeAsBytesSync(bytes ?? kOnePixelPng);
    return file;
  }

  /// Writes [count] page images named page_000.png, page_001.png ...
  List<File> writePages(int count, [Uint8List? bytes]) => List.generate(
        count,
        (i) => write('page_${i.toString().padLeft(3, '0')}.png', bytes),
      );

  void delete() {
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {
      // Windows may still hold a handle; ignore.
    }
  }
}

/// Loads and decodes [files] into the global [ImageCache] using real async,
/// so later `Image.file` widgets paint synchronously.
///
/// MUST be called before the widgets using these files are pumped: an image
/// stream created inside the fake-async zone cannot be awaited in runAsync.
Future<void> precacheFileImages(WidgetTester tester, List<File> files) async {
  await tester.runAsync(() async {
    for (final file in files) {
      final completer = Completer<void>();
      final stream = FileImage(file).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, __) {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (_, __) {
          if (!completer.isCompleted) completer.complete();
        },
      );
      stream.addListener(listener);
      await completer.future;
      // Keep the image alive in the cache.
      stream.removeListener(listener);
    }
  });
}

/// Lets pending real IO (e.g. `FileImage` loads/errors) complete, pumping
/// frames in between so listeners run.
Future<void> settleRealIo(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
}
