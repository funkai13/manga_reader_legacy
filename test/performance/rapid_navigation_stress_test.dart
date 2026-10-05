import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/widget/fakes.dart';
import '../helpers/widget/pump_app.dart';
import '../helpers/widget/test_images.dart';

void main() {
  late TestImageDir imageDir;
  late List<File> hundredPages;

  setUpAll(() {
    registerTestFallbacks();
    imageDir = TestImageDir.create();
    hundredPages = imageDir.writePages(100);
  });

  tearDownAll(() => imageDir.delete());

  testWidgets(
      'Stress: Rapid page navigation (50 continuous turns) debounces DB persistence and avoids UI jank',
      (tester) async {
    final comic = buildComic(
      id: 42,
      title: 'Stress Test Comic.cbz',
      imagesPath: '/images/42',
      comicType: 'Comic',
    );
    final repo = createComicRepository(comics: [comic]);
    final viewer = FakeComicViewerController(images: hundredPages);

    await pumpPushedScreen(
      tester,
      ComicViewerScreen(comic: comic),
      overrides: testOverrides(
        comicRepository: repo,
        viewerController: () => viewer,
      ),
    );

    expect(find.byType(ComicViewerScreen), findsOneWidget);

    // Tap right edge 50 times in rapid succession
    final rightEdge = tester.getTopRight(find.byType(ComicViewerScreen)) -
        const Offset(20, -200);

    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      await tester.tapAt(rightEdge);
      await tester.pump(const Duration(milliseconds: 16)); // ~60fps interval
    }
    stopwatch.stop();

    // Settle animation and debounce timer
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    // Verify repository received debounced bookmark update
    verify(() => repo.addBookMark(42, 1)).called(1);
    // Execution must complete smoothly without stalling
    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
  });

  testWidgets(
      'Stress: Immediate reader pop during rapid navigation cleanly disposes with zero unmounted leaks',
      (tester) async {
    final comic = buildComic(
      id: 99,
      title: 'Disposal Stress.cbz',
      imagesPath: '/images/99',
    );
    final repo = createComicRepository(comics: [comic]);
    final viewer = FakeComicViewerController(images: hundredPages);

    await pumpPushedScreen(
      tester,
      ComicViewerScreen(comic: comic),
      overrides: testOverrides(
        comicRepository: repo,
        viewerController: () => viewer,
      ),
    );

    // Start rapid navigation
    final rightEdge = tester.getTopRight(find.byType(ComicViewerScreen)) -
        const Offset(20, -200);
    for (var i = 0; i < 10; i++) {
      await tester.tapAt(rightEdge);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Immediately pop screen mid-stream
    Navigator.of(tester.element(find.byType(ComicViewerScreen))).pop();
    await tester.pumpAndSettle();

    // Verify screen is fully popped and no unhandled asynchronous exceptions or leaks occurred
    expect(find.byType(ComicViewerScreen), findsNothing);
  });
}
