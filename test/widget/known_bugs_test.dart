// Tests that document real bugs found in lib/ while writing the widget and
// golden suites. Each group is skipped with a `BUG:` reason; remove the skip
// once the bug is fixed and the test should pass.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_metadata_dialog.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comics_grid.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/emtpy_comics_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/search_bar.dart';

import '../helpers/widget/fakes.dart';
import '../helpers/widget/pump_app.dart';

void main() {
  setUpAll(registerTestFallbacks);

  group(
    'ComicsGrid on tablet',
    () {
      testWidgets('renders completed/reading comics without overflow',
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
      });
    },
    skip: 'BUG: ComicCard._buildStatusChip no es Flexible; con '
        'ComicsGrid (maxCrossAxisExtent 200, scale 1.0) en tablet el chip '
        '"Completado" (10.sp + padding 8.w) no cabe y la Row lanza '
        '"RenderFlex overflowed".',
  );

  group(
    'Search bar on phones',
    () {
      testWidgets('hint text is not clipped by the text field', (tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => CustomScrollView(slivers: [
                buildSearchBar(context, sampleComics(), false, 1.0,
                    SearchController(), FocusNode(), false),
              ]),
            ),
          ),
        );
        final field = tester.getRect(find.byType(TextField));
        final hint = tester.getRect(find.text('Buscar en tu biblioteca'));
        expect(hint.top, greaterThanOrEqualTo(field.top));
        expect(hint.bottom, lessThanOrEqualTo(field.bottom));
      });
    },
    skip: 'BUG: buildSearchBar fija la SearchBar a 50px de alto con padding '
        'vertical 8.h; el TextField interno queda de ~11px y el hint '
        '"Buscar en tu biblioteca" se ve recortado en teléfonos '
        '(ver goldens home_screen_phone_*).',
  );

  group(
    'EmptyComicsScreen in dark mode',
    () {
      testWidgets('icon and subtitle use readable colors', (tester) async {
        await pumpApp(tester, EmptyComicsScreen(onAddComic: () {}),
            themeMode: ThemeMode.dark);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        final subtitle = tester
            .widget<Text>(find.text('Agrega tu primer comic para comenzar.'));
        expect(subtitle.style?.color, isNot(Colors.black54));
        final icon = tester.widget<Icon>(find.byIcon(Icons.menu_book_rounded));
        expect(icon.color!.computeLuminance(), greaterThan(0.1));
      });
    },
    skip: 'BUG: EmptyComicsScreen usa colores fijos (Colors.black54 y '
        'black 35%) para el icono y el subtítulo, que son invisibles sobre '
        'el fondo negro del tema oscuro (ver golden empty_screen_*_dark).',
  );

  group(
    'ComicMetadataDialog in dark mode',
    () {
      testWidgets('autocomplete fields use the dark fill color',
          (tester) async {
        await pumpApp(
          tester,
          const Scaffold(body: ComicMetadataDialog(fileName: 'a.cbz')),
          themeMode: ThemeMode.dark,
          overrides: testOverrides(),
        );
        final decorator = tester.widget<InputDecorator>(find
            .ancestor(
                of: find.text('Autor'), matching: find.byType(InputDecorator))
            .first);
        expect(decorator.decoration.fillColor, AppColorsDark.cardColor);
      });
    },
    skip: 'BUG: ComicMetadataDialog no pasa isDark a CustomAutocompleteField, '
        'así que en tema oscuro Autor/Género/Colección se pintan con el '
        'relleno claro (ver golden metadata_dialog_*_dark).',
  );
}
