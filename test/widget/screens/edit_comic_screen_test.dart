import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/screens/edit_comic_screen.dart';
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

  Future<MockComicRepository> pumpEdit(
    WidgetTester tester,
    ComicEntity comic, {
    Size size = kPhoneSize,
  }) async {
    final repo = createComicRepository(comics: [comic]);
    await pumpPushedScreen(
      tester,
      EditComicScreen(comic: comic),
      overrides: testOverrides(comicRepository: repo),
      size: size,
    );
    return repo;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('shows the form pre-filled with the comic metadata',
      (tester) async {
    await pumpEdit(
      tester,
      buildComic(
        id: 3,
        title: 'Akira Vol. 1',
        author: 'Katsuhiro Otomo',
        genre: 'Seinen',
        collection: 'Akira',
        comicType: 'Comic',
      ),
    );

    expect(find.text('FICHA TÉCNICA'), findsOneWidget);
    expect(find.text('Akira Vol. 1'), findsOneWidget);
    expect(find.text('Katsuhiro Otomo'), findsOneWidget);
    expect(find.text('Seinen'), findsOneWidget);
    expect(find.text('Akira'), findsOneWidget);
    expect(find.text('MODO DE LECTURA POR DEFECTO'), findsOneWidget);

    final segmented = tester
        .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
    expect(segmented.selected, {'Comic'});
  });

  testWidgets('selects no type when the comic has none (auto)',
      (tester) async {
    await pumpEdit(tester, buildComic());
    final segmented = tester
        .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
    expect(segmented.selected, isEmpty);
  });

  testWidgets('shows the book placeholder when there is no cover',
      (tester) async {
    await pumpEdit(tester, buildComic());
    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
  });

  testWidgets('shows the cover image when the comic has one', (tester) async {
    final cover = imageDir.write('cover.png');
    await precacheFileImages(tester, [cover]);
    await pumpEdit(tester, buildComic(picture: cover.path));
    // Blurred background + sharp cover.
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byIcon(Icons.auto_stories), findsNothing);
  });

  testWidgets('empty title shows a snackbar and does not save', (tester) async {
    final repo = await pumpEdit(tester, buildComic(id: 3));

    await tester.enterText(field('Título del Tomo'), '');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(find.text('El título no puede estar vacío'), findsOneWidget);
    verifyNever(() => repo.updateComicMetadata(
          id: any(named: 'id'),
          title: any(named: 'title'),
          author: any(named: 'author'),
          genre: any(named: 'genre'),
          collection: any(named: 'collection'),
          comicType: any(named: 'comicType'),
        ));
    expect(find.byType(EditComicScreen), findsOneWidget);
  });

  testWidgets('editing only the author keeps an auto (null) reading mode',
      (tester) async {
    final repo = await pumpEdit(tester, buildComic(id: 3, title: 'Old'));

    await tester.enterText(field('Autor / Mangaka'), 'Otomo');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    verify(() => repo.updateComicMetadata(
          id: 3,
          title: 'Old',
          author: 'Otomo',
          genre: '',
          collection: '',
          comicType: null,
        )).called(1);
  });

  testWidgets('clearing author, genre and collection saves them empty',
      (tester) async {
    final repo = await pumpEdit(tester,
        buildComic(id: 3, author: 'Oda', genre: 'Shonen', collection: 'OP'));

    await tester.enterText(field('Autor / Mangaka'), '');
    await tester.enterText(field('Género (ej. Shonen, Seinen, Terror)'), ' ');
    await tester.enterText(field('Colección / Serie'), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    verify(() => repo.updateComicMetadata(
          id: 3,
          title: any(named: 'title'),
          author: '',
          genre: '',
          collection: '',
          comicType: null,
        )).called(1);
  });

  testWidgets('offers the three reading modes, including Webtoon',
      (tester) async {
    final repo = await pumpEdit(tester, buildComic(id: 3, comicType: 'Manga'));
    final segmented = tester
        .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
    expect(segmented.segments.map((s) => s.value), ['Manga', 'Comic', 'Webtoon']);
    expect(find.text('Manga'), findsWidgets);
    expect(find.text('Cómic'), findsOneWidget);
    expect(find.text('Webtoon'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Webtoon'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();
    verify(() => repo.updateComicMetadata(
          id: 3,
          title: any(named: 'title'),
          author: any(named: 'author'),
          genre: any(named: 'genre'),
          collection: any(named: 'collection'),
          comicType: 'Webtoon',
        )).called(1);
  });

  testWidgets('saving updates metadata, pops and shows a confirmation',
      (tester) async {
    final repo = await pumpEdit(tester, buildComic(id: 3, title: 'Old'));

    await tester.enterText(field('Título del Tomo'), 'Nuevo título');
    await tester.enterText(field('Autor / Mangaka'), 'Otomo');
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cómic'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    verify(() => repo.updateComicMetadata(
          id: 3,
          title: 'Nuevo título',
          author: 'Otomo',
          genre: '',
          collection: '',
          comicType: 'Comic',
        )).called(1);
    expect(find.byType(EditComicScreen), findsNothing);
    expect(find.text('Tomo actualizado correctamente'), findsOneWidget);
  });

  testWidgets('back arrow pops without saving', (tester) async {
    final repo = await pumpEdit(tester, buildComic(id: 3));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(EditComicScreen), findsNothing);
    verifyNever(() => repo.updateComicMetadata(
          id: any(named: 'id'),
          title: any(named: 'title'),
          author: any(named: 'author'),
          genre: any(named: 'genre'),
          collection: any(named: 'collection'),
          comicType: any(named: 'comicType'),
        ));
  });

  testWidgets('author field suggests existing authors', (tester) async {
    await pumpEdit(tester, buildComic(id: 3));
    await tester.enterText(field('Autor / Mangaka'), 'mil');
    await tester.pumpAndSettle();
    expect(find.text('Frank Miller'), findsOneWidget);

    await tester.tap(find.text('Frank Miller'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(field('Autor / Mangaka')).controller!.text,
        'Frank Miller');
  });

  testWidgets('renders on tablets without overflow', (tester) async {
    await pumpEdit(tester, buildComic(id: 3, author: 'Otomo'),
        size: kTabletSize);
    expect(find.text('FICHA TÉCNICA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
