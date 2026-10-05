import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';
import 'package:manga_reader/feature/Home/presenter/screen/home_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_card.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_metadata_dialog.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/emtpy_comics_screen.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget/fakes.dart';
import '../../helpers/widget/pump_app.dart';

void main() {
  setUpAll(registerTestFallbacks);

  Future<MockComicRepository> pumpHome(
    WidgetTester tester, {
    List<ComicEntity>? comics,
    MockComicRepository? repo,
    FakeComicViewerController? viewer,
    Size size = kPhoneSize,
  }) async {
    final repository = repo ?? createComicRepository(comics: comics ?? []);
    final viewerController = viewer ?? FakeComicViewerController();
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: testOverrides(
        comicRepository: repository,
        viewerController: () => viewerController,
      ),
      size: size,
    );
    return repository;
  }

  /// Lets EmptyComicsScreen's intro animation timer run.
  Future<void> settleEmpty(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
  }

  group('HomeScreen states', () {
    testWidgets('shows a spinner while loading', (tester) async {
      await pumpHome(tester,
          repo: createComicRepository(
              getAll: () => neverCompletes<ComicEntity>()));
      expect(find.byType(NeoLoadingIndicator), findsOneWidget);
      expect(find.text('CARGANDO TOMOS...'), findsOneWidget);
    });

    testWidgets('shows an error message when loading fails', (tester) async {
      await pumpHome(tester,
          repo: createComicRepository(
              getAll: () => Future.error(Exception('boom'))));
      await tester.pumpAndSettle();
      expect(find.textContaining('Error cargando los tomos'), findsOneWidget);
    });

    testWidgets('retry button reloads comics when initial load fails',
        (tester) async {
      var callCount = 0;
      final repo = createComicRepository(
        getAll: () {
          callCount++;
          if (callCount == 1) {
            return Future.error(Exception('boom'));
          }
          return Future.value(sampleComics());
        },
      );
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      expect(find.textContaining('Error cargando los tomos'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);

      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error cargando los tomos'), findsNothing);
      expect(find.byType(ComicCard), findsWidgets);
      expect(callCount, 2);
    });

    testWidgets('shows the empty screen when there are no comics',
        (tester) async {
      await pumpHome(tester, comics: []);
      await settleEmpty(tester);
      expect(find.byType(EmptyComicsScreen), findsOneWidget);
      expect(find.text('SIN COMICS AÚN'), findsOneWidget);
      expect(find.text('Bienvenido'), findsNothing);
    });

    testWidgets('shows the app bar, search bar and carousels with data',
        (tester) async {
      await pumpHome(tester, comics: sampleComics());
      await tester.pumpAndSettle();

      expect(find.text('BIBLIOTECA DE TOMOS'), findsOneWidget);
      expect(find.textContaining('TANK'), findsOneWidget);
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.byIcon(Icons.library_books), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('CONTINUAR LEYENDO'), findsOneWidget);
      expect(find.text('RECIENTEMENTE AGREGADOS'), findsOneWidget);
      expect(find.byType(ComicCard), findsWidgets);

      await tester.scrollUntilVisible(find.text('SIN LEER'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('SIN LEER'), findsOneWidget);
    });

    testWidgets('hides "Continuar Leyendo" when nothing is in progress',
        (tester) async {
      await pumpHome(tester, comics: [buildComic(id: 1), buildComic(id: 2)]);
      await tester.pumpAndSettle();
      expect(find.text('CONTINUAR LEYENDO'), findsNothing);
      expect(find.text('RECIENTEMENTE AGREGADOS'), findsOneWidget);
    });

    testWidgets('"Recientemente Agregados" shows at most 6 comics',
        (tester) async {
      final many = List.generate(9, (i) => buildComic(id: i + 1));
      await pumpHome(tester, comics: many);
      await tester.pumpAndSettle();

      final carousel = find.ancestor(
        of: find.text('RECIENTEMENTE AGREGADOS'),
        matching: find.byType(Column),
      );
      final list = tester.widget<ListView>(find
          .descendant(of: carousel.first, matching: find.byType(ListView))
          .first);
      expect(list.childrenDelegate.estimatedChildCount, 6);
    });

    testWidgets('pull to refresh reloads the comics', (tester) async {
      final repo = await pumpHome(tester, comics: sampleComics());
      await tester.pumpAndSettle();
      verify(() => repo.getAllComics()).called(1);

      await tester.fling(find.byType(SearchBar), const Offset(0, 500), 1000);
      await tester.pumpAndSettle();
      verify(() => repo.getAllComics()).called(1);
    });

    testWidgets('uses a taller search bar on tablets', (tester) async {
      await pumpHome(tester, comics: sampleComics(), size: kTabletSize);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SearchBar)).height, 64);
    });
  });

  group('HomeScreen navigation', () {
    testWidgets('library button opens LibraryScreen', (tester) async {
      await pumpHome(tester, comics: sampleComics());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pumpAndSettle();

      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
    });

    testWidgets('tapping a comic card in carousel opens ComicViewerScreen',
        (tester) async {
      final viewer = FakeComicViewerController();
      final comics = sampleComics();
      await pumpHome(tester, comics: comics, viewer: viewer);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ComicCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(ComicViewerScreen), findsOneWidget);
      expect(viewer.loadCalls.single.$2, 1);
    });

    testWidgets('tapping Inicio bottom navigation tab keeps HomeScreen active',
        (tester) async {
      await pumpHome(tester, comics: sampleComics());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LibraryScreen), findsNothing);
    });
  });

  group('HomeScreen add comic flow', () {
    testWidgets('does nothing when the picker is cancelled', (tester) async {
      final picker = FakeFilePicker(null);
      FilePicker.platform = picker;
      final repo = await pumpHome(tester, comics: sampleComics());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(find.byType(SnackBar), findsNothing);
      verifyNever(() => repo.addComic(any()));
    });

    testWidgets('rejects files that are not .cbr/.cbz', (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('notes.pdf'));
      final repo = await pumpHome(tester, comics: sampleComics());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Seleccione un archivo con extensión .cbr o .cbz'),
          findsOneWidget);
      verifyNever(() => repo.addComic(any()));
    });

    testWidgets('warns about duplicates already in the library',
        (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('akira.cbz'));
      final repo = createComicRepository(comics: sampleComics());
      // Checked by content, with the picked file's path.
      when(() => repo.findDuplicate('/fake/akira.cbz'))
          .thenAnswer((_) async => sampleComics()[2]);
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Este cómic ya está en tu biblioteca.'), findsOneWidget);
      verifyNever(() => repo.addComic(any()));
    });

    testWidgets(
        'shows the duplicate message when the import itself finds the '
        'same content', (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('renamed.cbr'));
      final repo = createComicRepository(comics: sampleComics());
      when(() => repo.addComic(any()))
          .thenAnswer((_) async => throw DuplicateComicException(existingId: 1));
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(ComicMetadataDialog), findsNothing);
      expect(find.text('Este cómic ya está en tu biblioteca.'), findsOneWidget);
      expect(find.text('Ocurrió un error al agregar el cómic.'), findsNothing);
    });

    testWidgets(
        'valid file opens the metadata dialog right away and saves metadata',
        (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('naruto_01.cbz'));
      final repo = createComicRepository(comics: sampleComics());
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(ComicMetadataDialog), findsOneWidget);
      expect(find.text('naruto_01'), findsOneWidget);
      final captured = verify(() => repo.addComic(captureAny())).captured.single
          as ComicEntity;
      expect(captured.title, 'naruto_01.cbz');
      expect(captured.filePath, '/fake/naruto_01.cbz');

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Autor / Mangaka'), 'Kishimoto');
      await tester.pumpAndSettle();
      await tester.tap(find.text('IMPORTAR'));
      await tester.pumpAndSettle();

      expect(find.byType(ComicMetadataDialog), findsNothing);
      verify(() => repo.updateComicMetadata(
            id: 99,
            title: 'naruto_01',
            author: 'Kishimoto',
            // Empty fields keep what ComicInfo.xml provided.
            genre: null,
            collection: null,
            comicType: null,
          )).called(1);
      // Initial load + refresh after adding.
      verify(() => repo.getAllComics()).called(2);
    });

    testWidgets('saving before extraction ends shows a spinner until done',
        (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('big.cbz'));
      final repo = createComicRepository(comics: sampleComics());
      final extraction = Completer<ComicEntity>();
      when(() => repo.addComic(any())).thenAnswer((_) => extraction.future);
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('IMPORTAR'));
      // The spinner animates forever, so pumpAndSettle can't be used here.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ComicMetadataDialog), findsNothing);
      expect(find.byType(NeoLoadingIndicator), findsOneWidget);
      expect(find.text('EXTRAYENDO TOMO...'), findsOneWidget);
      verifyNever(() => repo.updateComicMetadata(
            id: any(named: 'id'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            genre: any(named: 'genre'),
            collection: any(named: 'collection'),
            comicType: any(named: 'comicType'),
          ));

      extraction.complete(sampleComics().first.copyWith(id: 77));
      await tester.pumpAndSettle();

      expect(find.byType(NeoLoadingIndicator), findsNothing);
      verify(() => repo.updateComicMetadata(
            id: 77,
            title: 'big',
            author: null,
            genre: null,
            collection: null,
            comicType: null,
          )).called(1);
    });

    testWidgets('skipping metadata does not update it', (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('naruto_01.cbz'));
      final repo = createComicRepository(comics: sampleComics());
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OMITIR'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.updateComicMetadata(
            id: any(named: 'id'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            genre: any(named: 'genre'),
            collection: any(named: 'collection'),
            comicType: any(named: 'comicType'),
          ));
      verify(() => repo.getAllComics()).called(2);
    });

    testWidgets(
        'shows the unsupported-comic message when processing fails '
        'while the metadata dialog is open', (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('broken.cbr'));
      final repo = createComicRepository(comics: sampleComics());
      when(() => repo.addComic(any())).thenAnswer((_) => Future.delayed(
          const Duration(milliseconds: 800),
          () => throw UnsupportedComicException('RAR5 no soportado')));
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ComicMetadataDialog), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(ComicMetadataDialog), findsNothing);
      expect(find.text('RAR5 no soportado'), findsOneWidget);
    });

    testWidgets('shows a generic error when processing fails late',
        (tester) async {
      FilePicker.platform = FakeFilePicker(pickedFile('broken.cbz'));
      final repo = createComicRepository(comics: sampleComics());
      when(() => repo.addComic(any())).thenAnswer((_) => Future.delayed(
          const Duration(milliseconds: 800),
          () => throw StateError('disk full')));
      await pumpHome(tester, repo: repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(ComicMetadataDialog), findsNothing);
      expect(
          find.text('Ocurrió un error al agregar el cómic.'), findsOneWidget);
    });

    group(
      'fast failures',
      () {
        testWidgets('failing before the dialog is filled shows a snackbar',
            (tester) async {
          FilePicker.platform = FakeFilePicker(pickedFile('broken.cbr'));
          final repo = createComicRepository(comics: sampleComics());
          when(() => repo.addComic(any())).thenAnswer((_) => Future.delayed(
              const Duration(milliseconds: 200),
              () => throw UnsupportedComicException('RAR5 no soportado')));
          await pumpHome(tester, repo: repo);
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.add));
          await tester.pump(); // spinner route is built
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text('RAR5 no soportado'), findsOneWidget);
        });

        testWidgets('failing immediately does not assert on the spinner route',
            (tester) async {
          FilePicker.platform = FakeFilePicker(pickedFile('broken.cbz'));
          final repo = createComicRepository(comics: sampleComics());
          when(() => repo.addComic(any()))
              .thenAnswer((_) => Future.error(StateError('disk full')));
          await pumpHome(tester, repo: repo);
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.add));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();

          expect(find.text('Ocurrió un error al agregar el cómic.'),
              findsOneWidget);
        });
      },
    );

    testWidgets('"Agregar Comic" on the empty screen opens the picker',
        (tester) async {
      final picker = FakeFilePicker(pickedFile('notes.txt'));
      FilePicker.platform = picker;
      await pumpHome(tester, comics: []);
      await settleEmpty(tester);

      await tester.tap(find.text('AGREGAR COMIC'));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(find.text('Seleccione un archivo con extensión .cbr o .cbz'),
          findsOneWidget);
    });
  });
}
