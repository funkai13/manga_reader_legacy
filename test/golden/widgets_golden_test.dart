@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_card.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_metadata_dialog.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comics_grid.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/emtpy_comics_screen.dart';

import '../helpers/widget/fakes.dart';
import '../helpers/widget/golden.dart';

void main() {
  late GoldenCovers covers;

  setUpAll(() async {
    registerTestFallbacks();
    covers = await GoldenCovers.create();
  });
  tearDownAll(() => covers.delete());

  for (final variant in goldenVariants) {
    group('$variant', () {
      testWidgets('comic_card states', (tester) async {
        await covers.precache(tester);
        final cards = [
          buildComic(id: 1, picture: covers.pathFor(1)),
          buildComic(
              id: 2,
              picture: covers.pathFor(2),
              isReading: true,
              currentReadPage: 11),
          buildComic(
              id: 3,
              picture: covers.pathFor(3),
              isReading: true,
              isCompleted: true,
              currentReadPage: 30),
          buildComic(id: 4), // placeholder cover
        ];
        await pumpGolden(
          tester,
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final (i, c) in cards.indexed)
                    SizedBox(
                      // Same width the home carousel uses.
                      width: 140.w * variant.scale,
                      child: ComicCard(
                        comic: c,
                        scale: variant.scale,
                        onEdit: i.isEven ? () {} : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
          variant,
          wrapInScaffold: true,
        );
        await expectGolden(find.byType(Scaffold), variant.file('comic_card'));
      });

      testWidgets('comics_grid with data', (tester) async {
        await covers.precache(tester);
        final comics = sampleComics(picture: covers.pathFor) +
            [
              buildComic(
                  id: 5, title: 'Dragon Ball', picture: covers.pathFor(5)),
              buildComic(id: 6, title: 'Watchmen'),
            ];
        await pumpGolden(
          tester,
          const ComicsGrid(),
          variant,
          wrapInScaffold: true,
          overrides: testOverrides(
              comicRepository: createComicRepository(comics: comics)),
        );
        await expectGolden(find.byType(Scaffold), variant.file('comics_grid'));
      });

      testWidgets('empty comics screen', (tester) async {
        await pumpGolden(tester, EmptyComicsScreen(onAddComic: () {}), variant);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        await expectGolden(
            find.byType(EmptyComicsScreen), variant.file('empty_screen'));
      });

      testWidgets('comic metadata dialog', (tester) async {
        await pumpGolden(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ComicMetadataDialog(
                        fileName: 'naruto_vol_01.cbz'),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          variant,
          overrides: testOverrides(),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await expectGolden(
            find.byType(MaterialApp), variant.file('metadata_dialog'));
      });
    });
  }
}
