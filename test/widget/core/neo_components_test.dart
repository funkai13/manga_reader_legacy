import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/core/widgets/neo_button.dart';
import 'package:manga_reader/core/widgets/neo_card.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';

import '../../helpers/widget/pump_app.dart';
import '../../helpers/widget/test_images.dart';

void main() {
  group('NeoButton', () {
    testWidgets('renders text in uppercase by default', (tester) async {
      await pumpApp(
        tester,
        NeoButton(
          text: 'Continuar',
          onPressed: () {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('CONTINUAR'), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
    });

    testWidgets('renders text as-is when isUppercase is false', (tester) async {
      await pumpApp(
        tester,
        NeoButton(
          text: 'Continuar',
          isUppercase: false,
          onPressed: () {},
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('CONTINUAR'), findsNothing);
    });

    testWidgets('renders icon when provided', (tester) async {
      await pumpApp(
        tester,
        NeoButton(
          text: 'Descargar',
          icon: Icons.download,
          onPressed: () {},
        ),
        wrapInScaffold: true,
      );

      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.text('DESCARGAR'), findsOneWidget);
    });

    testWidgets('triggers onPressed on tap and performs press animation',
        (tester) async {
      var pressed = false;
      await pumpApp(
        tester,
        NeoButton(
          text: 'Pulsar',
          onPressed: () => pressed = true,
        ),
        wrapInScaffold: true,
      );

      final buttonFinder = find.byType(NeoButton);

      // Tap down triggers the forward animation (scale down)
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump(const Duration(milliseconds: 50));
      expect(pressed, isFalse);

      // Tap up triggers reverse animation and onPressed
      await gesture.up();
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('tap cancel reverses animation without triggering onPressed',
        (tester) async {
      var pressed = false;
      await pumpApp(
        tester,
        NeoButton(
          text: 'Cancelar Acción',
          onPressed: () => pressed = true,
        ),
        wrapInScaffold: true,
      );

      final buttonFinder = find.byType(NeoButton);
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(pressed, isFalse);
    });

    testWidgets('disabled button does not trigger when onPressed is null',
        (tester) async {
      await pumpApp(
        tester,
        const NeoButton(
          text: 'Deshabilitado',
          onPressed: null,
        ),
        wrapInScaffold: true,
      );

      expect(find.text('DESHABILITADO'), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(NeoButton)));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('applies custom background and foreground colors', (tester) async {
      const customBg = Colors.purple;
      const customFg = Colors.yellow;

      await pumpApp(
        tester,
        NeoButton(
          text: 'Colores',
          backgroundColor: customBg,
          foregroundColor: customFg,
          icon: Icons.palette,
          onPressed: () {},
        ),
        wrapInScaffold: true,
      );

      final text = tester.widget<Text>(find.text('COLORES'));
      expect(text.style?.color, customFg);

      final icon = tester.widget<Icon>(find.byIcon(Icons.palette));
      expect(icon.color, customFg);
    });
  });

  group('NeoOutlinedButton', () {
    testWidgets('renders NeoOutlinedButton with text and handles tap',
        (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        NeoOutlinedButton(
          text: 'Borde',
          icon: Icons.border_outer,
          onPressed: () => tapped = true,
        ),
        wrapInScaffold: true,
      );

      expect(find.text('BORDE'), findsOneWidget);
      expect(find.byIcon(Icons.border_outer), findsOneWidget);

      await tester.tap(find.byType(NeoOutlinedButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('NeoCard', () {
    testWidgets('renders static NeoCard without tap interaction', (tester) async {
      await pumpApp(
        tester,
        const NeoCard(
          width: 200,
          height: 150,
          padding: EdgeInsets.all(20),
          backgroundColor: Colors.amber,
          child: Text('Card Content'),
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(NeoCard), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.amber);
      expect(container.constraints?.minWidth, 200);
      expect(container.constraints?.minHeight, 150);
    });

    testWidgets('renders interactive NeoCard with onTap and InkWell',
        (tester) async {
      var cardTapped = false;
      await pumpApp(
        tester,
        NeoCard(
          onTap: () => cardTapped = true,
          child: const Text('Interactive Card'),
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Interactive Card'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.text('Interactive Card'));
      await tester.pumpAndSettle();

      expect(cardTapped, isTrue);
    });

    testWidgets('adapts border color for dark mode', (tester) async {
      await pumpApp(
        tester,
        const NeoCard(
          child: Text('Dark Card'),
        ),
        wrapInScaffold: true,
        themeMode: ThemeMode.dark,
      );

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(NeoCard), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, AppColorsDark.borderColor);
    });
  });

  group('NeoLoadingIndicator', () {
    testWidgets('renders with custom size and rotates over time', (tester) async {
      await pumpApp(
        tester,
        const NeoLoadingIndicator(size: 60.0),
        wrapInScaffold: true,
      );

      final indicatorFinder = find.byType(NeoLoadingIndicator);
      expect(indicatorFinder, findsOneWidget);

      final rotationFinder = find.descendant(
        of: indicatorFinder,
        matching: find.byType(RotationTransition),
      );
      expect(rotationFinder, findsOneWidget);

      final initialTransition = tester.widget<RotationTransition>(
        rotationFinder,
      );
      final initialTurns = initialTransition.turns.value;

      await tester.pump(const Duration(milliseconds: 500));

      final updatedTransition = tester.widget<RotationTransition>(
        rotationFinder,
      );
      expect(updatedTransition.turns.value, isNot(equals(initialTurns)));
    });
  });

  group('NeoShimmer', () {
    testWidgets('renders with width, height and animates opacity', (tester) async {
      await pumpApp(
        tester,
        const NeoShimmer(
          width: 120,
          height: 40,
          borderRadius: 8.0,
        ),
        wrapInScaffold: true,
      );

      expect(find.byType(NeoShimmer), findsOneWidget);

      final initialOpacity =
          tester.widget<Opacity>(find.descendant(of: find.byType(NeoShimmer), matching: find.byType(Opacity)));
      final firstVal = initialOpacity.opacity;

      await tester.pump(const Duration(milliseconds: 400));

      final nextOpacity =
          tester.widget<Opacity>(find.descendant(of: find.byType(NeoShimmer), matching: find.byType(Opacity)));
      expect(nextOpacity.opacity, isNot(equals(firstVal)));
    });
  });

  group('NeoErrorWidget', () {
    testWidgets('renders error message and retry button when onRetry provided',
        (tester) async {
      var retried = false;
      await pumpApp(
        tester,
        NeoErrorWidget(
          message: 'Error al conectar',
          onRetry: () => retried = true,
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Error al conectar'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);

      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('renders error message without retry button when onRetry is null',
        (tester) async {
      await pumpApp(
        tester,
        const NeoErrorWidget(
          message: 'Error fatal',
        ),
        wrapInScaffold: true,
      );

      expect(find.text('Error fatal'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('REINTENTAR'), findsNothing);
    });
  });

  group('NeoEmptyWidget', () {
    testWidgets('renders message and specified icon', (tester) async {
      await pumpApp(
        tester,
        const NeoEmptyWidget(
          message: 'No hay elementos guardados',
          icon: Icons.bookmark_border,
        ),
        wrapInScaffold: true,
      );

      expect(find.text('No hay elementos guardados'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });
  });

  group('NeoLoadingOverlay', () {
    testWidgets('renders overlay with indicator and default message',
        (tester) async {
      await pumpApp(
        tester,
        const NeoLoadingOverlay(),
        wrapInScaffold: true,
      );

      expect(find.text('CARGANDO...'), findsOneWidget);
      expect(find.byType(NeoLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders overlay with custom message', (tester) async {
      await pumpApp(
        tester,
        const NeoLoadingOverlay(message: 'IMPORTANDO ARCHIVOS...'),
        wrapInScaffold: true,
      );

      expect(find.text('IMPORTANDO ARCHIVOS...'), findsOneWidget);
      expect(find.byType(NeoLoadingIndicator), findsOneWidget);
    });
  });

  group('showNeoSnackBar', () {
    testWidgets('shows standard snackbar message', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showNeoSnackBar(context, 'Operación exitosa'),
            child: const Text('Show SnackBar'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      expect(find.text('Operación exitosa'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows error snackbar message with error style', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                showNeoSnackBar(context, 'Fallo la descarga', isError: true),
            child: const Text('Show Error SnackBar'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('Show Error SnackBar'));
      await tester.pump();

      expect(find.text('Fallo la descarga'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, AppColorsLight.errorColor);
    });
  });

  group('FileThumbnail', () {
    late TestImageDir testDir;
    late File testFile;

    setUpAll(() {
      testDir = TestImageDir.create();
      testFile = testDir.write('thumb.png', kOnePixelPng);
    });

    tearDownAll(() => testDir.delete());

    testWidgets('renders image with specified dimensions and fit',
        (tester) async {
      await pumpApp(
        tester,
        FileThumbnail(
          testFile.path,
          width: 80,
          height: 120,
          fit: BoxFit.fill,
        ),
        wrapInScaffold: true,
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 80);
      expect(image.height, 120);
      expect(image.fit, BoxFit.fill);
      expect(image.image, isA<ResizeImage>());
    });

    testWidgets('renders fallback width when unconstrained', (tester) async {
      await pumpApp(
        tester,
        UnconstrainedBox(
          child: FileThumbnail(testFile.path),
        ),
        wrapInScaffold: true,
      );

      expect(find.byType(FileThumbnail), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('triggers errorBuilder on invalid file path', (tester) async {
      await pumpApp(
        tester,
        FileThumbnail(
          'non_existent_file_path.png',
          errorBuilder: (context, error, stackTrace) =>
              const Text('Error al cargar miniatura'),
        ),
        wrapInScaffold: true,
      );

      await settleRealIo(tester);
      expect(find.text('Error al cargar miniatura'), findsOneWidget);
    });
  });
}
