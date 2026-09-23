@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/reader_chrome.dart';

import '../helpers/widget/fakes.dart';
import '../helpers/widget/golden.dart';
import '../helpers/widget/test_images.dart';

void main() {
  late GoldenCovers covers;

  setUpAll(() async {
    registerTestFallbacks();
    covers = await GoldenCovers.create();
  });
  tearDownAll(() => covers.delete());

  // The reader is always dark, so one theme per device is enough.
  final variants =
      goldenVariants.where((v) => v.themeMode == ThemeMode.dark).toList();

  for (final variant in variants) {
    group('$variant', () {
      Future<void> pumpReader(WidgetTester tester, String? comicType,
          {int page = 2}) async {
        final comic = buildComic(
          id: 7,
          title: 'Akira v01.cbz',
          currentReadPage: page,
          comicType: comicType,
          isReading: true,
        );
        await pumpGolden(
          tester,
          ComicViewerScreen(comic: comic),
          variant,
          overrides: testOverrides(
            comicRepository: createComicRepository(comics: [comic]),
            viewerController: () =>
                FakeComicViewerController(images: covers.files),
          ),
        );
      }

      Future<void> showControls(WidgetTester tester) async {
        final size = tester.getSize(find.byType(ComicViewerScreen));
        await tester.tapAt(size.center(Offset.zero));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }

      testWidgets('reader page with the indicator', (tester) async {
        await pumpReader(tester, 'Comic');
        await expectGolden(
            find.byType(ComicViewerScreen), variant.file('reader_page'));
      });

      testWidgets('reader controls (comic)', (tester) async {
        await pumpReader(tester, 'Comic');
        await showControls(tester);
        await expectGolden(find.byType(ComicViewerScreen),
            variant.file('reader_controls_comic'));
      });

      testWidgets('reader controls (manga, slider right to left)',
          (tester) async {
        await pumpReader(tester, 'Manga');
        await showControls(tester);
        await expectGolden(find.byType(ComicViewerScreen),
            variant.file('reader_controls_manga'));
      });

      testWidgets('reader end page', (tester) async {
        await pumpGolden(
          tester,
          ReaderEndPage(
            title: 'Akira v01',
            totalPages: 182,
            onClose: () {},
            onRestart: () {},
          ),
          variant,
        );
        await expectGolden(
            find.byType(ReaderEndPage), variant.file('reader_end_page'));
      });

      testWidgets('reading mode sheet', (tester) async {
        await pumpReader(tester, 'Manga');
        await showControls(tester);
        await tester.tap(find.byTooltip(
            'Modo de lectura: ${ReadingMode.rightToLeft.label}'));
        await tester.pumpAndSettle();
        // Sheets live in the navigator overlay, outside the screen widget.
        await expectGolden(
            find.byType(MaterialApp), variant.file('reader_mode_sheet'));
      });

      testWidgets('page thumbnails sheet', (tester) async {
        await pumpReader(tester, 'Comic');
        await showControls(tester);
        await tester.tap(find.byTooltip('Ver páginas'));
        await tester.pumpAndSettle();
        await settleRealIo(tester, rounds: 20);
        await tester.pumpAndSettle();
        await expectGolden(
            find.byType(MaterialApp), variant.file('reader_pages_sheet'));
      });
    });
  }
}
