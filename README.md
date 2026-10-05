# 📦 Manga Reader (Legacy / Archived Engine)

> **ESTADO DEL REPOSITORIO: [LEGACY / CONGELADO]**  
> Este repositorio ha sido preservado como archivo histórico de ingeniería. El desarrollo activo del producto y su versión insignia para Google Play Store se traslada al nuevo proyecto limpio **Tinta & Papel** (*Paper & Ink Manga System*).

---

## 📌 Contexto y Propósito de este Repositorio

Este repositorio sirvió como banco de pruebas y desarrollo donde se investigaron, prototiparon y estabilizaron los componentes de rendimiento más complejos del lector de manga:

1. **Motor de Lectura Inmersivo (60 FPS):**
   - Control estricto anti-OOM (*Out-Of-Memory*) mediante decodificación acotada (`ResizeImage` a ~1400px).
   - Política de ventana deslizante y desalojo activo de memoria gráfica (`evictFarPages`).
   - Soporte para 3 modos de lectura: Manga tradicional (D→I), Cómic Occidental (I→D) y Webtoon vertical continuo.
   - Gestos de zoom multitáctil a 60 FPS y doble toque para resetear escala con `InteractiveViewer`.
2. **Pipeline de Extracción en Isolates:**
   - Descompresión streaming de archivos CBR (RAR4/RAR5) y CBZ (ZIP) en hilos secundarios (`Isolate.run`), manteniendo 0 ms de bloqueo en el hilo de renderizado de Flutter.
   - Detección precisa de formato real por **Magic Bytes** binarios (`PK\x03\x04` y `Rar!\x1A\x07`).
   - Ordenamiento numérico natural (`NaturalSort`) para evitar desórdenes de capítulos (`página_2` antes de `página_10`).
   - Fingerprinting SHA-1/SHA-256 ultrarrápido (<10ms) leyendo cabecera y cola sin cargar archivos pesados completos.
3. **Especificación de Arquitectura Antigravity & Stitch Neobrutalism:**
   - Configuración nativa de Antigravity en `.agents/` con 8 subagentes especializados y 5 skills técnicas.
   - Manifiesto de reglas de arquitectura y directrices de veto en `GEMINI.md`.
   - Sistema de diseño Neobrutalista Stitch `16775015463770804252` con bordes sólidos de 2px, sombras duras `Offset(2.5, 2.5)` sin desenfoque y microinteracción táctil `+2px`.

---

## 🚀 Transición al Nuevo Proyecto: Tinta & Papel

Los módulos pulidos en este repositorio se han preparado y documentado para su trasplante directo al nuevo repositorio limpio, el cual arranca con:
- **Estructura:** Feature-First + Core desacoplado.
- **Gestión de Estado:** Riverpod 3 moderno con Code Generation (`@riverpod`).
- **Base de Datos:** SQLite v5 AI-Ready con soporte para embeddings vectoriales (`BLOB`), FTS5, sesiones de lectura y logros.
- **Enrutamiento e i18n:** `go_router` con `StatefulShellRoute.indexedStack` y paquete oficial `flutter_localizations` (`intl`).

---

## 📂 Rama de Referencia Principal

La rama definitiva con toda la configuración nativa de Antigravity, reglas de veto, ViewModels y componentes de UI Neobrutalistas se encuentra en:

👉 **[`refactor-with-gemini`](https://github.com/funkai13/manga_reader_legacy/tree/refactor-with-gemini)**
