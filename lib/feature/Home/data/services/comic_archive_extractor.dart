import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:image/image.dart' as img;
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:rar/rar.dart';
import 'package:xml/xml.dart';

/// Extensions accepted as comic pages, shared with the viewer.
const comicPageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};

/// Sub-folder of a comic's folder that holds the cover thumbnail, so the
/// viewer (which lists only the top level) never shows it as a page.
const thumbnailFolderName = 'thumb';

const _thumbnailWidth = 400;

bool isComicPageName(String name) {
  final normalized = name.replaceAll('\\', '/');
  final base = p.posix.basename(normalized);
  // macOS resource forks (__MACOSX/, ._0001.jpg) and hidden files.
  if (normalized.contains('__MACOSX/') || base.startsWith('.')) return false;
  return comicPageExtensions.contains(p.posix.extension(base).toLowerCase());
}

enum ArchiveKind { zip, rar, rar5, unknown }

/// Detects the container by its magic number: many `.cbr` files are really
/// ZIPs and vice versa, so the extension alone is not reliable.
ArchiveKind detectArchiveKind(String path) {
  final raf = File(path).openSync();
  try {
    final h = raf.readSync(8);
    if (h.length >= 4 && h[0] == 0x50 && h[1] == 0x4B) {
      // PK\x03\x04 (local file) or PK\x05\x06 (empty archive).
      if ((h[2] == 0x03 && h[3] == 0x04) || (h[2] == 0x05 && h[3] == 0x06)) {
        return ArchiveKind.zip;
      }
    }
    const rar = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07]; // Rar!\x1A\x07
    if (h.length >= 7 && List.generate(6, (i) => h[i] == rar[i]).every((b) => b)) {
      return h[6] == 0x01 ? ArchiveKind.rar5 : ArchiveKind.rar;
    }
    return ArchiveKind.unknown;
  } finally {
    raf.closeSync();
  }
}

/// Metadata read from a ComicInfo.xml (ComicRack schema).
class ComicInfoData {
  final String? title;
  final String? series;
  final String? writer;
  final String? genre;

  /// 'Manga', 'Comic' or null when the file doesn't say.
  final String? comicType;

  const ComicInfoData({
    this.title,
    this.series,
    this.writer,
    this.genre,
    this.comicType,
  });
}

ComicInfoData? parseComicInfo(String xml) {
  try {
    final doc = XmlDocument.parse(xml);
    String? field(String name) {
      final text = doc.findAllElements(name).firstOrNull?.innerText.trim();
      return text == null || text.isEmpty ? null : text;
    }

    final manga = field('Manga')?.toLowerCase();
    return ComicInfoData(
      title: field('Title'),
      series: field('Series'),
      writer: field('Writer'),
      // Genre is a comma separated list; the library groups by a single one.
      genre: field('Genre')?.split(',').first.trim(),
      comicType: switch (manga) {
        'yes' || 'yesandrighttoleft' => 'Manga',
        'no' => 'Comic',
        _ => null,
      },
    );
  } on XmlException {
    return null;
  }
}

class ExtractedComic {
  /// Absolute page paths in reading order (0001.ext, 0002.ext, ...).
  final List<String> pages;

  /// Absolute path of the cover thumbnail, or null if it couldn't be made.
  final String? thumbnail;
  final ComicInfoData? info;

  const ExtractedComic({required this.pages, this.thumbnail, this.info});
}

/// Extracts a CBZ/CBR into [outputDir] without loading the whole archive in
/// memory, off the UI isolate. Pages are renamed to zero-padded indexes, so
/// entry names never decide where files are written (no zip-slip).
class ComicArchiveExtractor {
  const ComicArchiveExtractor();

  Future<ExtractedComic> extract(String archivePath, String outputDir) async {
    if (!await File(archivePath).exists()) {
      throw UnsupportedComicException('No se encontró el archivo del cómic.');
    }

    final kind = await Isolate.run(() => detectArchiveKind(archivePath));
    switch (kind) {
      case ArchiveKind.zip:
        return Isolate.run(() => _extractZip(archivePath, outputDir));
      case ArchiveKind.rar:
      case ArchiveKind.rar5:
        return _extractRar(archivePath, outputDir);
      case ArchiveKind.unknown:
        throw UnsupportedComicException(
          'El archivo no es un CBZ/CBR válido o está corrupto.',
        );
    }
  }

  Future<ExtractedComic> _extractRar(String archivePath, String outputDir) async {
    final tempDir = await Directory.systemTemp.createTemp('comic_rar_');
    try {
      // package:rar handles RAR4 and RAR5 (libarchive via FFI on Android,
      // UnrarKit on iOS) and already runs off the UI isolate.
      bool extracted;
      try {
        final result = await Rar.extractRarFile(
          rarFilePath: archivePath,
          destinationPath: tempDir.path,
        );
        extracted = result['success'] == true;
      } catch (_) {
        extracted = false; // e.g. no native implementation on this platform
      }
      if (!extracted) {
        throw UnsupportedComicException(
          'No se pudo extraer el archivo CBR. El archivo puede estar corrupto '
          'o protegido con contraseña.',
        );
      }
      final source = tempDir.path;
      return await Isolate.run(() => _collectFromDirectory(source, outputDir));
    } finally {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    }
  }
}

ExtractedComic _extractZip(String archivePath, String outputDir) {
  final input = InputFileStream(archivePath);
  try {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (_) {
      throw UnsupportedComicException(
        'No se pudo leer el archivo CBZ. El archivo puede estar corrupto.',
      );
    }

    ComicInfoData? info;
    final pages = <ArchiveFile>[];
    for (final entry in archive) {
      if (!entry.isFile) continue;
      if (p.posix.basename(entry.name).toLowerCase() == 'comicinfo.xml') {
        info = parseComicInfo(utf8.decode(entry.content, allowMalformed: true));
      } else if (isComicPageName(entry.name)) {
        pages.add(entry);
      }
    }
    _ensureHasPages(pages.length);

    final keys = {for (final e in pages) e: _naturalKey(e.name)};
    pages.sort((a, b) => _compareNatural(keys[a]!, keys[b]!));

    Directory(outputDir).createSync(recursive: true);
    final written = <String>[];
    for (var i = 0; i < pages.length; i++) {
      final dest = p.join(outputDir, _pageName(i, pages[i].name));
      final output = OutputFileStream(dest);
      try {
        pages[i].writeContent(output);
      } catch (_) {
        throw UnsupportedComicException(
          'No se pudo leer el archivo CBZ. El archivo puede estar corrupto.',
        );
      } finally {
        output.closeSync();
      }
      written.add(dest);
    }

    return ExtractedComic(
      pages: written,
      thumbnail: _createThumbnail(written.first, outputDir),
      info: info,
    );
  } finally {
    input.closeSync();
  }
}

ExtractedComic _collectFromDirectory(String sourceDir, String outputDir) {
  ComicInfoData? info;
  final pages = <String, List<Object>>{}; // relative path -> natural key
  for (final entity in Directory(sourceDir).listSync(recursive: true)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: sourceDir);
    if (p.basename(relative).toLowerCase() == 'comicinfo.xml') {
      info = parseComicInfo(entity.readAsStringSync());
    } else if (isComicPageName(relative)) {
      pages[relative] = _naturalKey(relative);
    }
  }
  _ensureHasPages(pages.length);

  // Sort by the full relative path so chapter sub-folders keep their order
  // and cap1/001.jpg and cap2/001.jpg don't collide.
  final ordered = pages.keys.toList()
    ..sort((a, b) => _compareNatural(pages[a]!, pages[b]!));

  Directory(outputDir).createSync(recursive: true);
  final written = <String>[];
  for (var i = 0; i < ordered.length; i++) {
    final src = File(p.join(sourceDir, ordered[i]));
    final dest = p.join(outputDir, _pageName(i, ordered[i]));
    try {
      src.renameSync(dest);
    } on FileSystemException {
      // Rename fails across file systems (system temp vs app documents).
      src.copySync(dest);
    }
    written.add(dest);
  }

  return ExtractedComic(
    pages: written,
    thumbnail: _createThumbnail(written.first, outputDir),
    info: info,
  );
}

void _ensureHasPages(int count) {
  if (count == 0) {
    throw UnsupportedComicException(
      'El archivo no contiene imágenes soportadas '
      '(${comicPageExtensions.join(', ')}).',
    );
  }
}

String _pageName(int index, String originalName) =>
    '${(index + 1).toString().padLeft(4, '0')}'
    '${p.extension(originalName).toLowerCase()}';

/// Writes a small JPEG cover so grids don't decode full-size pages.
/// Returns null (and the caller falls back to the first page) on failure.
String? _createThumbnail(String firstPage, String outputDir) {
  try {
    final decoded = img.decodeImage(File(firstPage).readAsBytesSync());
    if (decoded == null) return null;
    final resized = decoded.width > _thumbnailWidth
        ? img.copyResize(decoded, width: _thumbnailWidth)
        : decoded;
    final dest = p.join(outputDir, thumbnailFolderName, 'cover.jpg');
    File(dest)
      ..createSync(recursive: true)
      ..writeAsBytesSync(img.encodeJpg(resized, quality: 80));
    return dest;
  } catch (_) {
    return null;
  }
}

final _naturalChunks = RegExp(r'\d+|\D+');

/// Case-insensitive natural sort key: "Page10" sorts after "page2".
List<Object> _naturalKey(String name) => [
      for (final m in _naturalChunks.allMatches(
          name.replaceAll('\\', '/').toLowerCase()))
        int.tryParse(m[0]!) ?? m[0]!,
    ];

int _compareNatural(List<Object> a, List<Object> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    final x = a[i], y = b[i];
    final diff = x is int && y is int
        ? x.compareTo(y)
        : x.toString().compareTo(y.toString());
    if (diff != 0) return diff;
  }
  return a.length.compareTo(b.length);
}
