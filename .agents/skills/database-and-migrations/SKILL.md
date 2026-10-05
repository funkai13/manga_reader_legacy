---
name: database-and-migrations
description: >-
  Guía completa para el esquema SQLite AI-Ready, control de versiones de migraciones (onUpgrade), tablas virtuales FTS5, almacenamiento de embeddings vectoriales BLOB, clases VectorMath en Isolate y tracking de sesiones de lectura y rachas. Usar al modificar la base de datos local.
---

# SKILL: DATABASE & MIGRATIONS PLAYBOOK (SQLITE AI-READY)

> **Guía para la administración de esquemas SQLite, migraciones seguras, consultas indexadas y búsqueda semántica vectorial.**

---

## 1. Esquema DDL Completo (SQLite v5 AI-Ready)

```sql
-- 1. Tabla Maestra de Cómics con Campos Semánticos
CREATE TABLE comics (
  _id INTEGER PRIMARY KEY AUTOINCREMENT,
  filePath TEXT NOT NULL,
  title TEXT NOT NULL,
  picture TEXT,
  currentPage INTEGER DEFAULT 0,
  totalPages INTEGER DEFAULT 0,
  lastOpened TEXT,
  currentReading INTEGER DEFAULT 0,
  imagesPath TEXT NOT NULL,
  isReading INTEGER DEFAULT 0,
  isFavorite INTEGER DEFAULT 0,
  bookMarks TEXT DEFAULT '',
  rating INTEGER DEFAULT 0,
  isCompleted INTEGER DEFAULT 0,
  author TEXT,
  genre TEXT,
  collection TEXT,
  comicType TEXT,
  contentHash TEXT,
  summary TEXT,
  volume TEXT,
  fileSize INTEGER DEFAULT 0,
  
  -- Campos de Inteligencia Artificial Semántica
  aiSummary TEXT,              -- Resumen o sinopsis generada por IA
  aiKeyThemes TEXT,            -- Temas clave separados por coma ("viajes en el tiempo, psicológico")
  embedding BLOB               -- Vector Float32List (256/384 dimensiones) serializado en bytes
);

-- Índices de consulta rápida insensibles a mayúsculas/minúsculas
CREATE INDEX IF NOT EXISTS idx_comics_author ON comics (author COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_comics_genre ON comics (genre COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_comics_collection ON comics (collection COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_comics_filePath ON comics (filePath);
CREATE UNIQUE INDEX IF NOT EXISTS idx_comics_contentHash ON comics (contentHash);

-- 2. Tabla de Embeddings Granulares por Página/Escena (Para Búsqueda Semántica Precisa)
CREATE TABLE comic_embeddings (
  _id INTEGER PRIMARY KEY AUTOINCREMENT,
  comicId INTEGER NOT NULL,
  pageNumber INTEGER NOT NULL,
  chunkText TEXT NOT NULL,
  embedding BLOB NOT NULL,     -- Vector Float32List del diálogo o viñeta
  FOREIGN KEY (comicId) REFERENCES comics(_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_embeddings_comicId ON comic_embeddings (comicId);
CREATE INDEX IF NOT EXISTS idx_embeddings_comic_page ON comic_embeddings (comicId, pageNumber);

-- 3. Tabla de Recapitulaciones y Resúmenes de Lectura
CREATE TABLE comic_recaps (
  _id INTEGER PRIMARY KEY AUTOINCREMENT,
  comicId INTEGER NOT NULL,
  startPage INTEGER NOT NULL,
  endPage INTEGER NOT NULL,
  recapTitle TEXT NOT NULL,
  recapContent TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (comicId) REFERENCES comics(_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_recaps_comicId ON comic_recaps (comicId);

-- 4. Búsqueda Full-Text Search (FTS5) Nativa de SQLite
CREATE VIRTUAL TABLE IF NOT EXISTS comics_fts USING fts5(
  title,
  author,
  genre,
  summary,
  aiSummary,
  tokenize='unicode61 remove_diacritics 2'
);

-- 5. Sesiones de Lectura (Cálculo de Horas Leídas y Rachas Diarias)
CREATE TABLE reading_sessions (
  _id INTEGER PRIMARY KEY AUTOINCREMENT,
  comicId INTEGER NOT NULL,
  startTime TEXT NOT NULL,       -- ISO8601
  endTime TEXT NOT NULL,         -- ISO8601
  durationSeconds INTEGER NOT NULL,
  pagesRead INTEGER NOT NULL,
  FOREIGN KEY (comicId) REFERENCES comics(_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sessions_startTime ON reading_sessions (startTime);
CREATE INDEX IF NOT EXISTS idx_sessions_comicId ON reading_sessions (comicId);

-- 6. Insignias y Logros de Perfil Desbloqueados
CREATE TABLE user_achievements (
  id TEXT PRIMARY KEY,          -- ej. 'night_reader', 'streak_7_days'
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,           -- Emoji o glifo de sello Neobrutalista
  unlockedAt TEXT,              -- Fecha ISO8601 o NULL si está bloqueada
  isUnlocked INTEGER DEFAULT 0
);
```

---

## 2. Reglas de Evolución de Esquema (`onUpgrade`)

Toda modificación a la base de datos debe incrementar el `schemaVersion` y agregar un bloque condicional en `_upgradeDatabase`:

```dart
Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
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
    try {
      await db.execute('ALTER TABLE comics ADD COLUMN aiSummary TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE comics ADD COLUMN aiKeyThemes TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE comics ADD COLUMN embedding BLOB');
    } catch (_) {}
  }
}
```

---

## 3. Motor de Búsqueda Semántica en Isolate (Dart SIMD)

Los vectores se almacenan como `BLOB` (bytes crudos de `Float32List`). El cálculo de la **similitud coseno** se ejecuta en un `Isolate.run` sin dependencias externas:

```dart
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

class VectorMath {
  /// Calcula la similitud coseno entre dos vectores Float32List.
  static double cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      final valA = a[i];
      final valB = b[i];
      dot += valA * valB;
      normA += valA * valA;
      normB += valB * valB;
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Ejecuta la búsqueda de los K cómics más cercanos en un Isolate en segundo plano (<3ms).
  static Future<List<int>> findTopKMatches({
    required Float32List queryVector,
    required Map<int, Float32List> libraryVectors,
    int k = 10,
    double threshold = 0.65,
  }) async {
    return Isolate.run(() {
      final scored = <MapEntry<int, double>>[];
      for (final entry in libraryVectors.entries) {
        final score = cosineSimilarity(queryVector, entry.value);
        if (score >= threshold) {
          scored.add(MapEntry(entry.key, score));
        }
      }
      scored.sort((a, b) => b.value.compareTo(a.value));
      return scored.take(k).map((e) => e.key).toList();
    });
  }
}
```

---

## 4. Pruebas Unitarias de Base de Datos en Memoria (`sqflite_common_ffi`)

Para testear la base de datos sin necesidad de emuladores ni dispositivos físicos:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Debe insertar y recuperar un cómic con metadatos completos y tablas semánticas', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 5);
    // Ejecutar aserciones de tablas e inserciones...
    await db.close();
  });
}
```
