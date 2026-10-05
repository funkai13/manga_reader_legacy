import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/services/comic_archive_extractor.dart';
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';
import 'package:path/path.dart' as p;

import '../../../../helpers/archive_builder.dart';

void main() {
  late Directory sandbox;

  setUp(() => sandbox = createTempDir('extractor_'));
  tearDown(() => deleteQuietly(sandbox));

  group('detectArchiveKind', () {
    ArchiveKind kindOf(List<int> bytes) =>
        detectArchiveKind(writeRawFile(sandbox, 'f', bytes).path);

    test('ZIP by content, whatever the extension', () {
      final zip = buildArchive(sandbox, 'x.cbr', {'1.jpg': [1]});
      expect(detectArchiveKind(zip.path), ArchiveKind.zip);
      expect(kindOf([0x50, 0x4B, 0x05, 0x06, 0, 0, 0, 0]), ArchiveKind.zip);
    });

    test('RAR 4 and RAR 5 signatures', () {
      expect(kindOf([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00]), ArchiveKind.rar);
      expect(kindOf([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00]),
          ArchiveKind.rar5);
    });

    test('anything else is unknown', () {
      expect(kindOf([]), ArchiveKind.unknown);
      expect(kindOf([0x50, 0x4B]), ArchiveKind.unknown);
      expect(kindOf('%PDF-1.7'.codeUnits), ArchiveKind.unknown);
    });
  });

  group('isComicPageName', () {
    test('accepts supported image extensions in any case', () {
      for (final n in ['a.jpg', 'b.JPEG', 'c.png', 'd.webp', 'e.GIF', 'f.bmp']) {
        expect(isComicPageName(n), isTrue, reason: n);
      }
    });

    test('rejects other files, hidden files and macOS resource forks', () {
      for (final n in [
        'ComicInfo.xml',
        'notes.txt',
        '.hidden.jpg',
        'ch1/._001.jpg',
        '__MACOSX/ch1/001.jpg',
        r'__MACOSX\001.jpg',
      ]) {
        expect(isComicPageName(n), isFalse, reason: n);
      }
    });

    test('pages in sub-folders are accepted', () {
      expect(isComicPageName('ch1/001.jpg'), isTrue);
      expect(isComicPageName(p.join('ch1', '001.jpg')), isTrue);
    });
  });

  group('parseComicInfo', () {
    test('reads the fields used by the library', () {
      final info = parseComicInfo(comicInfoXml(
          title: 'Romance Dawn',
          series: 'One Piece',
          writer: 'Eiichiro Oda',
          genre: 'Shonen, Aventura',
          manga: 'YesAndRightToLeft'))!;
      expect(info.title, 'Romance Dawn');
      expect(info.series, 'One Piece');
      expect(info.writer, 'Eiichiro Oda');
      expect(info.genre, 'Shonen');
      expect(info.comicType, 'Manga');
    });

    test('Manga values map to the reading mode', () {
      String? type(String? manga) => parseComicInfo(comicInfoXml(manga: manga))!
          .comicType;
      expect(type('Yes'), 'Manga');
      expect(type('YesAndRightToLeft'), 'Manga');
      expect(type('No'), 'Comic');
      expect(type('Unknown'), isNull);
      expect(type(null), isNull);
    });

    test('blank fields are null and malformed XML returns null', () {
      final info = parseComicInfo(
          '<ComicInfo><Writer>  </Writer><Series></Series></ComicInfo>')!;
      expect(info.writer, isNull);
      expect(info.series, isNull);
      expect(parseComicInfo('<ComicInfo><Writer>Oda'), isNull);
    });
  });

  group('extract', () {
    test('nonexistent file throws UnsupportedComicException', () async {
      final ghostPath = p.join(sandbox.path, 'ghost.cbz');
      final outDir = p.join(sandbox.path, 'out_ghost');
      await expectLater(
        ComicArchiveExtractor().extract(ghostPath, outDir),
        throwsA(isA<UnsupportedComicException>().having(
          (e) => e.message,
          'message',
          contains('No se encontró el archivo del cómic'),
        )),
      );
    });

    test('unknown archive kind throws UnsupportedComicException', () async {
      final invalidFile = writeRawFile(sandbox, 'invalid.cbz', [1, 2, 3, 4, 5]);
      final outDir = p.join(sandbox.path, 'out_invalid');
      await expectLater(
        ComicArchiveExtractor().extract(invalidFile.path, outDir),
        throwsA(isA<UnsupportedComicException>().having(
          (e) => e.message,
          'message',
          contains('El archivo no es un CBZ/CBR válido o está corrupto'),
        )),
      );
    });

    test('zip archive without supported pages throws UnsupportedComicException',
        () async {
      final emptyZip = buildArchive(sandbox, 'empty.cbz', {
        'notes.txt': 'no images here',
        'sub/data.json': '{}',
      });
      final outDir = p.join(sandbox.path, 'out_empty');
      await expectLater(
        ComicArchiveExtractor().extract(emptyZip.path, outDir),
        throwsA(isA<UnsupportedComicException>().having(
          (e) => e.message,
          'message',
          contains('El archivo no contiene imágenes soportadas'),
        )),
      );
    });

    test('natural sort compares filenames with different segment lengths',
        () async {
      final zip = buildArchive(sandbox, 'lengths.cbz', {
        'page.jpg': fakeJpg,
        'page_extra.jpg': fakeJpg,
      });
      final outDir = p.join(sandbox.path, 'out_lengths');
      final result =
          await ComicArchiveExtractor().extract(zip.path, outDir);
      expect(result.pages.length, 2);
    });
  });
}
