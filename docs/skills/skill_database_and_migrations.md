# SKILL: DATABASE & MIGRATIONS PLAYBOOK

> **Guía para la administración de esquemas SQLite, migraciones seguras y consultas indexadas.**

---

## 1. Reglas de Evolución de Esquema (`onUpgrade`)

Toda modificación a la base de datos debe incrementar el `schemaVersion` y agregar un bloque condicional en `_upgradeDatabase`:

```dart
Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
  // Migración a versión 5: soporte de metadatos ComicInfo y tamaño
  if (oldVersion < 5) {
    try {
      await db.execute('ALTER TABLE comics ADD COLUMN summary TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE comics ADD COLUMN volume TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE comics ADD COLUMN fileSize INTEGER DEFAULT 0');
    } catch (_) {}
  }
}
```

---

## 2. Índices Insensibles a Mayúsculas/Minúsculas (`COLLATE NOCASE`)

Para asegurar que agrupaciones como `"Oda"`, `"oda"` y `"ODA"` se consoliden en una sola entrada sin escaneos lentos de tabla:

```sql
CREATE INDEX IF NOT EXISTS idx_comics_author ON comics (author COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_comics_genre ON comics (genre COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_comics_collection ON comics (collection COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_comics_filePath ON comics (filePath);
CREATE UNIQUE INDEX IF NOT EXISTS idx_comics_contentHash ON comics (contentHash);
```

---

## 3. Pruebas Unitarias de Base de Datos en Memoria (`sqflite_common_ffi`)

Para testear la base de datos sin necesidad de emuladores ni dispositivos físicos:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Debe insertar y recuperar un cómic con metadatos completos', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 5, onCreate: ...);
    // Ejecutar aserciones...
  });
}
```
