import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Reader/presenter/reader_controller.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/paged_reader.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/reader_chrome.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/vertical_reader.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget/fakes.dart';
import '../../helpers/widget/pump_app.dart';
import '../../helpers/widget/test_images.dart';

void main() {
  late TestImageDir imageDir;
  late List<File> pages;

  setUpAll(() {
    registerTestFallbacks();
    imageDir = TestImageDir.create();
    pages = imageDir.writePages(5);
  });
  tearDownAll(() => imageDir.delete());

  Future<(MockComicRepository, FakeComicViewerController)> pumpViewer(
    WidgetTester tester, {
    ComicEntity? comic,
    FakeComicViewerController? viewer,
  }) async {
    final c = comic ??
        buildComic(id: 7, title: 'Akira v01.cbz', imagesPath: '/images/7');
    final repo = createComicRepository(comics: [c]);
    final controller = viewer ?? FakeComicViewerController(images: pages);
    await pumpPushedScreen(
      tester,
      ComicViewerScreen(comic: c),
      overrides: testOverrides(
        comicRepository: repo,
        viewerController: () => controller,
      ),
    );
    return (repo, controller);
  }

  bool controlsVisible(WidgetTester tester) => !tester
      .widget<IgnorePointer>(find
          .ancestor(
              of: find.byType(ReaderTopBar),
              matching: find.byType(IgnorePointer))
          .first)
      .ignoring;

  /// Taps at [fraction] of the width (or height with [vertical]) and waits
  /// for the double-tap recognizer to give up.
  Future<void> tapAt(WidgetTester tester, double fraction,
      {bool vertical = false}) async {
    final size = tester.getSize(find.byType(ComicViewerScreen));
    await tester.tapAt(vertical
        ? Offset(size.width / 2, size.height * fraction)
        : Offset(size.width * fraction, size.height / 2));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  // Progress is saved after a short debounce.
  Future<void> flushProgress(WidgetTester tester) => tester
      .pump(ReaderController.persistDelay + const Duration(milliseconds: 50));

  group('loading', () {
    testWidgets('loads the pages of the comic and marks it as reading',
        (tester) async {
      final (repo, viewer) = await pumpViewer(tester);
      expect(viewer.loadCalls, [('/images/7', 7)]);
      expect(find.byType(PagedReader), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
      verify(() => repo.startReadingComic(7)).called(1);
    });

    testWidgets('an already reading comic is not marked again',
        (tester) async {
      final (repo, _) =
          await pumpViewer(tester, comic: buildComic(id: 7, isReading: true));
      verifyNever(() => repo.startReadingComic(any()));
    });

    testWidgets('shows a spinner while pages load', (tester) async {
      final c = buildComic(id: 7);
      await pumpApp(
        tester,
        ComicViewerScreen(comic: c),
        overrides: testOverrides(
          comicRepository: createComicRepository(comics: [c]),
          viewerController: () => FakeComicViewerController(neverLoads: true),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows an error with a way back', (tester) async {
      await pumpViewer(tester,
          viewer: FakeComicViewerController(error: 'sin permisos'));
      expect(find.textContaining('sin permisos'), findsOneWidget);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.byType(ComicViewerScreen), findsNothing);
    });

    testWidgets('a comic without pages says so', (tester) async {
      await pumpViewer(tester, viewer: FakeComicViewerController(images: []));
      expect(find.text('Este cómic no tiene páginas.'), findsOneWidget);
    });

    testWidgets('opens at the saved page', (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, currentReadPage: 3));
      expect(find.text('4 / 5'), findsOneWidget);
    });

    testWidgets('a saved page past the end opens the last page',
        (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, currentReadPage: 40));
      expect(find.text('5 / 5'), findsOneWidget);
    });

    testWidgets('works with the real page loader reading a directory',
        (tester) async {
      final dir = TestImageDir.create();
      addTearDown(dir.delete);
      dir.writePages(3);
      dir.write('notes.txt');
      final c = buildComic(id: 5, imagesPath: dir.dir.path);

      // Not pumpPushedScreen: its pumpAndSettle would spin on the loader.
      await pumpApp(
        tester,
        ComicViewerScreen(comic: c),
        overrides: testOverrides(
          comicRepository: createComicRepository(comics: [c]),
          useRealViewerController: true,
        ),
      );
      // The real loader lists the directory with async I/O.
      for (var i = 0;
          i < 10 && find.byType(PagedReader).evaluate().isEmpty;
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    });
  });

  group('controls', () {
    testWidgets('start hidden; a center tap shows them, another hides them',
        (tester) async {
      await pumpViewer(tester);
      expect(controlsVisible(tester), isFalse);

      await tapAt(tester, 0.5);
      expect(controlsVisible(tester), isTrue);
      expect(find.text('Akira v01'), findsOneWidget, reason: 'no extension');
      expect(find.text('Página 1 de 5'), findsOneWidget);

      await tapAt(tester, 0.5);
      expect(controlsVisible(tester), isFalse);
    });

    testWidgets('while controls are shown an edge tap only hides them',
        (tester) async {
      await pumpViewer(tester);
      await tapAt(tester, 0.5);
      await tapAt(tester, 0.9);
      expect(controlsVisible(tester), isFalse);
      expect(find.text('1 / 5'), findsOneWidget);
    });

    testWidgets('back button saves pending progress and closes',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapAt(tester, 0.9); // page 2, save still pending
      await tapAt(tester, 0.5);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      expect(find.byType(ComicViewerScreen), findsNothing);
      verify(() => repo.addBookMark(7, 1)).called(1);
    });

    testWidgets('system back saves pending progress', (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapAt(tester, 0.9);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ComicViewerScreen), findsNothing);
      verify(() => repo.addBookMark(7, 1)).called(1);
    });
  });

  group('paged navigation', () {
    testWidgets('comic mode: right edge goes forward, left edge back',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapAt(tester, 0.9);
      await tapAt(tester, 0.9);
      expect(find.text('3 / 5'), findsOneWidget);
      await tapAt(tester, 0.1);
      expect(find.text('2 / 5'), findsOneWidget);

      await flushProgress(tester);
      verify(() => repo.addBookMark(7, 1)).called(1);
      verifyNever(() => repo.addBookMark(7, 2));
    });

    testWidgets('manga mode: left edge goes forward, right edge back',
        (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, comicType: 'Manga'));
      expect(tester.widget<PagedReader>(find.byType(PagedReader)).rightToLeft,
          isTrue);
      await tapAt(tester, 0.1);
      await tapAt(tester, 0.1);
      expect(find.text('3 / 5'), findsOneWidget);
      await tapAt(tester, 0.9);
      expect(find.text('2 / 5'), findsOneWidget);
    });

    testWidgets('left edge does nothing on the first page', (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapAt(tester, 0.1);
      await flushProgress(tester);
      expect(find.text('1 / 5'), findsOneWidget);
      verifyNever(() => repo.addBookMark(any(), any()));
    });

    testWidgets('fast page turns save only the last page', (tester) async {
      final (repo, _) = await pumpViewer(tester);
      for (var i = 0; i < 3; i++) {
        await tapAt(tester, 0.9);
      }
      verifyNever(() => repo.addBookMark(any(), any()));
      await flushProgress(tester);
      verify(() => repo.addBookMark(7, 3)).called(1);
      verifyNever(() => repo.addBookMark(7, 1));
    });

    testWidgets('swiping turns pages', (tester) async {
      await pumpViewer(tester);
      await tester.fling(
          find.byType(PagedReader), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2 / 5'), findsOneWidget);
    });
  });

  group('end of the comic', () {
    testWidgets('the last page marks it completed', (tester) async {
      final (repo, _) = await pumpViewer(tester,
          comic: buildComic(id: 7, currentReadPage: 3));
      await tapAt(tester, 0.9);
      await flushProgress(tester);
      verify(() => repo.addBookMark(7, 4)).called(1);
      verify(() => repo.markCompleted(7)).called(1);
    });

    testWidgets('after the last page comes a finish page', (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, currentReadPage: 4));
      await tapAt(tester, 0.9);
      expect(find.text('¡Terminaste!'), findsOneWidget);
      expect(find.text('5 páginas'), findsOneWidget);

      await tester.tap(find.text('Leer desde el inicio'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 5'), findsOneWidget);
    });

    testWidgets('"Volver a la biblioteca" closes the reader', (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, currentReadPage: 4));
      await tapAt(tester, 0.9);
      await tester.tap(find.text('Volver a la biblioteca'));
      await tester.pumpAndSettle();
      expect(find.byType(ComicViewerScreen), findsNothing);
    });
  });

  group('page picker', () {
    testWidgets('the thumbnails sheet jumps to the chosen page',
        (tester) async {
      await pumpViewer(tester);
      await tapAt(tester, 0.5);
      await tester.tap(find.byTooltip('Ver páginas'));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      await tester.tap(find.descendant(of: sheet, matching: find.text('4')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Página 4 de 5'), findsOneWidget);
    });

    testWidgets('the slider previews while dragging and jumps on release',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapAt(tester, 0.5);

      final slider = find.byType(Slider);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      final rect = tester.getRect(slider);
      await gesture.moveTo(Offset(rect.right - 2, rect.center.dy));
      await tester.pump();
      expect(find.text('Página 5'), findsOneWidget, reason: 'preview');
      expect(find.text('Página 1 de 5'), findsOneWidget, reason: 'not yet');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Página 5 de 5'), findsOneWidget);
      await flushProgress(tester);
      verify(() => repo.addBookMark(7, 4)).called(1);
    });

    testWidgets('in manga mode the slider runs right to left',
        (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, comicType: 'Manga'));
      await tapAt(tester, 0.5);
      final direction = Directionality.of(tester.element(find.byType(Slider)));
      expect(direction, TextDirection.rtl);
    });
  });

  group('reading mode', () {
    Future<void> pickMode(WidgetTester tester, String label) async {
      await tapAt(tester, 0.5);
      await tester.tap(find.byTooltip('Modo de lectura: Cómic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('switching to manga mirrors the pages and is saved',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapAt(tester, 0.9); // keep the current page across the switch
      await pickMode(tester, 'Manga');

      expect(tester.widget<PagedReader>(find.byType(PagedReader)).rightToLeft,
          isTrue);
      expect(find.text('Página 2 de 5'), findsOneWidget);
      verify(() => repo.updateComicMetadata(
            id: 7,
            title: null,
            author: null,
            genre: null,
            collection: null,
            comicType: 'Manga',
          )).called(1);
    });

    testWidgets('webtoon mode scrolls vertically from the current page',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapAt(tester, 0.9);
      await pickMode(tester, 'Webtoon');

      expect(find.byType(VerticalReader), findsOneWidget);
      expect(find.byType(PagedReader), findsNothing);
      expect(find.text('Página 2 de 5'), findsOneWidget);
      verify(() => repo.updateComicMetadata(
            id: 7,
            title: null,
            author: null,
            genre: null,
            collection: null,
            comicType: 'Webtoon',
          )).called(1);
    });

    testWidgets('webtoon: bottom edge scrolls down, top edge scrolls up',
        (tester) async {
      await pumpViewer(tester,
          comic: buildComic(id: 7, comicType: 'Webtoon'));
      expect(find.byType(VerticalReader), findsOneWidget);
      double offset() => tester
          .state<ScrollableState>(find.descendant(
              of: find.byType(VerticalReader),
              matching: find.byType(Scrollable)))
          .position
          .pixels;

      await tapAt(tester, 0.9, vertical: true);
      final afterDown = offset();
      expect(afterDown, greaterThan(0));

      await tapAt(tester, 0.1, vertical: true);
      expect(offset(), lessThan(afterDown));
    });
  });
}
