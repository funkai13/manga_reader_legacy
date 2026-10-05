import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_card.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comics_carousel.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comics_grid.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/emtpy_comics_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget/fakes.dart';
import '../../helpers/widget/pump_app.dart';

void main() {
  setUpAll(registerTestFallbacks);

  group('EmptyComicsScreen', () {
    testWidgets('fades in the empty-state message', (tester) async {
      await pumpApp(tester, EmptyComicsScreen(onAddComic: () {}));

      AnimatedOpacity opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacity().opacity, 0);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(opacity().opacity, 1);
      expect(find.text('SIN COMICS AÚN'), findsOneWidget);
      expect(
          find.text('Agrega tu primer comic para comenzar.'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('"Agregar Comic" calls onAddComic', (tester) async {
      var taps = 0;
      await pumpApp(tester, EmptyComicsScreen(onAddComic: () => taps++));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      await tester.tap(find.text('AGREGAR COMIC'));
      expect(taps, 1);
    });

    testWidgets(
      'does not call setState after being disposed before the intro delay',
      (tester) async {
        await pumpApp(tester, EmptyComicsScreen(onAddComic: () {}));
        // Remove the screen before the 100ms Future.delayed fires.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('icon and subtitle use readable colors in dark mode',
        (tester) async {
      await pumpApp(tester, EmptyComicsScreen(onAddComic: () {}),
          themeMode: ThemeMode.dark);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      final subtitle = tester
          .widget<Text>(find.text('Agrega tu primer comic para comenzar.'));
      expect(subtitle.style?.color, isNot(Colors.black54));
      expect(subtitle.style!.color!.computeLuminance(), greaterThan(0.1));
      final icon = tester.widget<Icon>(find.byIcon(Icons.menu_book_rounded));
      expect(icon.color, Colors.black);
    });
  });

  group('ComicsCarousel', () {
    testWidgets('renders nothing when the list is empty', (tester) async {
      await pumpApp(
        tester,
        const ComicsCarousel(title: 'Sin Leer', comics: [], scale: 1),
        wrapInScaffold: true,
      );
      expect(find.text('SIN LEER'), findsNothing);
      expect(find.byType(ComicCard), findsNothing);
    });

    testWidgets('shows the title and one card per comic', (tester) async {
      await pumpApp(
        tester,
        ComicsCarousel(
            title: 'Continuar Leyendo', comics: sampleComics(), scale: 1),
        wrapInScaffold: true,
      );
      expect(find.text('CONTINUAR LEYENDO'), findsOneWidget);
      // Horizontal list: at least the first two cards are visible.
      expect(find.byType(ComicCard), findsAtLeastNWidgets(2));
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.scrollDirection, Axis.horizontal);
    });

    testWidgets('scrolls horizontally to reveal the last comic',
        (tester) async {
      await pumpApp(
        tester,
        ComicsCarousel(title: 'Todos', comics: sampleComics(), scale: 1),
        wrapInScaffold: true,
      );
      await tester.drag(find.byType(ListView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('NUEVO'), findsWidgets);
    });

    testWidgets('onEdit is forwarded with the tapped comic', (tester) async {
      final edited = <ComicEntity>[];
      await pumpApp(
        tester,
        ComicsCarousel(
          title: 'Todos',
          comics: sampleComics(),
          scale: 1,
          onEdit: edited.add,
        ),
        wrapInScaffold: true,
      );
      await tester.tap(find.byIcon(Icons.edit).first);
      expect(edited.single.id, 1);
    });

    testWidgets('tapping a card opens the ComicViewerScreen', (tester) async {
      final comics = sampleComics();
      final repo = createComicRepository(comics: comics);
      final viewer = FakeComicViewerController();
      await pumpApp(
        tester,
        ComicsCarousel(title: 'Todos', comics: comics, scale: 1),
        wrapInScaffold: true,
        overrides: testOverrides(
          comicRepository: repo,
          viewerController: () => viewer,
        ),
      );

      await tester.tap(find.byType(ComicCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(ComicViewerScreen), findsOneWidget);
      expect(viewer.loadCalls.single.$2, 1);
    });
  });

  group('ComicsGrid', () {
    testWidgets('shows a spinner while comics are loading', (tester) async {
      final repo =
          createComicRepository(getAll: () => neverCompletes<ComicEntity>());
      await pumpApp(tester, const ComicsGrid(),
          wrapInScaffold: true,
          overrides: testOverrides(comicRepository: repo));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the error message when loading fails', (tester) async {
      final repo = createComicRepository(
          getAll: () => Future.error(Exception('db down')));
      await pumpApp(tester, const ComicsGrid(),
          wrapInScaffold: true,
          overrides: testOverrides(comicRepository: repo));
      await tester.pumpAndSettle();
      expect(find.textContaining('ERROR:'), findsOneWidget);
      expect(find.textContaining('Exception: db down'), findsOneWidget);
    });

    testWidgets('renders a card per comic', (tester) async {
      final repo = createComicRepository(comics: sampleComics());
      await pumpApp(tester, const ComicsGrid(),
          wrapInScaffold: true,
          overrides: testOverrides(comicRepository: repo));
      await tester.pumpAndSettle();
      expect(find.byType(ComicCard), findsNWidgets(4));
      expect(find.text('LEYENDO'), findsOneWidget);
      expect(find.text('COMPLETADO'), findsOneWidget);
      expect(find.text('NUEVO'), findsNWidgets(2));
    });

    testWidgets('pull to refresh reloads comics from the repository',
        (tester) async {
      final repo = createComicRepository(comics: sampleComics());
      await pumpApp(tester, const ComicsGrid(),
          wrapInScaffold: true,
          overrides: testOverrides(comicRepository: repo));
      await tester.pumpAndSettle();
      verify(() => repo.getAllComics()).called(1);

      await tester.fling(
          find.byType(ComicCard).first, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      verify(() => repo.getAllComics()).called(1);
    });

    testWidgets('renders completed/reading comics on tablet without overflow',
        (tester) async {
      await pumpApp(
        tester,
        const ComicsGrid(),
        size: kTabletSize,
        wrapInScaffold: true,
        overrides: testOverrides(
            comicRepository: createComicRepository(comics: sampleComics())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('COMPLETADO'), findsOneWidget);
      expect(find.text('Pág. 5'), findsOneWidget);
    });
  });
}
