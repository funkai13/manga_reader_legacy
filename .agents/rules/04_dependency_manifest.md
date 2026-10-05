---
description: Inventario de dependencias oficiales de producci�n y desarrollo (Riverpod 3, go_router, sqflite, etc.) y paquetes vetados.
trigger: model_decision
---
# MANIFIESTO DE DEPENDENCIAS: TINTA & PAPEL

> **Inventario curado de paquetes oficiales, justificación técnica y compatibilidad.**

---

## 1. Dependencias de Producción (`dependencies`)

### A. Gestión de Estado & Arquitectura
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`flutter_riverpod`** | `^3.0.3` | Estado reactivo, desacoplamiento de UI, Notifiers inmutables y sin `BuildContext`. |
| **`riverpod_annotation`** | `^3.0.3` | Generación de proveedores tipados y compatibilidad de tooling. |

### B. Enrutamiento Declarativo
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`go_router`** | `^14.8.1` | Navegación declarativa por URLs. Uso obligatorio de `StatefulShellRoute.indexedStack` para mantener el estado de memoria del Dock Neobrutalista de 4 pestañas. Soporta deep linking (`/reader/:id?page=X`). |

### C. Internacionalización Oficial (i18n)
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`flutter_localizations`** | *SDK* | Librería oficial de Flutter para delegados de localización en iOS y Android. |
| **`intl`** | `^0.20.2` | Formateo de fechas, números, plurales y generación tipada desde archivos `.arb` (`app_es.arb`, `app_en.arb`). |

### D. Persistencia & Base de Datos Semántica / Vectorial
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`sqflite`** | `^2.4.1` | Motor SQLite nativo offline-first con soporte para tablas FTS5 (búsqueda por texto completo) y vectores de embedding en columnas `BLOB`. |
| **`path_provider`** | `^2.1.5` | Localización segura de sandboxes del sistema operativo (`getApplicationDocumentsDirectory`, `systemTemp`). |
| **`path`** | `^1.9.0` | Normalización y manipulación de rutas relativas multiplataforma. |

### E. Motor de Extracción e Isolates
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`archive`** | `^4.0.5` | Descompresión en streaming para archivos `.cbz` y `.zip` mediante `ZipDecoder().decodeStream` en background isolates. |
| **`rar`** | `^0.3.0` | Soporte FFI nativo para archivos `.cbr` (formatos RAR4 y RAR5). |
| **`xml`** | `^6.5.0` | Parser puro de `ComicInfo.xml` para catalogación automática sin dependencias nativas. |
| **`crypto`** | `^3.0.7` | Fingerprinting SHA-1 ultra rápido (<10ms) de cabecera y cola para detección de duplicados. |
| **`image`** | `^4.10.1` | Generación de miniaturas `thumb/cover.jpg` (400px ancho) en segundo plano para evitar OOM. |

### F. UI Neobrutalista Stitch & Háptica
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`google_fonts`** | `^8.2.1` | Fuentes oficiales Stitch: **Space Grotesk** (titulares), **JetBrains Mono** (datos técnicos) y **Work Sans** (cuerpo). |
| **`vibration`** | `^3.1.3` | Feedback háptico mecánico al deprimir botones Neobrutalistas (+2px) y topes de página. |
| **`file_picker`** | `^10.1.2` | Selector nativo de archivos para importar cómics desde almacenamiento local o tarjeta SD. |
| **`cupertino_icons`** | `^1.0.8` | Glifos complementarios de alta resolución. |

### G. Red & APIs de Metadatos Públicas
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`http`** | `^1.2.2` | Cliente HTTP oficial de Dart para consultar APIs públicas de metadatos (Jikan / MyAnimeList y MangaDex) sin API key. |

### H. Edge AI & Inteligencia Artificial Local (On-Device)
| Paquete | Versión | Rol Arquitectónico y Justificación |
| :--- | :--- | :--- |
| **`google_mlkit_text_recognition`** | `^0.14.0` | Motor local oficial de Google para OCR en viñetas y globos de diálogo sin internet. |
| **`google_mlkit_translation`** | `^0.13.0` | Modelos locales descargables para traducción instantánea de burbujas en el visor. |

---

## 2. Dependencias de Desarrollo (`dev_dependencies`)

| Paquete | Versión | Rol |
| :--- | :--- | :--- |
| **`flutter_test`** | *SDK* | Suite base de testing de widgets y golden tests. |
| **`flutter_lints`** | `^6.0.0` | Reglas de estilo y calidad de código de Flutter. |
| **`mocktail`** | `^1.0.5` | Mocking moderno y tipado sin necesidad de `build_runner`. |
| **`sqflite_common_ffi`** | `^2.4.3` | SQLite en memoria para tests unitarios instantáneos en la máquina de desarrollo. |
| **`fake_async`** | `^1.3.3` | Simulación determinista del tiempo en tests de gestos y temporizadores. |
| **`riverpod_generator`** | `^3.0.3` | Generador de código oficial para `@riverpod`, eliminando boilerplate y asegurando auto-dispose. |
| **`build_runner`** | `^2.4.13` | Runner de compilación para la generación de archivos `*.g.dart`. |
| **`riverpod_lint`** | `^3.0.3` | Reglas de análisis estático especializadas para evitar errores de Riverpod en tiempo real. |
| **`custom_lint`** | `^0.8.0` | Motor de análisis de lints personalizados para el compilador de Dart. |

---

## 3. Paquetes Vetados (Prohibidos)

1. **APIs Cloud de OCR de Pago:** Queda vetado integrar servicios como Google Cloud Vision REST API o AWS Rekognition para tareas de lectura estándar. Toda inferencia de OCR debe ser local vía Google ML Kit para proteger la privacidad del usuario y permitir funcionamiento 100% offline.
2. **Librerías de Animaciones Pesadas o Incompatibles:** Prohibido el uso de paquetes que capturen el hilo de UI o dependan de webviews para renderizar controles básicos.
3. **State Management Redundante:** Prohibido mezclar `Provider` clásico, `GetX` o `Bloc`. El único gestor de estado oficial y permitido es **Riverpod 3**.
