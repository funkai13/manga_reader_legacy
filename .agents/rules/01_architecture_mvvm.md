---
description: Reglas de arquitectura Feature-First + Core, separación estricta de Screens vs Widgets, e inmutabilidad con Riverpod 3 code generation.
trigger: always_on
---

# ARQUITECTURA FEATURE-FIRST + CORE: TINTA & PAPEL

> **Estándar arquitectónico oficial para el desarrollo y mantenimiento del proyecto.**

---

## 1. Filosofía Feature-First (Empaquetado por Características)

A diferencia de la arquitectura por capas tradicional (donde todas las vistas o modelos se agrupan juntos), **Tinta & Papel** adopta una estructura **Feature-First**:
- Todo lo que pertenece a una funcionalidad (`home`, `reader`, `library`, `details`, `edge_ai`, `profile`, `shell`) se encapsula dentro de su propio directorio en `features/`.
- Cada feature implementa un patrón **MVVM pragmático y ligero**:
  - `screens/`: Armazones orquestadores principales (`Scaffold`, `SafeArea`, `RefreshIndicator`).
  - `widgets/`: Componentes atómicos modulares (Optimización de re-renders).
  - `viewmodels/`: Gestión de estado reactivo mediante `Notifier` de Riverpod 3.
  - `services/`: Lógica de I/O, isolates o integraciones locales específicas.
- Lo verdaderamente transversal (tokens de diseño Stitch, componentes base, SQLite y modelos globales) reside en `core/`.

---

## 2. Distinción Estricta: Screens vs Widgets (Optimización de Re-renders)

Para asegurar 60 FPS estables y evitar re-renderizados innecesarios en Flutter, se establece una separación estricta:

### A. Screens (`screens/`) — El Armazón / Cajón
- **Propósito:** Actúa como la raíz estructural o contenedor de nivel superior (`Scaffold`, `SafeArea`, `AppBar`, `RefreshIndicator`).
- **Composición:** No debe contener árboles de widgets anidados de cientos de líneas. Su único trabajo es armar y ensamblar los widgets modulares de la feature.
- **Ciclo de vida y Diálogos:** Maneja navegación, apertura de BottomSheets, diálogos y SnackBars. Escucha eventos únicos usando `ref.listen()`.
- **Ventaja:** El Scaffold permanece inmutable mientras los widgets internos actualizan sus estados de forma independiente.

### B. Widgets (`widgets/`) — Componentes Atómicos y Scoping de Render
- **Propósito:** Elementos individuales con responsabilidad única (ej. `HomeFilterPills`, `ActiveReadingCard`, `ComicShelfItem`).
- **Constructores `const`:** Obligatorios siempre que sus propiedades lo permitan para que Flutter los omita completamente del ciclo de reconstrucción.
- **Suscripciones Granulares de Riverpod:** Los widgets deben suscribirse únicamente a la propiedad del estado que les concierne mediante `.select()`:
  ```dart
  // Solo se reconstruye si cambia el filtro, sin afectar al resto de la pantalla:
  final filter = ref.watch(homeViewModelProvider.select((s) => s.activeFilter));
  ```
- **Testeabilidad:** Permite realizar **Widget Tests** y **Golden Tests** sobre componentes aislados en milisegundos, sin tener que montar toda la pantalla.

---

## 3. Gestión de Estado Oficial: `@riverpod` (Riverpod Generator)

Todo ViewModel debe implementarse usando la sintaxis moderna basada en anotaciones de código (`riverpod_annotation` y `riverpod_generator`), eliminando por completo los proveedores manuales antiguos:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/home_state.dart';

part 'home_viewmodel.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeState build() {
    // Auto-dispose activado por defecto para máxima eficiencia de memoria
    return const HomeState(isLoading: true);
  }

  Future<void> loadComics() async {
    // Lógica asíncrona inmutable
    state = state.copyWith(isLoading: false);
  }
}
```

### Ventajas Técnicas:
1. **Auto-Dispose por Defecto:** Al salir de una pantalla, Riverpod destruye y limpia el estado automáticamente, liberando memoria RAM.
2. **Tipado Estricto en Compilación:** Genera código fuertemente tipado (`homeViewModelProvider`), previniendo errores de runtime.
3. **Auditoría con `riverpod_lint`:** Reglas automáticas en el IDE que advierten al desarrollador si olvida un `ref.watch` o muta el estado indebidamente.

---

## 4. Estructura de Directorios

```text
lib/
├── core/
│   ├── theme/
│   │   ├── colors.dart               # NeoColors, AppColorsLight, AppColorsDark
│   │   ├── typography.dart           # Space Grotesk, JetBrains Mono, Work Sans
│   │   └── theme.dart                # ThemeData Neobrutalista completo
│   ├── utils/
│   │   └── constants.dart            # Bordes (2px), sombras (2.5, 2.5), radios (4px)
│   ├── widgets/
│   │   ├── neo_card.dart             # Tarjeta con borde y sombra dura
│   │   ├── neo_button.dart           # Botón con efecto de depresión al tap (+2px)
│   │   └── neo_loading.dart          # Spinner de carga Neobrutalista
│   ├── database/
│   │   └── comic_database.dart       # SQLite (comics.db), migraciones e índices
│   ├── storage/
│   │   └── comic_storage.dart        # Rutas relativas seguras para iOS y Android
│   └── models/
│       ├── comic.dart                # Entidad global inmutable Comic
│       └── reading_mode.dart         # Enum ReadingMode (Manga, Cómic, Webtoon)
│
└── features/
    ├── shell/
    │   └── screens/
    │       └── main_shell_screen.dart # Armazón dock inferior Neobrutalista (4 tabs)
    ├── home/
    │   ├── screens/
    │   │   └── home_screen.dart       # Scaffold principal de la estantería
    │   ├── widgets/
    │   │   ├── active_reading_card.dart # Escaparate de lectura activa [Viñeta Activa]
    │   │   ├── comic_search_bar.dart    # Barra de búsqueda con bordes de tinta
    │   │   ├── home_filter_pills.dart   # Pills de filtro con badges de conteo
    │   │   ├── comic_shelf_item.dart    # Portada de cómic individual
    │   │   └── shelf_section.dart       # Cuadrícula tankōbon o lista horizontal
    │   ├── viewmodels/
    │   │   └── home_viewmodel.dart      # Notifier de biblioteca con @riverpod
    │   └── models/
    │       └── home_state.dart          # Estado inmutable con copyWith
    ├── reader/
    │   ├── screens/
    │   │   └── comic_viewer_screen.dart # Visor inmersivo a 60 FPS
    │   └── widgets/
    │       ├── interactive_page_view.dart # Motor de gestos y zoom interactivo
    │       └── viewer_overlay.dart        # Controles Neobrutalistas flotantes
    ├── library/
    │   └── screens/
    │       └── collections_screen.dart    # Sagas y colecciones fanned-out 3D
    ├── details/
    │   └── screens/
    │       └── comic_details_screen.dart  # Ficha técnica editorial y metadatos
    └── profile/
        └── screens/
            └── profile_screen.dart        # Estadísticas, horas leídas, rachas y logros
```
