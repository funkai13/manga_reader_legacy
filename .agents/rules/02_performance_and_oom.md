---
description: Reglas de rendimiento innegociables y prevenci�n de OOM para el motor de lectura (ResizeImage a 1400px, evictFarPages, 60 FPS fijos).
trigger: always_on
---
# REGLAS DE RENDIMIENTO & PREVENCIÓN DE OOM: TINTA & PAPEL

> **Guía maestra de optimización de memoria gráfica, isolates y 60 FPS estables.**

---

## 1. El Problema Crítico del OOM en Lectores de Manga/Cómics

Un archivo `.cbz` o `.cbr` típico contiene escaneos de alta resolución (por ejemplo, 3840 x 5760 píxeles a 32 bits por píxel RGBA).
- **En disco (comprimido):** ~1.5 MB por página (JPEG o WebP).
- **En memoria RAM (descomprimido en textura gráfica):**
  $$\text{RAM} = 3840 \times 5760 \times 4 \text{ bytes} \approx 88.47 \text{ MB por página}$$
- **El colapso:** Si el lector mantiene solo 5 páginas en memoria sin redimensionar, la app consume **más de 440 MB de RAM solo en texturas de imagen**, provocando el cierre fulminante del sistema operativo por **Out-Of-Memory (OOM)**, especialmente en dispositivos de gama media y tablets como la Samsung Galaxy Tab.

---

## 2. Los 4 Pilares Innegociables de Rendimiento

### Pilar 1: Decodificación Acotada con `ResizeImage`
Ninguna página del visor se decodifica a su resolución nativa cruda en pantalla completa.
- **Fórmula de decodificación objetivo:**
  ```dart
  int readerTargetDecodeWidth(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Doble del ancho físico en píxeles de pantalla: nitidez retina absoluta al hacer zoom
    return (media.width * pixelRatio * 1.5).round();
  }
  ```
- **Implementación obligatoria en el visor:**
  ```dart
  Image(
    image: ResizeImage(
      FileImage(File(pagePath)),
      width: targetDecodeWidth,
      policy: ResizeImagePolicy.fit,
    ),
    fit: BoxFit.contain,
  )
  ```
- **Resultado:** El consumo en RAM por página pasa de **88.5 MB a ~7.2 MB** (ahorro del 91.8% de memoria).

---

### Pilar 2: Evicción Activa de Caché (`evictFarPages`)
El motor del visor mantiene una política estricta de **ventana deslizante**:
- **Radio de lectura activo:** `[Página Actual - 2]` a `[Página Actual + 2]`.
- **Radio de evicción:** Cualquier página fuera de `|Página - Actual| > 4` es expulsada activamente de la caché de Flutter:
  ```dart
  void evictFarPages(List<File> pages, int currentPage, {int safeRadius = 4}) {
    for (var i = 0; i < pages.length; i++) {
      if ((i - currentPage).abs() > safeRadius) {
        FileImage(pages[i]).evict();
      }
    }
  }
  ```
- **Precarga inteligente:** Se precargan con `precacheImage` únicamente las páginas `currentPage + 1` y `currentPage - 1` para asegurar transiciones a 60 FPS sin jank.

---

### Pilar 3: Aislamiento Total de I/O en `Isolate.run`
La descompresión de archivos de 200 MB, el cálculo de huellas digitales SHA-1 y el ordenamiento alfanumérico se ejecutan **fuera del hilo de UI**.
- **Prohibido:** Decodificar archivos ZIP o RAR en el hilo principal (`main isolate`).
- **Garantía:** Cero caídas de cuadros (*zero frame drops*) mientras se importa un cómic.
- **Limpieza de temporales:** Todo directorio intermedio en el almacenamiento temporal del sistema debe eliminarse en un bloque `finally`:
  ```dart
  final tempDir = await Directory.systemTemp.createTemp('comic_rar_');
  try {
    // Extracción en background...
  } finally {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  }
  ```

---

### Pilar 4: Ordenamiento Alfanumérico Natural
Los cómics con numeración sin ceros a la izquierda (`page_1.jpg`, `page_2.jpg`, `page_10.jpg`) nunca deben ordenarse por orden lexicográfico ASCII simple (que colocaría `page_10` antes que `page_2`).
- **Regla:** Implementar el extractor con segmentación natural de chunks numéricos (`\d+|\D+`), comparando enteros contra enteros y texto contra texto.
- **Resultado:** La secuencia de lectura siempre es fidedigna y libre de saltos de viñeta.
