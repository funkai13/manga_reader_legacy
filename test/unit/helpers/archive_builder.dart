import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// Tiny image payloads (only the bytes/extension matter for these tests).
final Uint8List fakePng = Uint8List.fromList(
    [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0]);
final Uint8List fakeJpg =
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A, 0x46]);

/// Builds a ComicInfo.xml document (ComicRack schema).
String comicInfoXml({
  String? title,
  String? writer,
  String? genre,
  String? series,
  String? manga,
  int? pageCount,
}) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="utf-8"?>')
    ..writeln('<ComicInfo xmlns:xsd="http://www.w3.org/2001/XMLSchema" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
  if (title != null) b.writeln('  <Title>$title</Title>');
  if (series != null) b.writeln('  <Series>$series</Series>');
  if (writer != null) b.writeln('  <Writer>$writer</Writer>');
  if (genre != null) b.writeln('  <Genre>$genre</Genre>');
  if (pageCount != null) b.writeln('  <PageCount>$pageCount</PageCount>');
  if (manga != null) b.writeln('  <Manga>$manga</Manga>');
  b.writeln('</ComicInfo>');
  return b.toString();
}

/// Writes a zip archive with [entries] (name -> bytes or String) to
/// `dir/fileName`. A `null` value creates a directory entry.
File buildArchive(
  Directory dir,
  String fileName,
  Map<String, Object?> entries,
) {
  final archive = Archive();
  entries.forEach((name, content) {
    if (content == null) {
      final d = ArchiveFile.noData(name.endsWith('/') ? name : '$name/')
        ..isFile = false;
      archive.addFile(d);
    } else if (content is String) {
      archive.addFile(ArchiveFile.string(name, content));
    } else {
      archive.addFile(ArchiveFile.bytes(name, content as List<int>));
    }
  });
  final bytes = ZipEncoder().encodeBytes(archive);
  final file = File(p.join(dir.path, fileName));
  file.writeAsBytesSync(bytes);
  return file;
}

/// Writes arbitrary raw bytes to `dir/fileName`.
File writeRawFile(Directory dir, String fileName, List<int> bytes) {
  final file = File(p.join(dir.path, fileName));
  file.writeAsBytesSync(bytes);
  return file;
}

Directory createTempDir([String prefix = 'manga_reader_test_']) =>
    Directory.systemTemp.createTempSync(prefix);

void deleteQuietly(FileSystemEntity entity) {
  try {
    if (entity.existsSync()) entity.deleteSync(recursive: true);
  } catch (_) {}
}
