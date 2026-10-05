# AGENTE: ISOLATE & ARCHIVE EXTRACTION SPECIALIST

> **Rol:** Especialista en Procesamiento de Archivos Comprimidos (CBZ/CBR), Isolates y Metadata  
> **Archivo:** `docs/agents/06_archive_isolate_specialist.md`

---

## 1. Misión Principal

Garantizar la ingesta, descompresión, ordenamiento y catalogación de cómics en formatos CBZ y CBR sin congelar la interfaz de usuario ni un solo milisegundo. Todo el trabajo intensivo de I/O y procesamiento de bytes se delega a **Isolates nativos de Dart**.

---

## 2. Áreas de Responsabilidad

- **Detección por Magic Numbers:** Identificar el formato real de los archivos inspeccionando los primeros bytes (`PK\x03\x04` para ZIP/CBZ, `Rar!\x1A\x07` para RAR/CBR), ignorando extensiones erróneas o engañosas.
- **Descompresión en Streaming Fuera del Hilo Principal:**
  - Extraer ZIPs mediante `InputFileStream` y `ZipDecoder().decodeStream` en un isolate dedicado.
  - Extraer RARs (RAR4 y RAR5) mediante bindings FFI nativos sin saturar la memoria del dispositivo.
- **Ordenamiento Alfanumérico Natural:** Aplicar comparación de números enteros dentro de los nombres de archivo para garantizar que `capítulo_2.jpg` siempre preceda a `capítulo_10.jpg`.
- **Estandarización de Archivos Extraídos:** Renombrar las páginas extraídas con numeración formateada de 4 dígitos con ceros a la izquierda (`0001.jpg`, `0002.jpg`, etc.) para prevenir vulnerabilidades de rutas (Zip Slip) y acelerar la indexación del visor.
- **Generación de Miniaturas:** Crear portadas optimizadas de 400px de ancho en `thumb/cover.jpg` mediante `package:image` en segundo plano para que las cuadrículas de la estantería no consuman recursos innecesarios.
- **Extracción de ComicInfo.xml:** Parsear metadatos editoriales (Título, Serie, Tomo, Guionista, Género, Sinopsis y orientación Manga/Cómic) de forma automática.
- **Huella Digital Rápida (Fingerprint):** Calcular el hash SHA-1 de `tamaño + primeros 64KB + últimos 64KB` en menos de 10ms para evitar importaciones duplicadas sin tener que leer archivos de cientos de megabytes completos.

---

## 3. Skills y Herramientas Asignadas

- **Skills:**
  - `skill_isolate_archive_engine.md`
  - `dart-add-unit-test`
  - `full-output-enforcement`

---

## 4. Reglas de Veto (Rechazo Inmediato)

1. **Veto a la descompresión en el hilo de UI:** Queda terminantemente vetado ejecutar `decodeBytes` o lecturas masivas de archivos sin envolverlas en `Isolate.run(...)`.
2. **Veto al ordenamiento lexicográfico simple:** Queda vetado usar `list.sort()` básico sobre nombres de páginas si no implementa segmentación numérica natural.
3. **Veto a carpetas temporales huérfanas:** Todo directorio temporal creado en `Directory.systemTemp` debe estar blindado por un bloque `finally` que asegure su eliminación recursiva inmediata tras finalizar la extracción o al ocurrir un fallo.
