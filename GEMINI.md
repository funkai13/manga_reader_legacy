# MANIFIESTO Y REGLAS DE ARQUITECTURA: TINTA & PAPEL (PAPER & INK)

> **Manga & Comic Reader Engine con Sistema Neobrutalista e Inteligencia Artificial Local (Edge AI)**  
> **Objetivo:** Aplicación insignia para Google Play Store y Portafolio Profesional en LinkedIn.

Este archivo define las reglas estrictas de desarrollo, arquitectura, rendimiento y veto para el proyecto **Tinta & Papel** (*Paper & Ink Manga System*, Stitch `16775015463770804252`). Todo agente y desarrollador que opere en este repositorio debe cumplir estas normas sin excepción.

---

## 1. Alcance del Proyecto y Formatos Soportados (V1.0 MVP)

- **Formatos Soportados:** Exclusivamente **CBR (.cbr / RAR)** y **CBZ (.cbz / ZIP)**.
- **Exclusión de PDF:** Queda **ESTRICTAMENTE PROHIBIDO** implementar soporte para PDF en la V1.0. La librería PDFium agrega ~35MB al APK y ralentiza la carga. PDF queda diferido para la versión V1.5+.
- **Metas de Calidad:**
  - Google Play Store: Cero cuelgues por Out-Of-Memory (OOM), arranque en <1.2s, inmersión total (`SystemUiMode.immersiveSticky`), 100% offline y privacidad total.
  - LinkedIn Showcase: Código limpio con arquitectura Feature-First + MVVM desacoplado, Riverpod 3 `@riverpod`, commits semánticos y suite de pruebas integral (Unit, Widget, Golden, Stress).

---

## 2. Estructura de Proyecto: Feature-First + Core

Todo el código en `lib/` debe estructurarse bajo el principio **Feature-First**:

```text
lib/
├── core/                         # Infraestructura transversal (sin dependencias de features)
│   ├── database/                 # SQLite (ComicDatabase, migraciones, FTS5, embeddings)
│   ├── router/                   # go_router con StatefulShellRoute.indexedStack (4 pestañas)
│   ├── theme/                    # Stitch Design Tokens (colores, bordes, sombras, tipografía)
│   ├── widgets/                  # Componentes Neobrutalistas atómicos (StitchButton, NeoCard, Badge)
│   ├── services/                 # Servicios globales (StorageService, HapticService)
│   └── utils/                    # NaturalSort, ImageUtils, Helpers
├── features/                     # Módulos desacoplados por funcionalidad
│   ├── home/                     # Biblioteca principal, estantería dual y escaparate [Viñeta Activa]
│   ├── reader/                   # Motor de lectura inmersivo (CBR/CBZ, zoom 60 FPS, 3 modos)
│   ├── search/                   # Búsqueda semántica, FTS5 y filtros
│   ├── profile/                  # Perfil, estadísticas de lectura, rachas diarias y logros
│   ├── metadata_enrichment/      # APIs públicas (Jikan/MangaDex), sanitizer Regex y editor manual
│   └── settings/                 # Preferencias de lectura, tema e internacionalización
├── l10n/                         # Internacionalización oficial (app_en.arb, app_es.arb)
└── main.dart                     # Entrypoint con ProviderScope
```

---

## 3. Regla Fundamental: Pantallas (`screens/`) vs Widgets (`widgets/`)

Para mantener un código limpio, desacoplado y de alto rendimiento:

1. **Pantallas (`screens/`):**
   - Son el armazón / Scaffold orquestador de la ruta (`Scaffold`, `SafeArea`, `RefreshIndicator`).
   - Manejan navegación, apertura de BottomSheets, diálogos y SnackBars.
   - Escuchan eventos de ciclo de vida y eventos únicos usando `ref.listen()`.
   - **No deben contener árboles gigantes de UI anidada.** Delegan la renderización a widgets atómicos.
2. **Widgets (`widgets/`):**
   - Son componentes atómicos, reutilizables y preferiblemente `const`.
   - Consumen estado específico utilizando `ref.watch(miProvider.select((state) => state.campoEspecifico))`.
   - **Prohibido** provocar rebuilds de toda la pantalla ante cambios locales de un widget.

---

## 4. Gestión de Estado: Riverpod 3 con Code Generation (`@riverpod`)

- **Obligatorio:** Utilizar exclusivamente la sintaxis moderna con generador:
  - `@riverpod class MiViewModel extends _$MiViewModel`
  - `@riverpod Future<T> miFuncion(MiFuncionRef ref)`
- **Prohibido:** Quedan obsoletos y vetados `StateNotifierProvider`, `ChangeNotifierProvider` y declaraciones manuales de `NotifierProvider`.
- **Inmutabilidad:** Todo estado debe ser inmutable (`@freezed` o clases con `final` y `copyWith`). Queda estrictamente vetada la mutación in-place (`state.comics.add(...)`).
- **Auto-Dispose:** Todo provider de pantalla debe auto-desecharse (`autoDispose` por defecto con `@riverpod`) para evitar retención innecesaria de memoria al navegar.
- **Sin BuildContext:** Los ViewModels nunca deben recibir ni almacenar referencias a `BuildContext`.

---

## 5. Motor de Lectura y Reglas Críticas Anti-OOM (Out-Of-Memory)

### El Problema del Bitmap OOM
Un archivo `.cbz` o `.cbr` típico contiene escaneos de 3840 x 5760 píxeles a 32 bits RGBA:
$$\text{RAM sin comprimir} = 3840 \times 5760 \times 4 \approx 88.47 \text{ MB por página}$$
Mantener 5 páginas sin redimensionar consume **más de 440 MB de RAM**, provocando cierre fulminante por OOM en tablets y gama media.

### Los 4 Pilares Innegociables
1. **Decodificación Acotada (`ResizeImage`):**
   ```dart
   int readerTargetDecodeWidth(BuildContext context) {
     final media = MediaQuery.sizeOf(context);
     final pixelRatio = MediaQuery.devicePixelRatioOf(context);
     return (media.width * pixelRatio * 1.5).round(); // ~1400px
   }
   ```
   Toda página debe cargarse con:
   ```dart
   ResizeImage(FileImage(File(path)), width: targetDecodeWidth, policy: ResizeImagePolicy.fit)
   ```
   Esto reduce la RAM de **88.5 MB a ~7.2 MB por página** (91.8% de ahorro).
2. **Ventana Activa y Desalojo de Caché (`evictFarPages`):**
   - Radio activo: `[Página Actual - 2]` a `[Página Actual + 2]`.
   - Evicción obligatoria: expulsar activamente del `PaintingBinding.instance.imageCache` toda página donde `|página - actual| > 4`.
   - Precarga inteligente: precargar solo `currentPage + 1` y `currentPage - 1`.
3. **Modos de Lectura Soportados:**
   - Manga Clásico: Horizontal Derecha a Izquierda (D→I).
   - Cómic Occidental: Horizontal Izquierda a Derecha (I→D).
   - Webtoon: Vertical continuo con física elástica suave.
4. **Interactividad:** 60 FPS fluidos con zoom pinch-to-zoom y doble toque para resetear escala (1.0) mediante `InteractiveViewer`.
5. **Inmersión Total:** `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` al abrir el lector; restaurar a `edgeToEdge` al salir.

---

## 6. Descompresión de Archivos: Pipeline Isolate Puro

1. **Aislamiento en Hilo Secundario:** Toda descompresión (ZIP para CBZ, RAR para CBR), parsing de `ComicInfo.xml` y cálculo de hashes debe ejecutarse dentro de `Isolate.run()`. 0 ms de bloqueo en UI.
2. **Detección por Magic Bytes:** Nunca confiar en la extensión del archivo.
   - ZIP (CBZ): `50 4B 03 04`
   - RAR (CBR): `52 61 72 21 1A 07` (RAR4 y RAR5)
3. **Ordenamiento Numérico Natural (Natural Sort):**
   - Comparación por chunks de números enteros (`\d+|\D+`) para que `página_2.jpg` siempre preceda a `página_10.jpg`.
4. **Fingerprint SHA-1 Instantáneo (<10ms):**
   - Hash SHA-1 de: `tamaño del archivo (8 bytes) + primeros 64KB + últimos 64KB`. Permite detectar duplicados en archivos de 300MB en menos de 10ms.
5. **Limpieza de Temporales:** Todo directorio en `Directory.systemTemp` debe destruirse en un bloque `finally { if (await temp.exists()) await temp.delete(recursive: true); }`.
6. **Estandarización de Archivos:** Renombrar páginas a `0001.jpg`, `0002.jpg` al extraer para bloquear ataques Zip-Slip y acelerar el renderizado.
7. **Miniaturas en Fondo:** Generar portada de 400px en `thumb/cover.jpg` en segundo plano para estanterías rápidas.

---

## 7. Base de Datos SQLite: Preparada para IA y Búsqueda Semántica

### Esquema AI-Ready (SQLite v5)
1. **Tabla `comics`:** Metadatos completos, `contentHash`, `summary`, `volume`, `fileSize`, `aiSummary`, `aiKeyThemes`, `embedding BLOB`.
2. **Tabla `comic_embeddings`:** Chunks de viñetas/diálogos con vector `BLOB` de `Float32List` e índices en `(comicId, pageNumber)` para búsqueda con número de página exacto.
3. **Tabla `comic_recaps`:** Resúmenes narrativos por rangos de lectura (`startPage`, `endPage`, `recapTitle`, `recapContent`).
4. **Tabla `reading_sessions`:** Minutos leídos, páginas consumidas y marcas temporales para analíticas y rachas.
5. **Tabla `user_achievements`:** Logros desbloqueados (`night_owl`, `streak_7`, `manga_maniac`, etc.).
6. **Tabla Virtual FTS5 `comics_fts`:** Búsqueda textual completa con tokenizador `unicode61 remove_diacritics 2`.

### Búsqueda Semántica en Isolate (Dart SIMD)
- Similitud coseno calculada sobre `Float32List` dentro de `Isolate.run` en submilisegundos (<3ms) sin dependencias de servidores.

---

## 8. Gamificación, Rachas Diarias y Metadatos Públicos

1. **Rachas de Lectura (Streaks):**
   - Contador de días consecutivos leyendo al menos 1 página o 5 minutos.
   - Récord histórico de racha máxima persistido en base de datos.
2. **Badges de Honor (Sellos Neobrutalistas):**
   - 🦉 *Lector Nocturno* (Lectura entre 12:00 AM y 5:00 AM).
   - ☀️ *Lectura Matutina* (Lectura antes de las 8:00 AM).
   - 🔥 *Semana Imparable* (Racha de 7 días consecutivos).
   - ⚡ *Devorador de Viñetas* (Más de 200 páginas leídas en un día).
   - 📚 *Biblioteca de Alejandría* (20 cómics en la biblioteca).
   - 🎌 *Manga Master* (Primer tomo completado en modo Manga).
   - 🏁 *Tomo Final* (Completar un tomo de más de 300 páginas).
3. **Enriquecimiento de Metadatos:**
   - Sanitizador Regex para títulos sin XML (elimina `[Scanlation]`, `(Digital)`, etc.).
   - Integración con APIs públicas gratuitas (Jikan/MyAnimeList y MangaDex sin API key) vía cliente HTTP con fallback a editor manual Neobrutalista.

---

## 9. Sistema de Diseño: Stitch Neobrutalism ("Tinta & Papel")

Inspirado en el sistema Stitch `16775015463770804252`:

- **Bordes:** `2.0px` sólido en color tinta (`#121316` en claro, `#383B44` en oscuro).
- **Sombras:** Hard drop shadow desplazada (`BoxShadow(color: Color(0xFF121316), offset: Offset(2.5, 2.5), blurRadius: 0)`). Cero desenfoque suave.
- **Microinteracción Mecánica:** Botones y tarjetas interactivas se comprimen físicamente `+2px` en X e Y al pulsar (`_isPressed`), reduciendo su sombra a 0 (efecto estampación táctil).
- **Paleta de Colores:**
  - Papel Pergamino (Canvas Claro): `#F5F3EC`
  - Superficie Elevada: `#ECEAE0` / `#E2DFD2`
  - Tinta China (Bordes y Texto): `#121316`
  - Naranja Manga (Acento Primario): `#D96B43`
  - Tinta Índigo (Acento Secundario): `#3E54A3`
  - Amarillo Resaltador: `#FFE156`
  - Verde Menta Neón (Éxito / Racha): `#2EC4B6`
- **Tipografía Triangular:**
  - Titulares e Impacto: **Space Grotesk** (pesos 700, 800, 900).
  - Datos Técnicos y Badges: **JetBrains Mono** (monoespaciada precisa).
  - Cuerpo de Lectura y Notas: **Work Sans** (legibilidad editorial).

---

## 10. Reglas de Veto Globales (Rechazo Inmediato)

1. **Veto a la contaminación de UI:** Rechazar cualquier widget que instancie o invoque `ComicDatabase`, `Directory`, `File`, `http.Client` o `Isolate.run`.
2. **Veto a la mutabilidad de estado:** Rechazar mutaciones in-place (`state.comics.add(...)`). Toda modificación debe emitir una nueva instancia vía `copyWith`.
3. **Veto a páginas de cómic sin ResizeImage:** Todo bitmap debe acotarse con `ResizeImage`.
4. **Veto a I/O o descompresión en el hilo principal:** Toda operación de descompresión o cálculo de hash debe usar `Isolate.run`.
5. **Veto a sombras difuminadas:** Prohibido `blurRadius > 0`. Sombras duras 100% Neobrutalistas.
6. **Veto a componentes genéricos de Material 3:** Prohibido usar FAB circular, elevaciones difusas o tarjetas redondeadas sin borde.
7. **Veto a soporte PDF en V1.0:** Exclusivamente CBZ y CBR en el lanzamiento.
8. **Veto a código recortado o placeholders:** Todo código debe escribirse completo, sin `// TODO:` ni métodos vacíos.
