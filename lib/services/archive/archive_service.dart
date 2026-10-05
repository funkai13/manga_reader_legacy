import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:rar/rar.dart';

import 'comic_info_parser.dart';

const comicPageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
const thumbnailFolderName = 'thumb';
const _thumbnailWidth = 400;

bool isComicPageName(String name) {
  final normalized = name.replaceAll('\\', '/');
  final base = p.posix.basename(normalized);
  if (normalized.contains('__MACOSX/') || base.startsWith('.')) return false;
  return comicPageExtensions.contains(p.posix.extension(base).toLowerCase());
}

enum ArchiveKind { zip, rar, rar5, unknown }

ArchiveKind detectArchiveKind(String path) {
  final raf = File(path).openSync();
  try {
    final h = raf.readSync(8);
    if (h.length >= 4 && h[0] == 0x50 && h[1] == 0x4B) {
      if ((h[2] == 0x03 && h[3] == 0x04) || (h[2] == 0x05 && h[3] == 0x06)) {
        return ArchiveKind.zip;
      }
    }
    const rar = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07];
    if (h.length >= 7 && List.generate(6, (i) => h[i] == rar[i]).every((b) => b)) {
      return h[6] == 0x01 ? ArchiveKind.rar5 : ArchiveKind.rar;
    }
    return ArchiveKind.unknown;
  } finally {
    raf.closeSync();
  }
}

class ExtractedArchive {
  final List<String> pages;
  final String? coverPath;
  final ComicInfoData? info;
  final String? contentHash;
  final int fileSize;

  const ExtractedArchive({
    required this.pages,
    this.coverPath,
    this.info,
    this.contentHash,
    this.fileSize = 0,
  });
}

class ArchiveException implements Exception {
  final String message;
  const ArchiveException(this.message);

  @override
  String toString() => message;
}

class ArchiveService {
  const ArchiveService();

  /// Calculates a fast SHA-1 content fingerprint of [archivePath] using size + head + tail.
  Future<String> calculateFingerprint(String archivePath, {int chunkSize = 64 * 1024}) async {
    return Isolate.run(() {
      final raf = File(archivePath).openSync();
      try {
        final length = raf.lengthSync();
        final header = ByteData(8)..setUint64(0, length);
        final builder = BytesBuilder(copy: false)..add(header.buffer.asUint8List());

        final headLength = length < chunkSize ? length : chunkSize;
        builder.add(raf.readSync(headLength));

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

  /// Extracts the comic archive (CBZ/CBR) into [outputDir].
  Future<ExtractedArchive> extract(String archivePath, String outputDir) async {
    final file = File(archivePath);
    if (!await file.exists()) {
      throw const ArchiveException('No se encontró el archivo del cómic.');
    }

    final fileSize = await file.length();
    final contentHash = await calculateFingerprint(archivePath);
    final kind = await Isolate.run(() => detectArchiveKind(archivePath));

    switch (kind) {
      case ArchiveKind.zip:
        return Isolate.run(() => _extractZip(archivePath, outputDir, contentHash, fileSize));
      case ArchiveKind.rar:
      case ArchiveKind.rar5:
        return _extractRar(archivePath, outputDir, contentHash, fileSize);
      case ArchiveKind.unknown:
        throw const ArchiveException('El archivo no es un CBZ/CBR válido o está dañado.');
    }
  }

  Future<ExtractedArchive> _extractRar(
    String archivePath,
    String outputDir,
    String contentHash,
    int fileSize,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp('comic_rar_');
    try {
      bool extracted;
      try {
        final result = await Rar.extractRarFile(
          rarFilePath: archivePath,
          destinationPath: tempDir.path,
        );
        extracted = result['success'] == true;
      } catch (_) {
        extracted = false;
      }
      if (!extracted) {
        throw const ArchiveException(
          'No se pudo extraer el archivo CBR. El archivo puede estar corrupto o protegido.',
        );
      }
      final source = tempDir.path;
      return await Isolate.run(
        () => _collectFromDirectory(source, outputDir, contentHash, fileSize),
      );
    } finally {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    }
  }
}

ExtractedArchive _extractZip(
  String archivePath,
  String outputDir,
  String contentHash,
  int fileSize,
) {
  final input = InputFileStream(archivePath);
  try {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (_) {
      throw const ArchiveException('No se pudo leer el archivo CBZ. El archivo puede estar corrupto.');
    }

    ComicInfoData? info;
    final pages = <ArchiveFile>[];
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final base = p.posix.basename(entry.name).toLowerCase();
      if (base == 'comicinfo.xml') {
        info = ComicInfoData.parse(utf8.decode(entry.content, allowMalformed: true));
      } else if (isComicPageName(entry.name)) {
        pages.add(entry);
      }
    }

    if (pages.isEmpty) {
      throw ArchiveException(
        'El archivo no contiene imágenes soportadas (${comicPageExtensions.join(', ')}).',
      );
    }

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
        throw const ArchiveException('No se pudo escribir una página del cómic.');
      } finally {
        output.closeSync();
      }
      written.add(dest);
    }

    final coverPath = _createThumbnail(written.first, outputDir) ?? written.first;

    return ExtractedArchive(
      pages: written,
      coverPath: coverPath,
      info: info,
      contentHash: contentHash,
      fileSize: fileSize,
    );
  } finally {
    input.closeSync();
  }
}

ExtractedArchive _collectFromDirectory(
  String sourceDir,
  String outputDir,
  String contentHash,
  int fileSize,
) {
  ComicInfoData? info;
  final pages = <String, List<Object>>{};
  for (final entity in Directory(sourceDir).listSync(recursive: true)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: sourceDir);
    final base = p.basename(relative).toLowerCase();
    if (base == 'comicinfo.xml') {
      info = ComicInfoData.parse(entity.readAsStringSync());
    } else if (isComicPageName(relative)) {
      pages[relative] = _naturalKey(relative);
    }
  }

  if (pages.isEmpty) {
    throw ArchiveException(
      'El archivo no contiene imágenes soportadas (${comicPageExtensions.join(', ')}).',
    );
  }

  final ordered = pages.keys.toList()..sort((a, b) => _compareNatural(pages[a]!, pages[b]!));

  Directory(outputDir).createSync(recursive: true);
  final written = <String>[];
  for (var i = 0; i < ordered.length; i++) {
    final src = File(p.join(sourceDir, ordered[i]));
    final dest = p.join(outputDir, _pageName(i, ordered[i]));
    try {
      src.renameSync(dest);
    } on FileSystemException {
      src.copySync(dest);
    }
    written.add(dest);
  }

  final coverPath = _createThumbnail(written.first, outputDir) ?? written.first;

  return ExtractedArchive(
    pages: written,
    coverPath: coverPath,
    info: info,
    contentHash: contentHash,
    fileSize: fileSize,
  );
}

String _pageName(int index, String originalName) =>
    '${(index + 1).toString().padLeft(4, '0')}${p.extension(originalName).toLowerCase()}';

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

List<Object> _naturalKey(String name) => [
      for (final m in _naturalChunks.allMatches(name.replaceAll('\\', '/').toLowerCase()))
        int.tryParse(m[0]!) ?? m[0]!,
    ];

int _compareNatural(List<Object> a, List<Object> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    final x = a[i], y = b[i];
    final diff = x is int && y is int ? x.compareTo(y) : x.toString().compareTo(y.toString());
    if (diff != 0) return diff;
  }
  return a.length.compareTo(b.length);
}
