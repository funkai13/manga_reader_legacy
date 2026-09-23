import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/widgets/generic_dialog.dart';
import 'package:manga_reader/core/widgets/generic_grid.dart';
import 'package:manga_reader/core/widgets/responsive_layout.dart';

import '../../helpers/widget/pump_app.dart';

void main() {
  group('DialogService', () {
    Future<void> pumpDialogHost(
      WidgetTester tester,
      Future<void> Function(DialogService, BuildContext) action,
    ) async {
      await pumpApp(
        tester,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    action(ref.read(dialogServiceProvider), context),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('showErrorDialog shows title/message and closes on Aceptar',
        (tester) async {
      var completed = false;
      await pumpDialogHost(tester, (service, context) async {
        await service.showErrorDialog(context,
            title: 'Error', message: 'Algo salió mal');
        completed = true;
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Algo salió mal'), findsOneWidget);
      expect(completed, isFalse);

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(completed, isTrue);
    });

    testWidgets('showInfoDialog shows the info dialog', (tester) async {
      await pumpDialogHost(tester, (service, context) {
        return service.showInfoDialog(context,
            title: 'Info', message: 'Todo bien');
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Todo bien'), findsOneWidget);

      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(find.text('Info'), findsNothing);
    });

    test('dialogServiceProvider exposes a DialogService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(dialogServiceProvider), isA<DialogService>());
    });
  });

  group('GenericGrid', () {
    testWidgets('builds one tile per item with the given delegate',
        (tester) async {
      await pumpApp(
        tester,
        GenericGrid<String>(
          items: const ['a', 'b', 'c'],
          maxCrossAxisExtent: 150,
          crossAxisSpacing: 8,
          mainAxisSpacing: 4,
          mainAxisExtent: 100,
          itemBuilder: (item) => Text('item $item'),
        ),
        wrapInScaffold: true,
      );

      expect(find.text('item a'), findsOneWidget);
      expect(find.text('item b'), findsOneWidget);
      expect(find.text('item c'), findsOneWidget);

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(delegate.maxCrossAxisExtent, 150);
      expect(delegate.mainAxisExtent, 100);
      expect(delegate.crossAxisSpacing, 8);
      expect(delegate.mainAxisSpacing, 4);
    });

    testWidgets('renders nothing for an empty list', (tester) async {
      await pumpApp(
        tester,
        GenericGrid<int>(
          items: const [],
          maxCrossAxisExtent: 150,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: 100,
          itemBuilder: (item) => Text('$item'),
        ),
        wrapInScaffold: true,
      );
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });
  });

  group('ResponsiveLayout', () {
    const layout = ResponsiveLayout(
      mobileBody: Text('mobile'),
      tabletBody: Text('tablet'),
    );

    testWidgets('shows the mobile body under 600px', (tester) async {
      await pumpApp(tester, layout, wrapInScaffold: true, size: kPhoneSize);
      expect(find.text('mobile'), findsOneWidget);
      expect(find.text('tablet'), findsNothing);
    });

    testWidgets('shows the tablet body at 600px or wider', (tester) async {
      await pumpApp(tester, layout, wrapInScaffold: true, size: kTabletSize);
      expect(find.text('tablet'), findsOneWidget);
      expect(find.text('mobile'), findsNothing);
    });

    testWidgets('breakpoint is exactly 600', (tester) async {
      await pumpApp(tester, layout,
          wrapInScaffold: true, size: const Size(599, 800));
      expect(find.text('mobile'), findsOneWidget);

      await pumpApp(tester, layout,
          wrapInScaffold: true, size: const Size(600, 800));
      expect(find.text('tablet'), findsOneWidget);
    });
  });
}
