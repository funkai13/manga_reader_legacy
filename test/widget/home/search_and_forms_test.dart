import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_metadata_dialog.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/custom_autocomplete_field.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/search_bar.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget/fakes.dart';
import '../../helpers/widget/pump_app.dart';

void main() {
  setUpAll(registerTestFallbacks);

  group('buildSearchBar', () {
    Future<FakeComicViewerController> pumpSearch(
      WidgetTester tester, {
      List<ComicEntity>? comics,
      bool isTablet = false,
    }) async {
      final viewer = FakeComicViewerController();
      final list = comics ?? sampleComics();
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => CustomScrollView(
              slivers: [
                buildSearchBar(
                  context,
                  list,
                  false,
                  1.0,
                  SearchController(),
                  FocusNode(),
                  isTablet,
                ),
              ],
            ),
          ),
        ),
        overrides: testOverrides(
          comicRepository: createComicRepository(comics: list),
          viewerController: () => viewer,
        ),
      );
      return viewer;
    }

    testWidgets('shows the hint and search icon', (tester) async {
      await pumpSearch(tester);
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('BUSCAR EN TU BIBLIOTECA'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('bar height is 56 on phones and 80 on tablets',
        (tester) async {
      await pumpSearch(tester);
      expect(tester.getSize(find.byType(SearchBar)).height, 56);

      await pumpSearch(tester, isTablet: true);
      expect(tester.getSize(find.byType(SearchBar)).height, 80);
    });

    testWidgets('typing filters comics by title (case insensitive)',
        (tester) async {
      await pumpSearch(tester);
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'vol');
      await tester.pumpAndSettle();

      // Matches: One Piece Vol. 1, Akira Vol. 1, Saga Vol. 1 (not Batman).
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('EN PROGRESO'), findsOneWidget);
      expect(find.text('SIN LEER'), findsNWidgets(2));
      // Highlighted match is rendered with rich text.
      expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == 'ONE PIECE VOL. 1'),
        findsWidgets,
      );
    });

    testWidgets('shows a "Sin resultados" tile when nothing matches',
        (tester) async {
      await pumpSearch(tester);
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(
          find.text('No se encontró ningún cómic con "zzz"'), findsOneWidget);

      await tester.tap(find.text('Sin resultados'));
      await tester.pumpAndSettle();
      expect(find.text('Sin resultados'), findsNothing);
    });

    testWidgets('completed comics are labelled "Completado"', (tester) async {
      await pumpSearch(tester);
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'batman');
      await tester.pumpAndSettle();
      expect(find.text('COMPLETADO'), findsOneWidget);
    });

    testWidgets('selecting a result opens the viewer for that comic',
        (tester) async {
      final viewer = await pumpSearch(tester);
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'akira');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(ComicViewerScreen), findsOneWidget);
      expect(viewer.loadCalls.single.$2, 3);
    });

    for (final isTablet in [false, true]) {
      testWidgets('hint text is not clipped (${isTablet ? 'tablet' : 'phone'})',
          (tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => CustomScrollView(slivers: [
                buildSearchBar(
                    context,
                    sampleComics(),
                    false,
                    isTablet ? 0.8 : 1.0,
                    SearchController(),
                    FocusNode(),
                    isTablet),
              ]),
            ),
          ),
          size: isTablet ? kTabletSize : kPhoneSize,
        );
        final field = tester.getRect(find.byType(TextField));
        final hint = tester.getRect(find.text('BUSCAR EN TU BIBLIOTECA'));
        expect(hint.top, greaterThanOrEqualTo(field.top));
        expect(hint.bottom, lessThanOrEqualTo(field.bottom));
      });
    }
  });

  group('CustomAutocompleteField', () {
    Future<void> pumpField(
      WidgetTester tester, {
      required TextEditingController controller,
      required List<String> options,
      ValueChanged<String>? onSelected,
      bool isDark = false,
    }) {
      return pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomAutocompleteField(
            label: 'Autor',
            icon: Icons.person,
            isDark: isDark,
            controller: controller,
            optionsBuilder: () async => options,
            onSelected: onSelected ?? (_) {},
          ),
        ),
        wrapInScaffold: true,
      );
    }

    testWidgets('renders label and prefix icon', (tester) async {
      await pumpField(tester,
          controller: TextEditingController(), options: const []);
      expect(find.text('Autor'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows the initial value from the external controller',
        (tester) async {
      await pumpField(tester,
          controller: TextEditingController(text: 'Oda'), options: const []);
      expect(find.text('Oda'), findsOneWidget);
    });

    testWidgets('typing filters options and syncs the external controller',
        (tester) async {
      final controller = TextEditingController();
      await pumpField(tester,
          controller: controller,
          options: const ['Eiichiro Oda', 'Frank Miller', 'Akira Toriyama']);

      await tester.enterText(find.byType(TextFormField), 'ra');
      await tester.pumpAndSettle();

      expect(controller.text, 'ra');
      expect(find.text('Akira Toriyama'), findsOneWidget);
      expect(find.text('Frank Miller'), findsOneWidget);
      expect(find.text('Eiichiro Oda'), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'mil');
      await tester.pumpAndSettle();
      expect(find.text('Frank Miller'), findsOneWidget);
      expect(find.text('Eiichiro Oda'), findsNothing);
    });

    testWidgets('selecting an option calls onSelected', (tester) async {
      final controller = TextEditingController();
      String? selected;
      await pumpField(tester,
          controller: controller,
          options: const ['Eiichiro Oda', 'Frank Miller'],
          onSelected: (v) => selected = v);

      await tester.enterText(find.byType(TextFormField), 'oda');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eiichiro Oda'));
      await tester.pumpAndSettle();

      expect(selected, 'Eiichiro Oda');
      expect(controller.text, 'Eiichiro Oda');
    });

    testWidgets('empty text shows no options', (tester) async {
      await pumpField(tester,
          controller: TextEditingController(), options: const ['Oda']);
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      expect(find.text('Oda'), findsNothing);
    });
  });

  group('ComicMetadataDialog', () {
    testWidgets('autocomplete fields use the dark fill color in dark mode',
        (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: ComicMetadataDialog(fileName: 'a.cbz')),
        themeMode: ThemeMode.dark,
        overrides: testOverrides(),
      );
      for (final label in ['Autor', 'Género', 'Colección']) {
        final decorator = tester.widget<InputDecorator>(find
            .ancestor(
                of: find.text(label), matching: find.byType(InputDecorator))
            .first);
        expect(decorator.decoration.fillColor, AppColorsDark.backgroundColor,
            reason: label);
      }
    });

    Future<List<Map<String, String>?>> pumpDialog(
      WidgetTester tester, {
      String fileName = 'naruto_01.cbz',
      MockComicRepository? repo,
    }) async {
      final results = <Map<String, String>?>[];
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final r = await showDialog<Map<String, String>?>(
                    context: context,
                    builder: (_) => ComicMetadataDialog(fileName: fileName),
                  );
                  results.add(r);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        overrides: testOverrides(comicRepository: repo),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('renders all fields with the file name as title',
        (tester) async {
      await pumpDialog(tester);
      expect(find.text('NUEVO CÓMIC'), findsOneWidget);
      expect(find.text('naruto_01.cbz'), findsOneWidget);
      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Autor'), findsOneWidget);
      expect(find.text('Género'), findsOneWidget);
      expect(find.text('Colección'), findsOneWidget);
      expect(find.text('TIPO DE LECTURA'), findsOneWidget);
      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('Cómic'), findsOneWidget);
      expect(find.text('OMITIR'), findsOneWidget);
      expect(find.text('GUARDAR'), findsOneWidget);
    });

    testWidgets('"Omitir" closes the dialog returning null', (tester) async {
      final results = await pumpDialog(tester);
      await tester.tap(find.text('OMITIR'));
      await tester.pumpAndSettle();
      expect(find.byType(ComicMetadataDialog), findsNothing);
      expect(results, [null]);
    });

    testWidgets('empty title shows a validation error', (tester) async {
      final results = await pumpDialog(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), '   ');
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(find.text('El título no puede estar vacío'), findsOneWidget);
      expect(find.byType(ComicMetadataDialog), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('"Guardar" returns the trimmed metadata', (tester) async {
      final results = await pumpDialog(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), '  Naruto 1 ');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Autor'), 'Kishimoto ');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Género'), 'Shonen');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Colección'), 'Naruto');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cómic'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(results.single, {
        'title': 'Naruto 1',
        'author': 'Kishimoto',
        'genre': 'Shonen',
        'collection': 'Naruto',
        'comicType': 'Comic',
      });
    });

    testWidgets('genre suggestions include predefined genres', (tester) async {
      final repo = createComicRepository();
      await pumpDialog(tester, repo: repo);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Género'), 'isek');
      await tester.pumpAndSettle();

      expect(find.text('Isekai'), findsOneWidget);
      verify(() => repo.getDistinctGenres()).called(greaterThan(0));
    });
  });
}
