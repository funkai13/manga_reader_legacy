---
description: Hoja de ruta y especificaci�n de funcionalidades para V1.0 MVP, V1.5 Edge AI y V2.0 Sem�ntico, cat�logo de gamificaci�n y rachas.
trigger: model_decision
---
# HOJA DE RUTA Y ESPECIFICACIÓN DE FEATURES: TINTA & PAPEL

> **Definición de Alcance, Horizontes de Lanzamiento y Sistema de Gamificación.**

---

## 1. Horizonte 1: V1.0 MVP (Lanzamiento en Google Play & Portfolio)

### A. Gestión de Biblioteca Neobrutalista (`features/home`)
- **Ingesta en Isolates:** Importación individual y por lote de archivos `.cbz` y `.cbr` (ZIP, RAR4, RAR5) sin jank.
- **Detección por Magic Bytes:** Identificación real del formato por cabeceras binarias (`PK\x03\x04` y `Rar!\x1A\x07`), ignorando extensiones erróneas.
- **Fingerprinting Instantáneo:** Hash SHA-1 de tamaño + cabecera (64KB) + cola (64KB) calculado en menos de 10ms para bloquear duplicados.
- **Metadatos Automáticos:** Parser de `ComicInfo.xml` (título, autor, tomo, sinopsis, género, modo de lectura).
- **Estantería Dual:**
  - Modo Cuadrícula tankōbon en proporción 1:1.41 con bordes de tinta y sombras duras.
  - Modo Lista horizontal con barra de progreso y detalles del archivo.
- **Escaparate `[VIÑETA ACTIVA]`:** Card destacada en Home que permite reanudar la lectura del cómic en curso con 1 tap.
- **Filtros Reactivos:** Pills con contador en tiempo real (`Todos`, `CBZ`, `CBR`, `En curso`, `Completados`).
- **Búsqueda Instantánea:** Filtrado en tiempo real por título, autor o género.

### B. Motor de Lectura Inmersivo Anti-OOM (`features/reader`)
- **Inmersión Total:** `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` sin barras del sistema.
- **3 Modos de Lectura Persistentes por Cómic:**
  - *Manga:* Derecha a Izquierda.
  - *Cómic Occidental:* Izquierda a Derecha.
  - *Webtoon:* Desplazamiento vertical continuo y suave.
- **Zoom Interactivo a 60 FPS:** `InteractiveViewer` fluido con soporte multitáctil y doble toque.
- **Garantía Anti-OOM (Memoria Acotada):**
  - `ResizeImage` obligatorio (máximo 2x ancho físico de pantalla).
  - Evicción activa de caché (`evictFarPages`) para páginas fuera de un radio de 4.
  - Precarga de páginas adyacentes (`+1`, `-1`).
- **Navegación Táctil:** Zonas laterales (30% izquierda, 30% derecha) y zona central (40% para controles Neobrutalistas).
- **Hoja de Miniaturas:** Grid flotante para saltar a cualquier página.
- **Guardado Transparente:** La página actual se persiste automáticamente en SQLite tras cada cambio.

### C. Colecciones & Sagas (`features/library`)
- **Agrupación Automática:** Filtros por Colección/Serie, Autor y Género.
- **Tarjetas 3D Fanned-Out:** Portadas inclinadas con rotación en perspectiva simulando tomos físicos.
- **Modal de Inspección:** Vista detallada de todos los números que componen una saga.

### D. Ficha Técnica & Enriquecimiento de Metadatos (`features/details`)
- **Detalles Editoriales:** Callout con sinopsis de `ComicInfo.xml` o generada.
- **Cajas Métricas:** Formato, Páginas, Tamaño en MB, Estado de lectura.
- **Selector de Modo de Lectura:** Modificación en caliente entre Manga, Cómic y Webtoon.
- **Sanitizador Automático de Nombres:** Algoritmo Regex que limpia etiquetas de grupos de escaneo `[...]` y `(...)` al importar archivos sin XML para extraer título limpio y número de tomo.
- **Editor Manual Neobrutalista:** Formulario interactivo para que el usuario pueda editar título, autor, tomo, colección, género y sinopsis.
- **Auto-Completado con APIs Públicas:** Botón *"BUSCAR EN LÍNEA 🌐"* que consulta APIs abiertas gratuitas (Jikan / MyAnimeList y MangaDex sin API key) para rellenar autor, sinopsis, géneros y portada oficial con un solo toque.

### E. Perfil de Usuario & Gamificación (`features/profile`)
- **Rachas de Lectura Diaria (Streaks):**
  - Contador de días consecutivos de lectura (🔥 *Racha activa*).
  - Récord histórico de racha máxima.
- **Métricas de Hábito:**
  - Horas totales de lectura acumuladas.
  - Tomos completados y páginas leídas.
- **Insignias y Sellos de Honor (Badges):**
  - 🦉 *Lector Nocturno* (Lectura entre 12:00 AM y 5:00 AM).
  - ☀️ *Lectura Matutina* (Lectura antes de las 8:00 AM).
  - 🔥 *Semana Imparable* (Racha de 7 días consecutivos).
  - ⚡ *Devorador de Viñetas* (Más de 200 páginas en un día).
  - 📚 *Biblioteca de Alejandría* (20 cómics importados).
  - 🎌 *Manga Master* (Primer tomo completado en modo Manga).
  - 🏁 *Tomo Final* (Completar un tomo de más de 300 páginas).
- **Ajustes:**
  - Selector de tema Claro (Papel Pergamino) / Oscuro (Noche de Tinta).
  - Internacionalización: Español e Inglés.

---

## 2. Horizonte 2: V1.5 (Edge AI On-Device & Herramientas)

- **OCR Local con Google ML Kit (`features/edge_ai`):**
  - Modo "Inspección de Globo": Tocar un globo de diálogo extrae el texto en menos de 200ms sin conexión a internet.
  - Bounding box Neobrutalista alrededor del globo tocado.
- **Traducción On-Device:**
  - Traducción local mediante modelos descargables de ML Kit (ej. inglés/japonés a español) en tarjeta flotante.
- **Marcadores de Viñetas:** Posibilidad de guardar viñetas destacadas en el perfil.
- **Backup Local:** Exportación e importación de historial y progreso en archivo JSON.

---

## 3. Horizonte 3: V2.0 (Superpoderes Semánticos)

- **Búsqueda Semántica en Isolate (SIMD):**
  - Búsqueda por lenguaje natural (*"batalla en el desierto con espadas"*).
  - Salto directo al **número de página exacto** de la escena mediante la tabla `comic_embeddings`.
- **Recapitulaciones Inteligentes ("Anteriormente en..."):**
  - Resumen automático de las últimas páginas leídas cuando un cómic no se abre en más de 10 días.
- **Auto-catalogación de Portadas sin Metadatos:**
  - Extracción de título y número de tomo desde la imagen de portada mediante OCR.
