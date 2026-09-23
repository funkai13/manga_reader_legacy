import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
import 'package:image/image.dart' as img;
import 'package:manga_reader/feature/Home/data/models/comic_model.dart';
import 'package:manga_reader/feature/Home/data/repositories/comic_repository_impl.dart';
import 'package:manga_reader/feature/Home/data/services/comic_archive_extractor.dart';
import 'package:manga_reader/feature/Home/data/services/comic_storage.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../../helpers/archive_builder.dart';
import '../../../../helpers/comic_fixtures.dart';
import '../../../../helpers/db_stubs.dart';
import '../../../../helpers/fake_path_provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockComicDatabase db;
  late ComicRepositoryImpl repo;
  late Directory sandbox; // holds source archives
  late Directory appDocs; // fake getApplicationDocumentsDirectory()
  const newId = 42;

  const unrarChannel = MethodChannel('unrar_file');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    db = MockComicDatabase();
    sandbox = createTempDir('repo_src_');
    appDocs = createTempDir('repo_docs_');
    repo = ComicRepositoryImpl(db,
        storage: ComicStorage(documentsDirectory: () async => appDocs));
    PathProviderPlatform.instance = FakePathProviderPlatform(appDocs.path);

    when(() => db.getComicByTitle(any())).thenAnswer((_) async => null);
    when(() => db.addComic(any())).thenAnswer((_) async => newId);
    when(() => db.deleteComic(any())).thenAnswer((_) async {});
    stubUpdateComic(db);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(unrarChannel, null);
    deleteQuietly(sandbox);
    deleteQuietly(appDocs);
  });

  /// The comics root inside the fake documents directory.
  Directory comicsRoot() => Directory(p.join(appDocs.path, 'comics'));

  /// Folders left under comics/ (must be empty after a failed import).
  List<String> leftovers() => comicsRoot().existsSync()
      ? comicsRoot().listSync().map((e) => p.basename(e.path)).toList()
      : [];

  List<String> pageFiles(String folder) => Directory(folder)
      .listSync()
      .whereType<File>()
      .map((f) => p.basename(f.path))
      .toList()
    ..sort();

  List<int> firstBytesInOrder(String folder) => [
        for (final n in pageFiles(folder))
          File(p.join(folder, n)).readAsBytesSync().first
      ];

  ComicModel insertedModel() =>
      verify(() => db.addComic(captureAny())).captured.single as ComicModel;

  Future<ComicEntity> importFile(File file, {ComicEntity? comic}) =>
      repo.addComic(comic ??
          buildComicEntity(
              id: null, title: p.basename(file.path), filePath: file.path));

  group('addComic', () {
    test('returns the existing comic without inserting when title exists',
        () async {
      when(() => db.getComicByTitle('Dup.cbz')).thenAnswer((_) async =>
          buildComicModel(id: 5, title: 'Dup.cbz', totalPages: 12, author: 'A'));

      final result =
          await repo.addComic(buildComicEntity(id: null, title: 'Dup.cbz'));

      expect(result.id, 5);
      expect(result.totalPages, 12);
      expect(result.author, 'A');
      verifyNever(() => db.addComic(any()));
    });

    test('extracts first, then inserts once with relative paths', () async {
      final file = buildArchive(sandbox, 'naruto.cbz', {
        'page10.jpg': fakeJpg,
        'page2.png': fakePng,
        'page1.jpg': fakeJpg,
        'notes.txt': 'hello',
        'thumbs.db': [1, 2, 3],
      });

      final result = await importFile(file,
          comic: buildComicEntity(
              id: 99, title: 'naruto.cbz', filePath: file.path, author: 'Oda'));

      final folder = result.imagesPath;
      expect(p.isWithin(comicsRoot().path, folder), isTrue);
      // page1 -> 0001, page2 -> 0002 (png), page10 -> 0003
      expect(pageFiles(folder), ['0001.jpg', '0002.png', '0003.jpg']);
      expect(File(p.join(folder, '0002.png')).readAsBytesSync(), fakePng);
      // Fake bytes can't be decoded, so the cover falls back to page 1.
      expect(result.picture, p.join(folder, '0001.jpg'));
      expect(result.id, newId);
      expect(result.totalPages, 3);

      final inserted = insertedModel();
      expect(inserted.id, isNull);
      expect(inserted.title, 'naruto.cbz');
      expect(inserted.filePath, file.path);
      expect(inserted.author, 'Oda');
      expect(inserted.totalPages, 3);
      final relativeFolder = 'comics/${p.basename(folder)}';
      expect(inserted.imagesPath, relativeFolder);
      expect(inserted.picture, '$relativeFolder/0001.jpg');
      // No insert-then-update: a failed import never leaves a zombie row.
      verifyNever(() => db.updateComic(
            id: any(named: 'id'),
            imagesPath: any(named: 'imagesPath'),
            picture: any(named: 'picture'),
            totalPages: any(named: 'totalPages'),
          ));
    });

    test('creates a cover thumbnail outside the page list', () async {
      final page = img.Image(width: 1200, height: 1800);
      img.fill(page, color: img.ColorRgb8(200, 30, 30));
      final file = buildArchive(sandbox, 'real.cbz', {
        '01.png': img.encodePng(page),
        '02.png': img.encodePng(page),
      });

      final result = await importFile(file);

      expect(result.picture,
          p.join(result.imagesPath, thumbnailFolderName, 'cover.jpg'));
      final thumb = img.decodeJpg(File(result.picture).readAsBytesSync())!;
      expect(thumb.width, 400);
      expect(thumb.height, 600);
      expect(pageFiles(result.imagesPath), ['0001.png', '0002.png']);
      expect(insertedModel().picture,
          'comics/${p.basename(result.imagesPath)}/thumb/cover.jpg');
    });

    test('natural sort handles nested chapter folders (ch2 < ch10)',
        () async {
      final file = buildArchive(sandbox, 'vol.cbz', {
        'ch10/': null,
        'ch10/001.jpg': [10],
        'ch2/001.jpg': [2],
        'ch1/002.jpg': [12],
        'ch1/001.jpg': [11],
      });

      final result = await importFile(file);
      expect(firstBytesInOrder(result.imagesPath), [11, 12, 2, 10]);
    });

    test('natural sort ignores case (page2 < Page10)', () async {
      final file = buildArchive(sandbox, 'case.cbz', {
        'Page10.jpg': [10],
        'page2.jpg': [2],
        'PAGE1.jpg': [1],
      });
      final result = await importFile(file);
      expect(firstBytesInOrder(result.imagesPath), [1, 2, 10]);
    });

    test('accepts upper-case extensions (.CBZ archive, .JPG/.JPEG pages)',
        () async {
      final file = buildArchive(sandbox, 'UPPER.CBZ', {
        'B.JPEG': fakeJpg,
        'A.JPG': fakeJpg,
      });

      final result = await importFile(file);

      expect(result.totalPages, 2);
      expect(pageFiles(result.imagesPath), ['0001.jpg', '0002.jpeg']);
    });

    test('accepts webp/gif/bmp and skips macOS junk entries', () async {
      final file = buildArchive(sandbox, 'mixed.cbz', {
        '__MACOSX/._01.webp': [0],
        '._02.gif': [0],
        '01.webp': [1],
        '02.gif': [2],
        '03.bmp': [3],
      });

      final result = await importFile(file);

      expect(
          pageFiles(result.imagesPath), ['0001.webp', '0002.gif', '0003.bmp']);
      expect(firstBytesInOrder(result.imagesPath), [1, 2, 3]);
    });

    test('entry names with ../ cannot write outside the comic folder',
        () async {
      final file = buildArchive(sandbox, 'slip.cbz', {
        '../../evil.jpg': [7],
      });

      final result = await importFile(file);

      expect(pageFiles(result.imagesPath), ['0001.jpg']);
      expect(File(p.join(appDocs.path, 'evil.jpg')).existsSync(), isFalse);
      expect(File(p.join(sandbox.path, 'evil.jpg')).existsSync(), isFalse);
    });

    test('ComicInfo.xml is not a page', () async {
      final file = buildArchive(sandbox, 'm.cbz', {
        'ComicInfo.xml': comicInfoXml(manga: 'YesAndRightToLeft'),
        '01.jpg': fakeJpg,
      });
      final result = await importFile(file);
      expect(result.totalPages, 1);
      expect(pageFiles(result.imagesPath), ['0001.jpg']);
    });

    for (final variant in <String, String?>{
      'YesAndRightToLeft': 'Manga',
      'Yes': 'Manga',
      'No': 'Comic',
      'Unknown': null,
    }.entries) {
      test(
          'ComicInfo.xml <Manga>${variant.key}</Manga> sets comicType '
          '${variant.value}', () async {
        final file = buildArchive(sandbox, 'm.cbz', {
          'ComicInfo.xml': comicInfoXml(
              manga: variant.key,
              writer: 'Oda',
              genre: 'Shonen, Aventura',
              series: 'One Piece'),
          '01.jpg': fakeJpg,
        });
        final result = await importFile(file);
        expect(result.comicType, variant.value);
        expect(result.author, 'Oda');
        expect(result.genre, 'Shonen');
        expect(result.collection, 'One Piece');
        expect(insertedModel().comicType, variant.value);
      });
    }

    test('metadata given by the caller wins over ComicInfo.xml', () async {
      final file = buildArchive(sandbox, 'm.cbz', {
        'ComicInfo.xml': comicInfoXml(manga: 'No', writer: 'Oda'),
        '01.jpg': fakeJpg,
      });
      final result = await importFile(file,
          comic: buildComicEntity(
              id: null,
              title: 'm.cbz',
              filePath: file.path,
              author: 'Toriyama',
              comicType: 'Manga'));
      expect(result.author, 'Toriyama');
      expect(result.comicType, 'Manga');
    });

    test('malformed ComicInfo.xml is ignored', () async {
      final file = buildArchive(sandbox, 'm.cbz', {
        'ComicInfo.xml': '<ComicInfo><Writer>Oda',
        '01.jpg': fakeJpg,
      });
      final result = await importFile(file);
      expect(result.totalPages, 1);
      expect(result.author, isNull);
    });

    test('detects the format by content: a ZIP named .cbr imports', () async {
      final zip = buildArchive(sandbox, 'tmp.zip', {'1.jpg': fakeJpg});
      final file = zip.renameSync(p.join(sandbox.path, 'actually_zip.cbr'));
      final result = await importFile(file);
      expect(result.totalPages, 1);
    });

    Future<void> expectRejected(File file, {String? message}) async {
      await expectLater(
        importFile(file),
        throwsA(isA<UnsupportedComicException>().having(
            (e) => e.message, 'message', contains(message ?? ''))),
      );
      verifyNever(() => db.addComic(any()));
      expect(leftovers(), isEmpty);
    }

    test('random bytes are rejected as not a CBZ/CBR', () async {
      await expectRejected(
          writeRawFile(sandbox, 'bad.cbz',
              List<int>.generate(512, (i) => (i * 37) % 256)),
          message: 'no es un CBZ/CBR válido');
    });

    test('truncated CBZ is rejected and cleaned up', () async {
      final good = buildArchive(sandbox, 'good.cbz', {
        '1.jpg': List<int>.generate(4096, (i) => i % 251),
        '2.jpg': List<int>.generate(4096, (i) => i % 241),
      });
      final bytes = good.readAsBytesSync();
      await expectRejected(writeRawFile(
          sandbox, 'trunc.cbz', bytes.sublist(0, bytes.length ~/ 2)));
    });

    test('zero-byte file is rejected', () async {
      await expectRejected(writeRawFile(sandbox, 'empty.cbz', []));
    });

    test('CBZ without images is rejected with "no contiene imágenes"',
        () async {
      await expectRejected(
          buildArchive(sandbox, 'noimg.cbz', {
            'ComicInfo.xml': comicInfoXml(title: 'x'),
            'readme.txt': 'hi',
          }),
          message: 'no contiene imágenes');
    });

    test('empty ZIP archive is rejected', () async {
      await expectRejected(buildArchive(sandbox, 'void.cbz', {}));
    });

    test('missing source file is rejected', () async {
      await expectRejected(File(p.join(sandbox.path, 'ghost.cbz')),
          message: 'No se encontró');
    });

    test('a DB failure removes the extracted folder and rethrows', () async {
      final file = buildArchive(sandbox, 'a.cbz', {'1.jpg': fakeJpg});
      when(() => db.addComic(any())).thenThrow(StateError('db down'));

      await expectLater(importFile(file), throwsA(isA<StateError>()));
      expect(leftovers(), isEmpty);
    });

    group('CBR (unrar platform channel mocked)', () {
      final rarMagic = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00, 0x00];
      final rar5Magic = [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00];

      void onExtract(void Function(String dest) write) {
        messenger.setMockMethodCallHandler(unrarChannel, (call) async {
          expect(call.method, 'extractRAR');
          write((call.arguments as Map)['destination_path'] as String);
          return 'Extraction Success';
        });
      }

      void put(String dest, String relative, List<int> bytes) =>
          File(p.join(dest, relative))
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes);

      test('keeps chapter order and same-named pages in sub-folders',
          () async {
        final file = writeRawFile(sandbox, 'x.cbr', rarMagic);
        onExtract((dest) {
          put(dest, 'cap2/001.jpg', [21]);
          put(dest, 'cap1/002.png', [12]);
          put(dest, 'cap1/001.jpg', [11]);
          put(dest, 'cap10/001.jpeg', [101]);
          put(dest, 'info.txt', [0]);
        });

        final result = await importFile(file);

        expect(result.totalPages, 4);
        expect(firstBytesInOrder(result.imagesPath), [11, 12, 21, 101]);
        expect(pageFiles(result.imagesPath),
            ['0001.jpg', '0002.png', '0003.jpg', '0004.jpeg']);
      });

      test('reads ComicInfo.xml from the RAR', () async {
        final file = writeRawFile(sandbox, 'x.cbr', rarMagic);
        onExtract((dest) {
          put(dest, '01.jpg', [1]);
          File(p.join(dest, 'ComicInfo.xml'))
              .writeAsStringSync(comicInfoXml(manga: 'YesAndRightToLeft'));
        });
        final result = await importFile(file);
        expect(result.comicType, 'Manga');
      });

      test('extraction failure -> UnsupportedComicException mentioning CBR',
          () async {
        messenger.setMockMethodCallHandler(unrarChannel, (call) async {
          throw PlatformException(code: 'extractionError', message: 'boom');
        });
        await expectRejected(writeRawFile(sandbox, 'y.cbr', rarMagic),
            message: 'CBR');
      });

      test('RAR5 failure explains that RAR5 is not supported', () async {
        messenger.setMockMethodCallHandler(unrarChannel, (call) async {
          throw PlatformException(code: 'extractionError', message: 'boom');
        });
        await expectRejected(writeRawFile(sandbox, 'y5.cbr', rar5Magic),
            message: 'RAR5');
      });

      test('RAR without images -> "no contiene imágenes"', () async {
        messenger.setMockMethodCallHandler(
            unrarChannel, (call) async => 'Extraction Success');
        await expectRejected(writeRawFile(sandbox, 'z.cbr', rarMagic),
            message: 'no contiene imágenes');
      });
    });
  });

  group('stored paths', () {
    test('relative paths are resolved against the documents directory',
        () async {
      when(() => db.fetchAllComics()).thenAnswer((_) async => [
            buildComicModel(
                id: 1,
                imagesPath: 'comics/c_1',
                picture: 'comics/c_1/thumb/cover.jpg'),
          ]);
      final comic = (await repo.getAllComics()).single;
      expect(comic.imagesPath, p.join(appDocs.path, 'comics', 'c_1'));
      expect(comic.picture,
          p.join(appDocs.path, 'comics', 'c_1', 'thumb', 'cover.jpg'));
    });

    test('legacy absolute paths and empty pictures are kept as-is', () async {
      final legacy = p.join(appDocs.path, 'comics', '7');
      when(() => db.getComicsByAuthor('Oda')).thenAnswer((_) async =>
          [buildComicModel(id: 7, imagesPath: legacy, picture: '')]);
      final comic = (await repo.getComicsByAuthor('Oda')).single;
      expect(comic.imagesPath, legacy);
      expect(comic.picture, '');
    });
  });

  group('reads', () {
    test('getComicByPath maps model to entity / returns null', () async {
      when(() => db.getComicByPath('/a')).thenAnswer(
          (_) async => buildComicModel(id: 3, author: 'A', comicType: 'Manga'));
      when(() => db.getComicByPath('/none')).thenAnswer((_) async => null);

      final c = await repo.getComicByPath('/a');
      expect(comicFields(c!),
          comicFields(buildComicModel(id: 3, author: 'A', comicType: 'Manga')));
      expect(await repo.getComicByPath('/none'), isNull);
    });

    test('getComicByTitle maps / null', () async {
      when(() => db.getComicByTitle('t'))
          .thenAnswer((_) async => buildComicModel(id: 4, rating: 5));
      expect((await repo.getComicByTitle('t'))!.rating, 5);
      expect(await repo.getComicByTitle('missing'), isNull);
    });

    test('getComicByFilenameMatch maps / null', () async {
      when(() => db.getComicByFilenameMatch('f.cbz'))
          .thenAnswer((_) async => buildComicModel(id: 6, genre: 'G'));
      when(() => db.getComicByFilenameMatch('x.cbz'))
          .thenAnswer((_) async => null);
      expect((await repo.getComicByFilenameMatch('f.cbz'))!.genre, 'G');
      expect(await repo.getComicByFilenameMatch('x.cbz'), isNull);
    });

    test('getAllComics maps every model preserving order', () async {
      final models = [
        buildComicModel(id: 1, title: 'a', isFavorite: true),
        buildComicModel(id: 2, title: 'b', collection: 'C'),
      ];
      when(() => db.fetchAllComics()).thenAnswer((_) async => models);

      final all = await repo.getAllComics();
      expect(all.map(comicFields), models.map(comicFields));
    });

    test('getAllComics propagates datasource errors', () async {
      when(() => db.fetchAllComics()).thenThrow(Exception('io'));
      expect(repo.getAllComics(), throwsException);
    });

    test('getDistinct* delegate with the right column', () async {
      when(() => db.getDistinctValues(any())).thenAnswer(
          (inv) async => ['v:${inv.positionalArguments.first}']);
      expect(await repo.getDistinctAuthors(), ['v:${ComicFields.author}']);
      expect(await repo.getDistinctGenres(), ['v:${ComicFields.genre}']);
      expect(await repo.getDistinctCollections(),
          ['v:${ComicFields.collection}']);
    });

    test('getComicsBy* delegate', () async {
      when(() => db.getComicsByAuthor('a'))
          .thenAnswer((_) async => [buildComicModel(id: 1)]);
      when(() => db.getComicsByGenre('g'))
          .thenAnswer((_) async => [buildComicModel(id: 2)]);
      when(() => db.getComicsByCollection('c'))
          .thenAnswer((_) async => [buildComicModel(id: 3)]);
      expect((await repo.getComicsByAuthor('a')).single.id, 1);
      expect((await repo.getComicsByGenre('g')).single.id, 2);
      expect((await repo.getComicsByCollection('c')).single.id, 3);
    });
  });

  group('writes', () {
    test('addBookMark -> updateBookmark', () async {
      when(() => db.updateBookmark(1, 7)).thenAnswer((_) async {});
      await repo.addBookMark(1, 7);
      verify(() => db.updateBookmark(1, 7)).called(1);
    });

    test('startReadingComic -> updateComic(isReading: true)', () async {
      await repo.startReadingComic(9);
      final call = captureUpdateComicCalls(db).single;
      expect(call['id'], 9);
      expect(call['isReading'], true);
      expect(call['title'], isNull);
    });

    test('deleteComic delegates', () async {
      await repo.deleteComic(3);
      verify(() => db.deleteComic(3)).called(1);
    });

    test('updateComicMetadata forwards only metadata fields', () async {
      await repo.updateComicMetadata(
        id: 2,
        title: 'T',
        author: 'A',
        genre: 'G',
        collection: 'C',
        comicType: 'Manga',
      );
      final call = captureUpdateComicCalls(db).single;
      expect(call, {
        'id': 2,
        'imagesPath': null,
        'picture': null,
        'filePath': null,
        'title': 'T',
        'totalPages': null,
        'isReading': null,
        'isCompleted': null,
        'author': 'A',
        'genre': 'G',
        'collection': 'C',
        'comicType': 'Manga',
      });
    });
  });
}
