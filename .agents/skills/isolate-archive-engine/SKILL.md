---
name: isolate-archive-engine
description: Gu�a para la extracci�n de archivos CBZ/CBR, ordenamiento natural y hashing de alto rendimiento.
---
# SKILL: ISOLATE ARCHIVE ENGINE PLAYBOOK

> **Guía para la extracción de archivos CBZ/CBR, ordenamiento natural y hashing de alto rendimiento.**

---

## 1. Detección Confiable por Magic Bytes

Muchos archivos `.cbr` en realidad son archivos ZIP renombrados o viceversa. El extractor nunca se fía de la extensión:

```dart
enum ArchiveKind { zip, rar, rar5, unknown }

ArchiveKind detectArchiveKind(String path) {
  final raf = File(path).openSync();
  try {
    final h = raf.readSync(8);
    // Firma ZIP: PK\x03\x04
    if (h.length >= 4 && h[0] == 0x50 && h[1] == 0x4B) {
      if ((h[2] == 0x03 && h[3] == 0x04) || (h[2] == 0x05 && h[3] == 0x06)) {
        return ArchiveKind.zip;
      }
    }
    // Firma RAR: Rar!\x1A\x07
    const rar = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07];
    if (h.length >= 7 && List.generate(6, (i) => h[i] == rar[i]).every((b) => b)) {
      return h[6] == 0x01 ? ArchiveKind.rar5 : ArchiveKind.rar;
    }
    return ArchiveKind.unknown;
  } finally {
    raf.closeSync();
  }
}
```

---

## 2. Ordenamiento Alfanumérico Natural

Evita el clásico bug donde `página_10.jpg` aparece antes que `página_2.jpg`:

```dart
final _naturalChunks = RegExp(r'\d+|\D+');

List<Object> _naturalKey(String name) => [
  for (final m in _naturalChunks.allMatches(name.replaceAll('\\', '/').toLowerCase()))
    int.tryParse(m[0]!) ?? m[0]!,
];

int compareNatural(List<Object> a, List<Object> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    final x = a[i], y = b[i];
    final diff = x is int && y is int ? x.compareTo(y) : x.toString().compareTo(y.toString());
    if (diff != 0) return diff;
  }
  return a.length.compareTo(b.length);
}
```

---

## 3. Huella Digital Instantánea (<10ms)

Calcula un hash único del archivo sin tener que leer archivos pesados de 200MB completos:

```dart
Future<String> calculateFingerprint(String path, {int chunkSize = 64 * 1024}) async {
  return Isolate.run(() {
    final raf = File(path).openSync();
    try {
      final length = raf.lengthSync();
      final header = ByteData(8)..setUint64(0, length);
      final builder = BytesBuilder(copy: false)..add(header.buffer.asUint8List());

      // Primeros 64KB (Cabecera del contenedor)
      final headLength = length < chunkSize ? length : chunkSize;
      builder.add(raf.readSync(headLength));

      // Últimos 64KB (Directorio central de ZIP / trailers de RAR)
      final tailStart = length - chunkSize;
      if (tailStart > headLength) {
        raf.setPositionSync(tailStart);
      } else {
        raf.setPositionSync(headLength);
      }
      builder.add(raf.readSync(chunkSize));

      return sha1.convert(builder.takeBytes()).toString();
    } finally {
      raf.closeSync();
    }
  });
}
```
