import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_controls_overlay.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_page_grid_dialog.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_progress_bar.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/long_press_overlay.dart';

import '../../helpers/widget/pump_app.dart';
import '../../helpers/widget/test_images.dart';

void main() {
  late TestImageDir imageDir;
  late List<File> pages;

  setUpAll(() {
    imageDir = TestImageDir.create();
    pages = imageDir.writePages(6);
  });
  tearDownAll(() => imageDir.delete());

  group('ComicProgressBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      int current = 0,
      int total = 10,
      bool manga = false,
      ValueChanged<int>? onSelected,
      ValueChanged<int?>? onPreview,
    }) {
      return pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: SizedBox(
              width: 300,
              child: ComicProgressBar(
                currentPageIndex: current,
                totalPages: total,
                mangaMode: manga,
                onPageSelected: onSelected ?? (_) {},
                onPreviewPageChanged: onPreview ?? (_) {},
              ),
            ),
          ),
        ),
        wrapInScaffold: true,
      );
    }

    double progressValue(WidgetTester tester) => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    testWidgets('renders an empty box when there are no pages', (tester) async {
      await pumpBar(tester, total: 0);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('progress reflects (current + 1) / total', (tester) async {
      await pumpBar(tester, current: 4, total: 10);
      expect(progressValue(tester), closeTo(0.5, 1e-9));
    });

    testWidgets('tapping selects the page under the finger', (tester) async {
      final selected = <int>[];
      final previews = <int?>[];
      await pumpBar(tester,
          total: 10, onSelected: selected.add, onPreview: previews.add);

      final rect = tester.getRect(find.byType(ComicProgressBar));
      // 75% of the width -> page index 7.
      await tester.tapAt(Offset(rect.left + rect.width * 0.75, rect.center.dy));
      await tester.pump();

      expect(selected, [7]);
      expect(previews.last, 7);
      expect(progressValue(tester), closeTo(0.8, 1e-9));
    });

    testWidgets('manga mode mirrors the bar (right-to-left)', (tester) async {
      final selected = <int>[];
      await pumpBar(tester, total: 10, manga: true, onSelected: selected.add);

      final rect = tester.getRect(find.byType(ComicProgressBar));
      // Tapping near the left edge on a mirrored bar is near the end.
      await tester.tapAt(Offset(rect.left + rect.width * 0.05, rect.center.dy));
      await tester.pump();

      expect(selected.single, 9);
    });

    testWidgets('dragging previews pages and clears the preview on end',
        (tester) async {
      final selected = <int>[];
      final previews = <int?>[];
      await pumpBar(tester,
          current: 0,
          total: 10,
          onSelected: selected.add,
          onPreview: previews.add);

      final rect = tester.getRect(find.byType(ComicProgressBar));
      final gesture =
          await tester.startGesture(Offset(rect.left + 5, rect.center.dy));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveTo(Offset(rect.right - 1, rect.center.dy));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(selected, isNotEmpty);
      expect(selected.last, 9);
      expect(previews.first, 0);
      expect(previews.last, isNull);
    });
  });

  group('ComicControlsOverlay', () {
    Future<Map<String, int>> pumpOverlay(
      WidgetTester tester, {
      int current = 2,
      int total = 12,
      bool manga = false,
      bool bookmarked = false,
      int? preview,
      List<int>? selectedPages,
    }) async {
      final calls = <String, int>{};
      void hit(String k) => calls[k] = (calls[k] ?? 0) + 1;
      await pumpApp(
        tester,
        Scaffold(
          backgroundColor: Colors.grey,
          body: ComicControlsOverlay(
            currentPageIndex: current,
            totalPages: total,
            mangaMode: manga,
            isBookmarked: bookmarked,
            previewPageIndex: preview,
            onBack: () => hit('back'),
            onToggleBookmark: () => hit('bookmark'),
            onOpenPageGrid: () => hit('grid'),
            onToggleMangaMode: () => hit('manga'),
            onPageSelected: (p) => selectedPages?.add(p),
            onPreviewPageChanged: (_) => hit('preview'),
          ),
        ),
      );
      return calls;
    }

    testWidgets('shows current and total page labels', (tester) async {
      await pumpOverlay(tester, current: 2, total: 12);
      expect(find.text('Página 3'), findsOneWidget);
      expect(find.text('12 Páginas'), findsOneWidget);
    });

    testWidgets('preview page overrides the current page label',
        (tester) async {
      await pumpOverlay(tester, current: 2, preview: 7);
      expect(find.text('Página 8'), findsOneWidget);
    });

    testWidgets('comic mode shows current page on the left', (tester) async {
      await pumpOverlay(tester);
      final current = tester.getCenter(find.text('Página 3'));
      final total = tester.getCenter(find.text('12 Páginas'));
      expect(current.dx, lessThan(total.dx));
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('manga mode swaps the labels and icon', (tester) async {
      await pumpOverlay(tester, manga: true);
      final current = tester.getCenter(find.text('Página 3'));
      final total = tester.getCenter(find.text('12 Páginas'));
      expect(current.dx, greaterThan(total.dx));
      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('bookmark icon reflects isBookmarked', (tester) async {
      await pumpOverlay(tester, bookmarked: false);
      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      await pumpOverlay(tester, bookmarked: true);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('buttons invoke their callbacks', (tester) async {
      final calls = await pumpOverlay(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.tap(find.byIcon(Icons.list));
      await tester.tap(find.byIcon(Icons.menu_book));
      await tester.pump();

      expect(calls, {'back': 1, 'bookmark': 1, 'grid': 1, 'manga': 1});
    });

    testWidgets('tapping the progress bar selects a page', (tester) async {
      final selected = <int>[];
      await pumpOverlay(tester, total: 12, selectedPages: selected);
      await tester.tap(find.byType(ComicProgressBar));
      await tester.pump();
      expect(selected.single, 6);
    });
  });

  group('ComicPageGridDialog', () {
    Future<void> pumpGrid(
      WidgetTester tester, {
      required int current,
      required bool manga,
      required ValueChanged<int> onSelected,
    }) {
      return pumpApp(
        tester,
        Scaffold(
          body: ComicPageGridDialog(
            images: pages,
            currentPageIndex: current,
            mangaMode: manga,
            onPageSelected: onSelected,
          ),
        ),
      );
    }

    testWidgets('lists every page number in order', (tester) async {
      await pumpGrid(tester, current: 0, manga: false, onSelected: (_) {});
      expect(find.text('Seleccionar Página'), findsOneWidget);
      for (var i = 1; i <= pages.length; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      final first = tester.getTopLeft(find.text('1'));
      final second = tester.getTopLeft(find.text('2'));
      expect(first.dx, lessThan(second.dx));
    });

    testWidgets('tapping a tile reports its page index', (tester) async {
      int? selected;
      await pumpGrid(tester,
          current: 0, manga: false, onSelected: (p) => selected = p);
      await tester.tap(find.text('3'));
      expect(selected, 2);
    });

    testWidgets('manga mode lists pages in reverse order', (tester) async {
      int? selected;
      await pumpGrid(tester,
          current: 0, manga: true, onSelected: (p) => selected = p);

      final six = tester.getTopLeft(find.text('6'));
      final five = tester.getTopLeft(find.text('5'));
      expect(six.dx, lessThan(five.dx));

      await tester.tap(find.text('6'));
      expect(selected, 5);
    });

    testWidgets('highlights the current page with an amber border',
        (tester) async {
      await pumpGrid(tester, current: 1, manga: false, onSelected: (_) {});
      final highlighted = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          ((w.decoration as BoxDecoration).border as Border).top.color ==
              Colors.amber);
      expect(highlighted, findsOneWidget);
    });
  });

  group('LongPressOverlay', () {
    testWidgets('is transparent and ignores pointers when hidden',
        (tester) async {
      await pumpApp(tester, const LongPressOverlay(visible: false),
          wrapInScaffold: true);
      final opacity =
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacity.opacity, 0);
      final ignore = tester.widget<IgnorePointer>(find
          .ancestor(
              of: find.byType(AnimatedOpacity),
              matching: find.byType(IgnorePointer))
          .first);
      expect(ignore.ignoring, isTrue);
    });

    testWidgets('shows the touch icon when visible', (tester) async {
      await pumpApp(tester, const LongPressOverlay(visible: true),
          wrapInScaffold: true);
      await tester.pumpAndSettle();
      final opacity =
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacity.opacity, 1);
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
      final ignore = tester.widget<IgnorePointer>(find
          .ancestor(
              of: find.byType(AnimatedOpacity),
              matching: find.byType(IgnorePointer))
          .first);
      expect(ignore.ignoring, isFalse);
    });
  });
}
