import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:manga_reader/feature/Home/presenter/screens/edit_comic_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_card.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_card.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_grid_widget.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_list_widget.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/comic_grid_widget.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/rename_category_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget/fakes.dart';
import '../../helpers/widget/pump_app.dart';
import '../../helpers/widget/test_images.dart';

void main() {
  late TestImageDir imageDir;

  setUpAll(() {
    registerTestFallbacks();
    imageDir = TestImageDir.create();
  });
  tearDownAll(() => imageDir.delete());

  group('CategoryCard', () {
    Future<void> pumpCard(
      WidgetTester tester,
      CategoryEntity category, {
      VoidCallback? onTap,
      VoidCallback? onEdit,
    }) {
      return pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            child: CategoryCard(
              category: category,
              onTap: onTap ?? () {},
              onEdit: onEdit,
            ),
          ),
        ),
        wrapInScaffold: true,
      );
    }

    testWidgets('shows name, count and placeholder icon', (tester) async {
      await pumpCard(
          tester, CategoryEntity(name: 'Shonen', count: 12, type: 'genre'));
      expect(find.text('Shonen'), findsOneWidget);
      expect(find.text('12 cómics'), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('onTap and onEdit are invoked', (tester) async {
      var taps = 0, edits = 0;
      await pumpCard(
        tester,
        CategoryEntity(name: 'Shonen', count: 1, type: 'genre'),
        onTap: () => taps++,
        onEdit: () => edits++,
      );
      await tester.tap(find.text('Shonen'));
      await tester.tap(find.byIcon(Icons.edit));
      expect(taps, 1);
      expect(edits, 1);
    });

    testWidgets('renders the cover image when coverPath is set',
        (tester) async {
      final cover = imageDir.write('cat_cover.png');
      await precacheFileImages(tester, [cover]);
      await pumpCard(
          tester,
          CategoryEntity(
              name: 'Oda', count: 3, type: 'author', coverPath: cover.path));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.category), findsNothing);
    });

    testWidgets('shows a fallback icon when the cover cannot load',
        (tester) async {
      await pumpCard(
          tester,
          CategoryEntity(
              name: 'Oda',
              count: 3,
              type: 'author',
              coverPath: '${imageDir.dir.path}/missing.png'));
      await settleRealIo(tester);
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('long names are ellipsized to two lines', (tester) async {
      await pumpCard(
          tester,
          CategoryEntity(
              name: 'Un nombre de colección extremadamente largo que no cabe',
              count: 1,
              type: 'collection'));
      final text =
          tester.widget<Text>(find.textContaining('extremadamente largo'));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryGridWidget', () {
    Future<MockLibraryRepository> pumpGrid(
      WidgetTester tester, {
      String type = 'author',
      MockLibraryRepository? repo,
      int crossAxisCount = 2,
    }) async {
      final library = repo ?? createLibraryRepository();
      await pumpApp(
        tester,
        CategoryGridWidget(type: type, crossAxisCount: crossAxisCount),
        wrapInScaffold: true,
        overrides: testOverrides(
          libraryRepository: library,
          comicRepository: createComicRepository(comics: sampleComics()),
        ),
      );
      return library;
    }

    testWidgets('shows a spinner while loading', (tester) async {
      final repo = createLibraryRepository();
      when(() => repo.getAuthors())
          .thenAnswer((_) => neverCompletes<CategoryEntity>());
      await pumpGrid(tester, repo: repo);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the error message', (tester) async {
      final repo = createLibraryRepository();
      when(() => repo.getGenres()).thenAnswer((_) => Future.error('fallo'));
      await pumpGrid(tester, type: 'genre', repo: repo);
      await tester.pumpAndSettle();
      expect(find.text('Error: fallo'), findsOneWidget);
    });

    testWidgets('shows the empty message', (tester) async {
      await pumpGrid(tester,
          type: 'collection', repo: createLibraryRepository(collections: []));
      await tester.pumpAndSettle();
      expect(find.text('No hay elementos en esta categoría'), findsOneWidget);
    });

    for (final type in ['author', 'genre', 'collection']) {
      testWidgets('loads $type categories from the repository', (tester) async {
        final repo = await pumpGrid(tester, type: type);
        await tester.pumpAndSettle();
        expect(find.byType(CategoryCard), findsNWidgets(3));
        switch (type) {
          case 'author':
            verify(() => repo.getAuthors()).called(1);
          case 'genre':
            verify(() => repo.getGenres()).called(1);
          case 'collection':
            verify(() => repo.getCollections()).called(1);
        }
      });
    }

    testWidgets('uses the requested number of columns', (tester) async {
      await pumpGrid(tester, crossAxisCount: 3);
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
      expect(delegate.childAspectRatio, 0.7);
    });

    testWidgets('tapping a category opens its filtered comics', (tester) async {
      await pumpGrid(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Frank Miller'));
      await tester.pumpAndSettle();

      expect(find.byType(FilteredComicsScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Frank Miller'), findsOneWidget);
    });

    testWidgets('edit badge opens the rename dialog', (tester) async {
      await pumpGrid(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      expect(find.byType(RenameCategoryDialog), findsOneWidget);
      expect(find.text('Renombrar Autor'), findsOneWidget);
    });
  });

  group('CategoryListWidget', () {
    Future<MockLibraryRepository> pumpList(
      WidgetTester tester, {
      MockLibraryRepository? repo,
      String type = 'genre',
    }) async {
      final library = repo ?? createLibraryRepository();
      await pumpApp(
        tester,
        CategoryListWidget(type: type),
        wrapInScaffold: true,
        overrides: testOverrides(
          libraryRepository: library,
          comicRepository: createComicRepository(comics: sampleComics()),
        ),
      );
      return library;
    }

    testWidgets('lists categories with a count chip', (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('Eiichiro Oda'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('loading state', (tester) async {
      final loading = createLibraryRepository();
      when(() => loading.getGenres())
          .thenAnswer((_) => neverCompletes<CategoryEntity>());
      await pumpList(tester, repo: loading);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state', (tester) async {
      final failing = createLibraryRepository();
      when(() => failing.getGenres()).thenAnswer((_) => Future.error('x'));
      await pumpList(tester, repo: failing);
      await tester.pumpAndSettle();
      expect(find.text('Error: x'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pumpList(tester, repo: createLibraryRepository(genres: []));
      await tester.pumpAndSettle();
      expect(find.text('No hay elementos en esta categoría'), findsOneWidget);
    });

    testWidgets('tap navigates to filtered comics', (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Katsuhiro Otomo'));
      await tester.pumpAndSettle();
      expect(find.byType(FilteredComicsScreen), findsOneWidget);
    });

    testWidgets('long press opens the rename dialog', (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Katsuhiro Otomo'));
      await tester.pumpAndSettle();
      expect(find.byType(RenameCategoryDialog), findsOneWidget);
      expect(find.text('Renombrar Género'), findsOneWidget);
    });
  });

  group('RenameCategoryDialog', () {
    Future<MockLibraryRepository> pumpDialog(
      WidgetTester tester, {
      String type = 'author',
      MockLibraryRepository? repo,
    }) async {
      final library = repo ?? createLibraryRepository();
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    RenameCategoryDialog(currentName: 'Oda', type: type),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        overrides: testOverrides(libraryRepository: library),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return library;
    }

    testWidgets('pre-fills the current name', (tester) async {
      await pumpDialog(tester);
      expect(find.text('Renombrar Autor'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Oda'), findsOneWidget);
      expect(find.text('Nuevo nombre'), findsOneWidget);
    });

    testWidgets('Cancelar closes without renaming', (tester) async {
      final repo = await pumpDialog(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(RenameCategoryDialog), findsNothing);
      verifyNever(() => repo.renameAuthor(any(), any()));
    });

    testWidgets('empty name shows a validation error', (tester) async {
      final repo = await pumpDialog(tester);
      await tester.enterText(find.byType(TextFormField), '  ');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
      verifyNever(() => repo.renameAuthor(any(), any()));
    });

    testWidgets('unchanged name just closes', (tester) async {
      final repo = await pumpDialog(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.byType(RenameCategoryDialog), findsNothing);
      verifyNever(() => repo.renameAuthor(any(), any()));
    });

    for (final type in ['author', 'genre', 'collection']) {
      testWidgets('renames a $type and shows success', (tester) async {
        final repo = await pumpDialog(tester, type: type);
        await tester.enterText(find.byType(TextFormField), ' Eiichiro Oda ');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        switch (type) {
          case 'author':
            verify(() => repo.renameAuthor('Oda', 'Eiichiro Oda')).called(1);
          case 'genre':
            verify(() => repo.renameGenre('Oda', 'Eiichiro Oda')).called(1);
          case 'collection':
            verify(() => repo.renameCollection('Oda', 'Eiichiro Oda'))
                .called(1);
        }
        expect(find.byType(RenameCategoryDialog), findsNothing);
        expect(find.text('Renombrado con éxito'), findsOneWidget);
      });
    }

    testWidgets('shows an error snackbar when renaming fails', (tester) async {
      final repo = createLibraryRepository();
      when(() => repo.renameAuthor(any(), any()))
          .thenAnswer((_) => Future.error(Exception('db')));
      await pumpDialog(tester, repo: repo);

      await tester.enterText(find.byType(TextFormField), 'Otro');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Error al renombrar'), findsOneWidget);
      expect(find.byType(RenameCategoryDialog), findsOneWidget);
    });
  });

  group('ComicGridWidget', () {
    testWidgets('shows the empty message', (tester) async {
      await pumpApp(tester, const ComicGridWidget(comics: []),
          wrapInScaffold: true);
      expect(find.text('No hay cómics para mostrar'), findsOneWidget);
    });

    testWidgets('renders a card with edit badge per comic', (tester) async {
      await pumpApp(tester, ComicGridWidget(comics: sampleComics()),
          wrapInScaffold: true);
      expect(find.byType(ComicCard), findsNWidgets(4));
      expect(find.byIcon(Icons.edit), findsNWidgets(4));
    });

    testWidgets('tapping a card opens the viewer', (tester) async {
      final viewer = FakeComicViewerController();
      await pumpApp(
        tester,
        ComicGridWidget(comics: sampleComics()),
        wrapInScaffold: true,
        overrides: testOverrides(
          comicRepository: createComicRepository(comics: sampleComics()),
          viewerController: () => viewer,
        ),
      );
      await tester.tap(find.text('LEYENDO'));
      await tester.pumpAndSettle();
      expect(find.byType(ComicViewerScreen), findsOneWidget);
      expect(viewer.loadCalls.single.$2, 1);
    });

    testWidgets('edit badge opens EditComicScreen', (tester) async {
      await pumpApp(
        tester,
        ComicGridWidget(comics: sampleComics()),
        wrapInScaffold: true,
        overrides: testOverrides(
            comicRepository: createComicRepository(comics: sampleComics())),
      );
      await tester.tap(find.byIcon(Icons.edit).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(EditComicScreen), findsOneWidget);
      expect(find.text('Batman: Year One'), findsOneWidget);
    });
  });
}
