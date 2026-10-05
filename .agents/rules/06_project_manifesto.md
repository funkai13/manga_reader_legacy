---
description: Manifiesto del producto Tinta & Papel, metas de publicaci�n en Google Play Store y est�ndares para LinkedIn.
trigger: always_on
---
# MANIFIESTO DEL PROYECTO: TINTA & PAPEL (PAPER & INK)

> **Manga & Comic Reader Engine con Sistema Neobrutalista e Inteligencia Artificial Local (Edge AI)**  
> **Objetivo:** Aplicación insignia para Google Play Store y Portafolio Profesional en LinkedIn.

---

## 1. Visión del Producto

**Tinta & Papel** es un lector de cómics y manga moderno, offline-first y de alto rendimiento para formatos `.cbz` y `.cbr`. Combina:
1. Una estética visual **Neobrutalista editorial** inspirada en el proyecto oficial de Google Stitch (*Paper & Ink Manga System*, Proyecto `16775015463770804252`).
2. Un **motor de lectura inmersivo a prueba de fallos de memoria (OOM)** con gestos de zoom fluido a 60 FPS, múltiples orientaciones y evicción activa de caché.
3. Un **pipeline de Inteligencia Artificial en el dispositivo (Edge AI)** utilizando **Google ML Kit** para reconocimiento óptico de caracteres (OCR) local en viñetas y globos de texto sin enviar datos a servidores externos.
4. Una **arquitectura MVVM pragmática con Riverpod 3**, garantizando código limpio, mantenible y testeable de nivel sénior.

---

## 2. Metas de Publicación y Portafolio

* **Google Play Store:**
  - Cero cuelgues por Out-Of-Memory (OOM) en dispositivos de gama media y baja.
  - Tiempos de arranque inferiores a 1.2 segundos.
  - Lectura inmersiva total (`SystemUiMode.immersiveSticky`) sin distracciones.
  - Privacidad total: ningún dato o cómic del usuario sale del dispositivo.
* **LinkedIn & Tech Showcase:**
  - Código fuente impecable con arquitectura MVVM desacoplada.
  - Commits semánticos con estándar *Conventional Commits*.
  - Suite de pruebas completa: Unit tests, Widget tests, Golden tests visuales y Stress benchmarks de memoria.
  - README profesional con badges de cobertura, capturas Stitch y diagramas de arquitectura.

---

## 3. Principios Innegociables de Ingeniería

1. **Cero I/O en el Hilo Principal:** Toda descompresión de archivos (ZIP, RAR), hashing de huella digital y parsing de `ComicInfo.xml` debe ejecutarse estrictamente mediante `Isolate.run`.
2. **Control Estricto de Memoria (Anti-OOM):** Prohibido decodificar imágenes completas de 50MB en RAM sin redimensionamiento. Se impone el uso de `ResizeImage` limitado a 2x el ancho de pantalla y una ventana de retención máxima de 5 páginas en memoria activa.
3. **Fidelidad Neobrutalista Stitch 1:1:** Prohibido usar estilos genéricos de Material Design o sombras desenfocadas. Se aplican sombras duras (`Offset(2.5, 2.5)` sin blur), bordes de tinta de 2px, paleta Papel/Tinta/Terracota y tipografías *Space Grotesk*, *JetBrains Mono* y *Work Sans*.
4. **Flujo Unidireccional Reactivo:** La interfaz de usuario (Views) solo observa estados inmutables expuestos por ViewModels (`Notifier` de Riverpod) y despacha intenciones de usuario. Las vistas nunca interactúan con la base de datos o el sistema de archivos directamente.
5. **Edge AI Local y Seguro:** La integración de OCR y asistencia de lectura debe operar de forma 100% local en el dispositivo a través de Google ML Kit, garantizando latencia ultra baja y funcionamiento sin conexión a internet.
