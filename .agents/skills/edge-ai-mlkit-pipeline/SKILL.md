---
name: edge-ai-mlkit-pipeline
description: >-
  Playbook de Inteligencia Artificial local en el dispositivo (On-Device), reconocimiento óptico de caracteres (OCR) con Google ML Kit, detección de viñetas, globos de diálogo y proyección de coordenadas en pantalla con zoom. Usar al trabajar con módulos de visión o IA local.
---

# SKILL: ON-DEVICE EDGE AI ML KIT PLAYBOOK

> **Guía para la implementación de reconocimiento óptico de caracteres (OCR) y traducción local con Google ML Kit.**

---

## 1. Configuración de Google ML Kit

Agregar la dependencia al `pubspec.yaml`:

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.14.0
```

### Inicialización y Ciclo de Vida del Recognizer
```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MLKitOCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<RecognizedText> processPage(String pageFilePath) async {
    final inputImage = InputImage.fromFilePath(pageFilePath);
    return await _textRecognizer.processImage(inputImage);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
```

---

## 2. Detección de Bloques de Diálogo y Bounding Boxes

Cada página procesada retorna una lista de `TextBlock` con sus rectángulos delimitadores (`boundingBox`):

```dart
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DetectedBubble {
  final String text;
  final Rect boundingBox;
  final List<String> lines;

  DetectedBubble({required this.text, required this.boundingBox, required this.lines});
}

List<DetectedBubble> extractSpeechBubbles(RecognizedText recognized) {
  final bubbles = <DetectedBubble>[];
  for (final block in recognized.blocks) {
    bubbles.add(
      DetectedBubble(
        text: block.text,
        boundingBox: block.boundingBox,
        lines: block.lines.map((l) => l.text).toList(),
      ),
    );
  }
  return bubbles;
}
```

---

## 3. Mapeo de Coordenadas de Viñeta a Pantalla

Cuando el usuario hace zoom con `InteractiveViewer`, las coordenadas del bitmap original deben proyectarse a las coordenadas físicas de la pantalla:

```dart
Rect mapImageRectToScreen({
  required Rect imageRect,
  required Size originalImageSize,
  required Size renderedSize,
}) {
  final scaleX = renderedSize.width / originalImageSize.width;
  final scaleY = renderedSize.height / originalImageSize.height;

  return Rect.fromLTRB(
    imageRect.left * scaleX,
    imageRect.top * scaleY,
    imageRect.right * scaleX,
    imageRect.bottom * scaleY,
  );
}
```

Al tocar una viñeta, se resalta con un borde de tinta `NeoColors.terracotta` y se despliega una tarjeta Neobrutalista flotante con el texto reconocido.
