import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/paged_reader.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/reader_chrome.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/reader_page.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/vertical_reader.dart';

import '../../helpers/widget/pump_app.dart';
import '../../helpers/widget/test_images.dart';

void main() {
  late TestImageDir testDir;
  late List<File> pages;

  setUpAll(() {
    testDir = TestImageDir.create();
    pages = testDir.writePages(5);
  });

  tearDownAll(() => testDir.delete());

  group('ReaderTopBar', () {
    testWidgets('renders title, subtitle and reading mode icon', (tester) async {
      await pumpApp(
        tester,
        ReaderTopBar(
          title: 'One Piece - Cap 1000',
          subtitle: 'Página 1 de 20',
          mode: ReadingMode.rightToLeft,
          onBack: () {},
          onOpenPages: () {},
          onOpenModes: () {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('One Piece - Cap 1000'), findsOneWidget);
      expect(find.text('Página 1 de 20'), findsOneWidget);
      expect(find.byIcon(Icons.format_textdirection_r_to_l), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('readingModeIcon adapts to mode', (tester) async {
      for (final mode in ReadingMode.values) {
        await pumpApp(
          tester,
          ReaderTopBar(
            title: 'Comic',
            subtitle: 'Sub',
            mode: mode,
            onBack: () {},
            onOpenPages: () {},
            onOpenModes: () {},
          ),
          wrapInScaffold: true,
        );

        final expectedIcon = readingModeIcon(mode);
        expect(find.byIcon(expectedIcon), findsOneWidget);
      }
    });

    testWidgets('callbacks fire on icon button taps', (tester) async {
      var backTapped = false;
      var pagesTapped = false;
      var modesTapped = false;

      await pumpApp(
        tester,
        ReaderTopBar(
          title: 'Title',
          subtitle: 'Subtitle',
          mode: ReadingMode.leftToRight,
          onBack: () => backTapped = true,
          onOpenPages: () => pagesTapped = true,
          onOpenModes: () => modesTapped = true,
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byTooltip('Volver'));
      await tester.pump();
      expect(backTapped, isTrue);

      await tester.tap(find.byTooltip('Modo de lectura: Cómic'));
      await tester.pump();
      expect(modesTapped, isTrue);

      await tester.tap(find.byTooltip('Ver páginas'));
      await tester.pump();
      expect(pagesTapped, isTrue);
    });
  });

  group('ReaderBottomBar', () {
    testWidgets('single page comic hides slider and displays page numbers',
        (tester) async {
      await pumpApp(
        tester,
        ReaderBottomBar(
          pages: [pages.first],
          page: 0,
          rightToLeft: false,
          onJumpToPage: (_) {},
        ),
        wrapInScaffold: true,
      );

      expect(find.byType(Slider), findsNothing);
      expect(find.text('1'), findsNWidgets(2));
    });

    testWidgets('LTR mode shows current page on left and total on right',
        (tester) async {
      await pumpApp(
        tester,
        ReaderBottomBar(
          pages: pages,
          page: 2,
          rightToLeft: false,
          onJumpToPage: (_) {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('RTL mode shows total on left and current page on right',
        (tester) async {
      await pumpApp(
        tester,
        ReaderBottomBar(
          pages: pages,
          page: 1,
          rightToLeft: true,
          onJumpToPage: (_) {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('dragging slider displays page preview and calls onJumpToPage',
        (tester) async {
      int? jumpedPage;

      await pumpApp(
        tester,
        ReaderBottomBar(
          pages: pages,
          page: 0,
          rightToLeft: false,
          onJumpToPage: (page) => jumpedPage = page,
        ),
        wrapInScaffold: true,
      );

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      final topLeft = tester.getTopLeft(sliderFinder);
      final bottomRight = tester.getBottomRight(sliderFinder);
      final targetPoint = Offset((topLeft.dx + bottomRight.dx) * 0.75, (topLeft.dy + bottomRight.dy) / 2);

      // Start drag to activate preview
      final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
      await tester.pump();
      await gesture.moveTo(targetPoint);
      await tester.pump();

      // Preview should show 'Página X'
      expect(find.textContaining('Página'), findsOneWidget);

      // Finish drag
      await gesture.up();
      await tester.pumpAndSettle();

      expect(jumpedPage, isNotNull);
      expect(find.textContaining('Página'), findsNothing);
    });
  });

  group('ReaderPageIndicator', () {
    testWidgets('displays page and total page count in pill format',
        (tester) async {
      await pumpApp(
        tester,
        const ReaderPageIndicator(page: 3, totalPages: 10),
        wrapInScaffold: true,
      );

      expect(find.text('4 / 10'), findsOneWidget);
    });
  });

  group('ReaderEndPage', () {
    testWidgets('renders completion header, comic title, and action buttons',
        (tester) async {
      var closed = false;
      var restarted = false;

      await pumpApp(
        tester,
        ReaderEndPage(
          title: 'Berserk Vol 1',
          totalPages: 220,
          onClose: () => closed = true,
          onRestart: () => restarted = true,
        ),
        wrapInScaffold: true,
      );

      expect(find.text('¡Terminaste!'), findsOneWidget);
      expect(find.text('Berserk Vol 1'), findsOneWidget);
      expect(find.text('220 páginas'), findsOneWidget);
      expect(find.text('Volver a la biblioteca'), findsOneWidget);
      expect(find.text('Leer desde el inicio'), findsOneWidget);

      await tester.tap(find.text('Volver a la biblioteca'));
      await tester.pump();
      expect(closed, isTrue);

      await tester.tap(find.text('Leer desde el inicio'));
      await tester.pump();
      expect(restarted, isTrue);
    });
  });

  group('showReadingModeSheet', () {
    testWidgets('opens sheet and allows selecting a new reading mode',
        (tester) async {
      ReadingMode? selectedMode;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedMode = await showReadingModeSheet(
                context,
                ReadingMode.rightToLeft,
              );
            },
            child: const Text('Open Modes'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('Open Modes'));
      await tester.pumpAndSettle();

      expect(find.text('Modo de lectura'), findsOneWidget);
      expect(find.text(ReadingMode.rightToLeft.label), findsOneWidget);
      expect(find.text(ReadingMode.leftToRight.label), findsOneWidget);
      expect(find.text(ReadingMode.vertical.label), findsOneWidget);

      // Current mode (RTL) has a check icon
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Select leftToRight
      await tester.tap(find.text(ReadingMode.leftToRight.label));
      await tester.pumpAndSettle();

      expect(selectedMode, ReadingMode.leftToRight);
      expect(find.text('Modo de lectura'), findsNothing);
    });
  });

  group('showPageThumbnailsSheet', () {
    testWidgets('opens grid of thumbnails and returns selected page',
        (tester) async {
      int? selectedIndex;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedIndex = await showPageThumbnailsSheet(
                context,
                pages: pages,
                currentPage: 2,
              );
            },
            child: const Text('Open Pages Grid'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('Open Pages Grid'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Tap on page 4 (index 3)
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 3);
      expect(find.byType(GridView), findsNothing);
    });
  });

  group('ReaderPage', () {
    testWidgets('renders reader page and handles double tap to zoom',
        (tester) async {
      var zoomChanged = false;

      await pumpApp(
        tester,
        ReaderPage(
          file: pages.first,
          active: true,
          onZoomChanged: (zoomed) => zoomChanged = zoomed,
        ),
        wrapInScaffold: true,
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Double tap to zoom in
      final center = tester.getCenter(find.byType(ReaderPage));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(zoomChanged, isTrue);
    });
  });

  group('PagedReader', () {
    testWidgets('renders pages and navigates with controller methods',
        (tester) async {
      final key = GlobalKey<PagedReaderState>();
      int currentPage = 0;

      await pumpApp(
        tester,
        PagedReader(
          key: key,
          pages: pages,
          initialPage: 0,
          rightToLeft: false,
          endPage: const Text('END_PAGE_CONTENT'),
          onPageChanged: (p) => currentPage = p,
        ),
        wrapInScaffold: true,
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(currentPage, 0);

      // Next page
      key.currentState?.nextPage();
      await tester.pumpAndSettle();
      expect(currentPage, 1);

      // Jump to page 3
      key.currentState?.jumpToPage(3);
      await tester.pumpAndSettle();
      expect(currentPage, 3);

      // Previous page
      key.currentState?.previousPage();
      await tester.pumpAndSettle();
      expect(currentPage, 2);

      // Jump to end page (index 5)
      key.currentState?.jumpToPage(pages.length);
      await tester.pumpAndSettle();
      expect(find.text('END_PAGE_CONTENT'), findsOneWidget);
    });

    testWidgets('renders in RTL reverse mode when rightToLeft is true',
        (tester) async {
      final key = GlobalKey<PagedReaderState>();

      await pumpApp(
        tester,
        PagedReader(
          key: key,
          pages: pages,
          initialPage: 0,
          rightToLeft: true,
          endPage: const Text('END_PAGE_CONTENT'),
          onPageChanged: (_) {},
        ),
        wrapInScaffold: true,
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.reverse, isTrue);
    });
  });

  group('VerticalReader', () {
    testWidgets('renders pages vertically and supports navigation',
        (tester) async {
      final key = GlobalKey<VerticalReaderState>();
      await pumpApp(
        tester,
        VerticalReader(
          key: key,
          pages: pages,
          initialPage: 0,
          endPage: const Text('END_PAGE_CONTENT'),
          onPageChanged: (_) {},
        ),
        wrapInScaffold: true,
      );

      expect(find.byType(ListView), findsOneWidget);

      // Jump to page 2
      key.currentState?.jumpToPage(2);
      await tester.pumpAndSettle();

      // Next page scrolls down
      key.currentState?.nextPage();
      await tester.pumpAndSettle();

      // Previous page scrolls up
      key.currentState?.previousPage();
      await tester.pumpAndSettle();
    });
  });
}
