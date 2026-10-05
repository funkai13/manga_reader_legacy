import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_card.dart';

import '../../helpers/widget/fakes.dart';
import '../../helpers/widget/pump_app.dart';
import '../../helpers/widget/test_images.dart';

void main() {
  late TestImageDir images;

  setUpAll(() => images = TestImageDir.create());
  tearDownAll(() => images.delete());

  Future<void> pumpCard(
    WidgetTester tester,
    ComicEntity comic, {
    VoidCallback? onEdit,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 150,
          child: ComicCard(comic: comic, scale: 1.0, onEdit: onEdit),
        ),
      ),
      wrapInScaffold: true,
      themeMode: themeMode,
    );
  }

  group('ComicCard status chip', () {
    testWidgets('shows "Nuevo" for an unread comic', (tester) async {
      await pumpCard(tester, buildComic());
      expect(find.text('NUEVO'), findsOneWidget);
      expect(find.textContaining('Pág.'), findsNothing);
    });

    testWidgets('shows "Leyendo" and the current page while reading',
        (tester) async {
      await pumpCard(tester, buildComic(isReading: true, currentReadPage: 4));
      expect(find.text('LEYENDO'), findsOneWidget);
      expect(find.text('Pág. 5'), findsOneWidget);
    });

    testWidgets('shows "Completado" and hides the page for completed comics',
        (tester) async {
      await pumpCard(
        tester,
        buildComic(isCompleted: true, isReading: true, currentReadPage: 9),
      );
      expect(find.text('COMPLETADO'), findsOneWidget);
      expect(find.text('LEYENDO'), findsNothing);
      expect(find.textContaining('Pág.'), findsNothing);
    });

    testWidgets('shows no chip for a started comic that is not reading',
        (tester) async {
      await pumpCard(tester, buildComic(currentReadPage: 2));
      expect(find.text('NUEVO'), findsNothing);
      expect(find.text('LEYENDO'), findsNothing);
      expect(find.text('COMPLETADO'), findsNothing);
      expect(find.text('Pág. 3'), findsOneWidget);
    });
  });

  group('ComicCard cover', () {
    testWidgets('shows the book placeholder when there is no picture',
        (tester) async {
      await pumpCard(tester, buildComic());
      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('uses the dark card color for the placeholder in dark mode',
        (tester) async {
      await pumpCard(tester, buildComic(), themeMode: ThemeMode.dark);
      final container = tester.widget<Container>(
        find
            .ancestor(
                of: find.byIcon(Icons.book), matching: find.byType(Container))
            .first,
      );
      expect(container.color, AppColorsDark.cardColor);
    });

    testWidgets('renders Image.file when a picture path is set',
        (tester) async {
      final cover = images.write('cover.png');
      await precacheFileImages(tester, [cover]);
      await pumpCard(tester, buildComic(picture: cover.path));

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.book), findsNothing);
    });

    testWidgets('falls back to the placeholder if the image cannot load',
        (tester) async {
      await pumpCard(
        tester,
        buildComic(picture: '${images.dir.path}/does_not_exist.png'),
      );
      await settleRealIo(tester);

      expect(find.byIcon(Icons.book), findsOneWidget);
    });
  });

  group('ComicCard edit badge', () {
    testWidgets('is hidden when onEdit is null', (tester) async {
      await pumpCard(tester, buildComic());
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('is shown and invokes onEdit when tapped', (tester) async {
      var taps = 0;
      await pumpCard(tester, buildComic(), onEdit: () => taps++);

      expect(find.byIcon(Icons.edit), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit));
      expect(taps, 1);
    });
  });

  testWidgets('keeps a 3:4 aspect ratio', (tester) async {
    await pumpCard(tester, buildComic());
    final size = tester.getSize(find.byType(ComicCard));
    expect(size.width, 150);
    expect(size.height, closeTo(200, 0.01));
  });
}
