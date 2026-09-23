import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/screen/comic_viewer_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_controls_overlay.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_page.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_page_grid_dialog.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/long_press_overlay.dart';
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
    final c = comic ?? buildComic(id: 7, imagesPath: '/images/7');
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

  bool controlsVisible(WidgetTester tester) {
    final opacity = tester.widget<AnimatedOpacity>(find
        .ancestor(
            of: find.byType(ComicControlsOverlay),
            matching: find.byType(AnimatedOpacity))
        .first);
    return opacity.opacity == 1;
  }

  // Bookmarks are saved after an 800 ms debounce.
  Future<void> flushBookmark(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  Future<void> tapZone(WidgetTester tester, double fraction) async {
    final size = tester.getSize(find.byType(ComicViewerScreen));
    await tester.tapAt(Offset(size.width * fraction, size.height / 2));
    // Wait for the inner double-tap recognizer to give up.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await flushBookmark(tester);
  }

  group('ComicViewerScreen loading', () {
    testWidgets('loads the comic images for the given comic', (tester) async {
      final (_, viewer) = await pumpViewer(tester);
      expect(viewer.loadCalls, [('/images/7', 7)]);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(ComicPage), findsOneWidget);
    });

    testWidgets('shows a spinner while images are loading', (tester) async {
      final c = buildComic(id: 7);
      final repo = createComicRepository(comics: [c]);
      await pumpApp(
        tester,
        ComicViewerScreen(comic: c),
        overrides: testOverrides(
          comicRepository: repo,
          viewerController: () => FakeComicViewerController(neverLoads: true),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the error when loading fails', (tester) async {
      await pumpViewer(tester,
          viewer: FakeComicViewerController(error: 'sin permisos'));
      expect(find.text('Error: sin permisos'), findsOneWidget);
    });

    testWidgets('renders nothing when the comic has no pages', (tester) async {
      await pumpViewer(tester, viewer: FakeComicViewerController(images: []));
      expect(find.byType(PageView), findsNothing);
      await tapZone(tester, 0.5);
      expect(find.text('0 Páginas'), findsOneWidget);
    });

    testWidgets('jumps to the bookmarked page on open', (tester) async {
      final (repo, _) = await pumpViewer(tester,
          comic: buildComic(id: 7, currentReadPage: 3));
      await tapZone(tester, 0.5);
      expect(find.text('Página 4'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      verify(() => repo.addBookMark(7, 3)).called(1);
    });

    testWidgets('works with the real controller reading a directory',
        (tester) async {
      final dir = TestImageDir.create();
      addTearDown(dir.delete);
      dir.writePages(3);
      dir.write('notes.txt');
      final c = buildComic(id: 5, imagesPath: dir.dir.path);
      final repo = createComicRepository(comics: [c]);

      await pumpPushedScreen(
        tester,
        ComicViewerScreen(comic: c),
        overrides: testOverrides(
          comicRepository: repo,
          useRealViewerController: true,
        ),
      );

      verify(() => repo.startReadingComic(5)).called(1);
      // The real controller lists the directory with async I/O.
      for (var i = 0; i < 10 && find.byType(PageView).evaluate().isEmpty; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await tapZone(tester, 0.5);
      expect(find.text('3 Páginas'), findsOneWidget);
    });
  });

  group('ComicViewerScreen tap zones', () {
    testWidgets('controls start hidden and toggle with a center tap',
        (tester) async {
      await pumpViewer(tester);
      expect(controlsVisible(tester), isFalse);

      await tapZone(tester, 0.5);
      expect(controlsVisible(tester), isTrue);
      expect(find.text('Página 1'), findsOneWidget);
      expect(find.text('5 Páginas'), findsOneWidget);

      await tapZone(tester, 0.5);
      expect(controlsVisible(tester), isFalse);
    });

    testWidgets('right zone goes to the next page and saves a bookmark',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapZone(tester, 0.9);
      await tapZone(tester, 0.9);

      verify(() => repo.addBookMark(7, 1)).called(1);
      verify(() => repo.addBookMark(7, 2)).called(1);
      await tapZone(tester, 0.5);
      expect(find.text('Página 3'), findsOneWidget);
    });

    testWidgets('left zone goes back but not before the first page',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapZone(tester, 0.1);
      verifyNever(() => repo.addBookMark(any(), any()));

      await tapZone(tester, 0.9);
      await tapZone(tester, 0.1);
      verify(() => repo.addBookMark(7, 0)).called(1);
    });

    testWidgets('manga mode: left zone goes forward, right zone goes back',
        (tester) async {
      final (repo, _) = await pumpViewer(tester,
          comic: buildComic(id: 7, comicType: 'Manga'));
      await tapZone(tester, 0.1);
      await tapZone(tester, 0.1);
      verify(() => repo.addBookMark(7, 1)).called(1);
      verify(() => repo.addBookMark(7, 2)).called(1);

      await tapZone(tester, 0.9);
      verify(() => repo.addBookMark(7, 1)).called(1);
      await tapZone(tester, 0.5);
      expect(find.text('Página 2'), findsOneWidget);
    });

    testWidgets('fast page turns save only the last page (debounce)',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      final size = tester.getSize(find.byType(ComicViewerScreen));
      for (var i = 0; i < 3; i++) {
        await tester.tapAt(Offset(size.width * 0.9, size.height / 2));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }
      verifyNever(() => repo.addBookMark(any(), any()));

      await flushBookmark(tester);
      verify(() => repo.addBookMark(7, 3)).called(1);
      verifyNever(() => repo.addBookMark(7, 1));
      verifyNever(() => repo.addBookMark(7, 2));
    });

    testWidgets('right zone does nothing on the last page', (tester) async {
      final (repo, _) = await pumpViewer(tester,
          comic: buildComic(id: 7, currentReadPage: 4));
      await flushBookmark(tester);
      clearInteractions(repo);
      await tapZone(tester, 0.9);
      verifyNever(() => repo.addBookMark(any(), any()));
    });
  });

  group('ComicViewerScreen controls', () {
    testWidgets('comic mode is the default for non-manga comics',
        (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, comicType: 'Comic'));
      expect(tester.widget<PageView>(find.byType(PageView)).reverse, isFalse);
    });

    testWidgets('manga comics open in right-to-left mode', (tester) async {
      await pumpViewer(tester, comic: buildComic(id: 7, comicType: 'Manga'));
      expect(tester.widget<PageView>(find.byType(PageView)).reverse, isTrue);
    });

    testWidgets('toggling manga mode reverses pages and persists the type',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapZone(tester, 0.5);

      await tester.tap(find.byIcon(Icons.menu_book));
      await tester.pumpAndSettle();

      expect(tester.widget<PageView>(find.byType(PageView)).reverse, isTrue);
      expect(find.byIcon(Icons.book), findsOneWidget);
      verify(() => repo.updateComicMetadata(
            id: 7,
            title: null,
            author: null,
            genre: null,
            collection: null,
            comicType: 'Manga',
          )).called(1);

      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();
      verify(() => repo.updateComicMetadata(
            id: 7,
            title: null,
            author: null,
            genre: null,
            collection: null,
            comicType: 'Comic',
          )).called(1);
    });

    testWidgets('bookmark button saves the current page', (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapZone(tester, 0.5);
      clearInteractions(repo);

      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pump();
      verify(() => repo.addBookMark(7, 0)).called(1);
    });

    testWidgets('back button saves a bookmark and pops the screen',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapZone(tester, 0.5);
      clearInteractions(repo);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ComicViewerScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
      verify(() => repo.addBookMark(7, 0)).called(1);
    });

    testWidgets('system back hides the controls first, then pops',
        (tester) async {
      await pumpViewer(tester);
      await tapZone(tester, 0.5);
      expect(controlsVisible(tester), isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ComicViewerScreen), findsOneWidget);
      expect(controlsVisible(tester), isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ComicViewerScreen), findsNothing);
    });

    testWidgets('page grid opens and jumps to the selected page',
        (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapZone(tester, 0.5);

      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.byType(ComicPageGridDialog), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(ComicPageGridDialog), matching: find.text('4')));
      await tester.pumpAndSettle();
      await flushBookmark(tester);

      expect(find.byType(ComicPageGridDialog), findsNothing);
      expect(find.text('Página 4'), findsOneWidget);
      verify(() => repo.addBookMark(7, 3)).called(1);
    });

    testWidgets('page grid does not open without pages', (tester) async {
      await pumpViewer(tester, viewer: FakeComicViewerController(images: []));
      await tapZone(tester, 0.5);
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.byType(ComicPageGridDialog), findsNothing);
    });

    testWidgets('progress bar selects a page', (tester) async {
      final (repo, _) = await pumpViewer(tester);
      await tapZone(tester, 0.5);

      final bar = tester.getRect(find.byType(LinearProgressIndicator));
      await tester.tapAt(Offset(bar.left + bar.width * 0.9, bar.center.dy));
      await tester.pumpAndSettle();
      await flushBookmark(tester);

      verify(() => repo.addBookMark(7, 4)).called(1);
    });
  });

  group('ComicViewerScreen long press', () {
    testWidgets('long press shows the overlay and controls until release',
        (tester) async {
      mockVibrationChannel(tester, hasVibrator: true);
      await pumpViewer(tester);

      final center = tester.getCenter(find.byType(ComicViewerScreen));
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(
          tester
              .widget<LongPressOverlay>(find.byType(LongPressOverlay))
              .visible,
          isTrue);
      expect(controlsVisible(tester), isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<LongPressOverlay>(find.byType(LongPressOverlay))
              .visible,
          isFalse);
    });
  });
}
