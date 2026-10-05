---
name: testing-playbook
description: >-
  Estrategia completa de pruebas unitarias de lógica pura, pruebas de interacción de widgets, pruebas de regresión visual Golden tests en temas claro y oscuro, y benchmarks de estrés anti-OOM para Tinta & Papel. Usar al escribir o ejecutar suites de prueba.
---

# SKILL: TESTING PLAYBOOK (WIDGET, GOLDEN, UNIT & STRESS)

> **Guía práctica para la ejecución y creación de pruebas automatizadas en Tinta & Papel.**

---

## 1. Pruebas Unitarias de Lógica Pura (Unit Tests)

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ordenamiento Alfanumérico Natural', () {
    test('página 2 debe preceder a página 10', () {
      final pages = ['page_10.jpg', 'page_2.jpg', 'page_1.jpg'];
      final sorted = sortPagesNaturally(pages);
      expect(sorted, ['page_1.jpg', 'page_2.jpg', 'page_10.jpg']);
    });
  });
}
```

---

## 2. Pruebas de Interacción de Componentes (Widget Tests)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NeoButton debe cambiar de estado visual y ejecutar callback al tap', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeoButton(
            text: 'CONTINUAR LECTURA',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    // Verificar texto
    expect(find.text('CONTINUAR LECTURA'), findsOneWidget);

    // Simular tap
    await tester.tap(find.byType(NeoButton));
    await tester.pump();
    expect(pressed, isTrue);
  });
}
```

---

## 3. Pruebas de Regresión Visual (Golden Tests)

Permiten capturar y verificar la fidelidad de los bordes y sombras Neobrutalistas pixel a pixel:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Golden Test: ActiveReadingCard en Modo Claro y Oscuro', (tester) async {
    // Configurar tamaño de pantalla estándar
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Cargar widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActiveReadingCard(comic: mockComic, onContinueReading: null),
        ),
      ),
    );

    await expectLater(
      find.byType(ActiveReadingCard),
      matchesGoldenFile('goldens/active_reading_card_light.png'),
    );
  });
}
```

- Comando de actualización de baselines golden:
  `flutter test test/golden/ --update-goldens`

---

## 4. Benchmark de Estrés y Evicción de RAM

Simula un usuario pasando 50 páginas a alta velocidad para verificar que no ocurran caídas de memoria (OOM) y que `evictFarPages()` mantenga un número acotado de páginas en memoria:

```dart
testWidgets('Prueba de estrés de navegación rápida en lector', (tester) async {
  // Montar visor con cómic de 100 páginas de prueba
  // Realizar 50 taps sucesivos de avance rápido
  for (var i = 0; i < 50; i++) {
    await tester.tapAt(const Offset(350, 500)); // Tap zona derecha
    await tester.pump(const Duration(milliseconds: 20));
  }

  // Verificar que la página actual avanzó y las páginas distantes fueron expulsadas
  expect(activeCachedPagesCount, lessThanOrEqualTo(5));
});
```
