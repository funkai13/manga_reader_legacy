import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
import 'package:manga_reader/feature/Home/data/repositories/comic_repository_impl.dart';
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
    repo = ComicRepositoryImpl(db);
    sandbox = createTempDir('repo_src_');
    appDocs = createTempDir('repo_docs_');
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

  String comicFolder([int id = newId]) =>
      p.join(appDocs.path, 'comics', id.toString());

  List<String> folderContents([int id = newId]) {
    final dir = Directory(comicFolder(id));
    if (!dir.existsSync()) return [];
    return dir.listSync().map((e) => p.basename(e.path)).toList()..sort();
  }

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

    test('inserts with id=null and the entity data', () async {
      final file = buildArchive(sandbox, 'a.cbz', {'1.jpg': fakeJpg});
      await repo.addComic(buildComicEntity(
          id: 99, title: 'a.cbz', filePath: file.path, author: 'Oda'));

      final inserted = verify(() => db.addComic(captureAny())).captured.single
          as dynamic;
      expect(inserted.id, isNull);
      expect(inserted.title, 'a.cbz');
      expect(inserted.filePath, file.path);
      expect(inserted.author, 'Oda');
    });

    test('extracts CBZ pages in natural order, renames and updates DB',
        () async {
      final file = buildArchive(sandbox, 'naruto.cbz', {
        'page10.jpg': fakeJpg,
        'page2.png': fakePng,
        'page1.jpg': fakeJpg,
        'ComicInfo.xml': comicInfoXml(title: 'Naruto', writer: 'Kishimoto'),
        'notes.txt': 'hello',
        'thumbs.db': [1, 2, 3],
      });

      final result = await repo.addComic(buildComicEntity(
          id: null, title: 'naruto.cbz', filePath: file.path));

      final folder = comicFolder();
      expect(folderContents(), ['0001.jpg', '0002.png', '0003.jpg']);
      expect(Directory(p.join(folder, 'temp_extract')).existsSync(), isFalse);
      // page1 -> 0001, page2 -> 0002 (png), page10 -> 0003
      expect(File(p.join(folder, '0002.png')).readAsBytesSync(), fakePng);

      expect(result.id, newId);
      expect(result.totalPages, 3);
      expect(result.imagesPath, folder);
      expect(result.picture, p.join(folder, '0001.jpg'));

      final call = captureUpdateComicCalls(db).single;
      expect(call['id'], newId);
      expect(call['imagesPath'], folder);
      expect(call['picture'], p.join(folder, '0001.jpg'));
      expect(call['totalPages'], 3);
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

      await repo.addComic(
          buildComicEntity(id: null, title: 'vol.cbz', filePath: file.path));

      final folder = comicFolder();
      final order = [
        for (final n in folderContents())
          File(p.join(folder, n)).readAsBytesSync().first
      ];
      expect(order, [11, 12, 2, 10]);
    });

    test('accepts upper-case extensions (.CBZ archive, .JPG/.JPEG pages)',
        () async {
      final file = buildArchive(sandbox, 'UPPER.CBZ', {
        'B.JPEG': fakeJpg,
        'A.JPG': fakeJpg,
      });

      final result = await repo.addComic(
          buildComicEntity(id: null, title: 'UPPER.CBZ', filePath: file.path));

      expect(result.totalPages, 2);
      expect(folderContents(), ['0001.jpg', '0002.jpeg']);
    });

    test('ComicInfo.xml is ignored as a page', () async {
      final file = buildArchive(sandbox, 'm.cbz', {
        'ComicInfo.xml': comicInfoXml(manga: 'YesAndRightToLeft'),
        '01.jpg': fakeJpg,
      });
      final result = await repo.addComic(
          buildComicEntity(id: null, title: 'm.cbz', filePath: file.path));
      expect(result.totalPages, 1);
      expect(folderContents(), ['0001.jpg']);
    });

    for (final variant in <String, String?>{
      'YesAndRightToLeft': 'Manga',
      'Yes': 'Manga',
      'No': 'Comic',
    }.entries) {
      test(
        'ComicInfo.xml <Manga>${variant.key}</Manga> sets comicType '
        '${variant.value}',
        () async {
          final file = buildArchive(sandbox, 'm.cbz', {
            'ComicInfo.xml': comicInfoXml(
                manga: variant.key, writer: 'Oda', genre: 'Shonen'),
            '01.jpg': fakeJpg,
          });
          final result = await repo.addComic(
              buildComicEntity(id: null, title: 'm.cbz', filePath: file.path));
          expect(result.comicType, variant.value);
          expect(result.author, 'Oda');
          expect(result.genre, 'Shonen');
        },
        skip: 'MISSING FEATURE: ComicInfo.xml is never parsed (package:xml '
            'is a dependency but unused). Manga/Writer/Genre/Series are not '
            'imported, so the auto manga (RTL) mode only works if the user '
            'picks "Manga" manually.',
      );
    }

    test('current behaviour: ComicInfo metadata does not change comicType',
        () async {
      final file = buildArchive(sandbox, 'm.cbz', {
        'ComicInfo.xml': comicInfoXml(manga: 'YesAndRightToLeft'),
        '01.jpg': fakeJpg,
      });
      final result = await repo.addComic(
          buildComicEntity(id: null, title: 'm.cbz', filePath: file.path));
      expect(result.comicType, isNull);
    });

    test('corrupt CBZ throws UnsupportedComicException and cleans up',
        () async {
      final file = writeRawFile(sandbox, 'bad.cbz',
          List<int>.generate(512, (i) => (i * 37) % 256));

      await expectLater(
        repo.addComic(
            buildComicEntity(id: null, title: 'bad.cbz', filePath: file.path)),
        // NOTE: archive 4.x ZipDecoder is lenient and returns an empty
        // archive for random bytes, so the user sees "no contiene imágenes"
        // instead of the "corrupto" message.
        throwsA(isA<UnsupportedComicException>()),
      );
      verify(() => db.deleteComic(newId)).called(1);
      expect(Directory(comicFolder()).existsSync(), isFalse);
    });

    test('truncated CBZ throws UnsupportedComicException and cleans up',
        () async {
      final good = buildArchive(sandbox, 'good.cbz', {
        '1.jpg': List<int>.generate(4096, (i) => i % 251),
        '2.jpg': List<int>.generate(4096, (i) => i % 241),
      });
      final bytes = good.readAsBytesSync();
      final file =
          writeRawFile(sandbox, 'trunc.cbz', bytes.sublist(0, bytes.length ~/ 2));

      await expectLater(
        repo.addComic(buildComicEntity(
            id: null, title: 'trunc.cbz', filePath: file.path)),
        throwsA(isA<UnsupportedComicException>()),
      );
      verify(() => db.deleteComic(newId)).called(1);
      expect(Directory(comicFolder()).existsSync(), isFalse);
    });

    test('zero-byte CBZ throws UnsupportedComicException and cleans up',
        () async {
      final file = writeRawFile(sandbox, 'empty.cbz', []);
      await expectLater(
        repo.addComic(buildComicEntity(
            id: null, title: 'empty.cbz', filePath: file.path)),
        throwsA(isA<UnsupportedComicException>()),
      );
      verify(() => db.deleteComic(newId)).called(1);
      expect(Directory(comicFolder()).existsSync(), isFalse);
    });

    test('CBZ without images throws "no contiene imágenes" and cleans up',
        () async {
      final file = buildArchive(sandbox, 'noimg.cbz', {
        'ComicInfo.xml': comicInfoXml(title: 'x'),
        'readme.txt': 'hi',
        'cover.gif': [1, 2],
      });
      await expectLater(
        repo.addComic(buildComicEntity(
            id: null, title: 'noimg.cbz', filePath: file.path)),
        throwsA(isA<UnsupportedComicException>().having(
            (e) => e.message, 'message', contains('no contiene imágenes'))),
      );
      verify(() => db.deleteComic(newId)).called(1);
      expect(Directory(comicFolder()).existsSync(), isFalse);
      verifyNever(() => db.updateComic(
            id: any(named: 'id'),
            imagesPath: any(named: 'imagesPath'),
            picture: any(named: 'picture'),
            totalPages: any(named: 'totalPages'),
          ));
    });

    test('empty CBZ archive throws UnsupportedComicException', () async {
      final file = buildArchive(sandbox, 'void.cbz', {});
      await expectLater(
        repo.addComic(buildComicEntity(
            id: null, title: 'void.cbz', filePath: file.path)),
        throwsA(isA<UnsupportedComicException>()),
      );
      verify(() => db.deleteComic(newId)).called(1);
    });

    test('unsupported extension throws UnsupportedComicException', () async {
      final file = buildArchive(sandbox, 'book.zip', {'1.jpg': fakeJpg});
      await expectLater(
        repo.addComic(buildComicEntity(
            id: null, title: 'book.zip', filePath: file.path)),
        throwsA(isA<UnsupportedComicException>()),
      );
      verify(() => db.deleteComic(newId)).called(1);
      expect(Directory(comicFolder()).existsSync(), isFalse);
    });

    test(
      'missing source file is rejected',
      () async {
        await expectLater(
          repo.addComic(buildComicEntity(
              id: null,
              title: 'ghost.cbz',
              filePath: p.join(sandbox.path, 'ghost.cbz'))),
          throwsA(isA<UnsupportedComicException>()),
        );
        verify(() => db.deleteComic(newId)).called(1);
      },
      skip: 'BUG: _extractComicToFolder returns an empty list when the '
          'archive does not exist, so addComic silently stores a comic with '
          'totalPages=0 and no cover instead of failing.',
    );

    test('current behaviour: missing source file is stored with 0 pages',
        () async {
      final result = await repo.addComic(buildComicEntity(
          id: null,
          title: 'ghost.cbz',
          filePath: p.join(sandbox.path, 'ghost.cbz')));
      expect(result.totalPages, 0);
      expect(result.picture, '');
      verifyNever(() => db.deleteComic(any()));
    });

    test('rethrows non-Unsupported errors after cleanup', () async {
      final file = buildArchive(sandbox, 'a.cbz', {'1.jpg': fakeJpg});
      when(() => db.updateComic(
            id: any(named: 'id'),
            imagesPath: any(named: 'imagesPath'),
            picture: any(named: 'picture'),
            totalPages: any(named: 'totalPages'),
          )).thenThrow(StateError('db down'));

      await expectLater(
        repo.addComic(
            buildComicEntity(id: null, title: 'a.cbz', filePath: file.path)),
        throwsA(isA<StateError>()),
      );
      verify(() => db.deleteComic(newId)).called(1);
      expect(Directory(comicFolder()).existsSync(), isFalse);
    });

    group('CBR (unrar platform channel mocked)', () {
      test('copies extracted images (flattened) in natural order', () async {
        final file = writeRawFile(sandbox, 'x.cbr', [0x52, 0x61, 0x72, 0x21]);
        String? receivedSource;
        messenger.setMockMethodCallHandler(unrarChannel, (call) async {
          expect(call.method, 'extractRAR');
          final args = call.arguments as Map;
          receivedSource = args['file_path'] as String;
          final dest = args['destination_path'] as String;
          Directory(p.join(dest, 'sub')).createSync(recursive: true);
          File(p.join(dest, 'p10.jpg')).writeAsBytesSync([10]);
          File(p.join(dest, 'p9.png')).writeAsBytesSync([9]);
          File(p.join(dest, 'sub', 'p1.jpeg')).writeAsBytesSync([1]);
          File(p.join(dest, 'info.xml')).writeAsStringSync('<x/>');
          return 'Extraction Success';
        });

        final result = await repo.addComic(
            buildComicEntity(id: null, title: 'x.cbr', filePath: file.path));

        expect(receivedSource, file.path);
        expect(result.totalPages, 3);
        final folder = comicFolder();
        final order = [
          for (final n in folderContents())
            File(p.join(folder, n)).readAsBytesSync().first
        ];
        expect(order, [1, 9, 10]);
        expect(folderContents(), ['0001.jpeg', '0002.png', '0003.jpg']);
      });

      test('extraction failure -> UnsupportedComicException (RAR5) + cleanup',
          () async {
        final file = writeRawFile(sandbox, 'y.cbr', [1, 2, 3]);
        messenger.setMockMethodCallHandler(unrarChannel, (call) async {
          throw PlatformException(code: 'extractionError', message: 'boom');
        });

        await expectLater(
          repo.addComic(
              buildComicEntity(id: null, title: 'y.cbr', filePath: file.path)),
          throwsA(isA<UnsupportedComicException>()
              .having((e) => e.message, 'message', contains('CBR'))),
        );
        verify(() => db.deleteComic(newId)).called(1);
        expect(Directory(comicFolder()).existsSync(), isFalse);
      });

      test('RAR without images -> UnsupportedComicException', () async {
        final file = writeRawFile(sandbox, 'z.cbr', [1]);
        messenger.setMockMethodCallHandler(
            unrarChannel, (call) async => 'Extraction Success');

        await expectLater(
          repo.addComic(
              buildComicEntity(id: null, title: 'z.cbr', filePath: file.path)),
          throwsA(isA<UnsupportedComicException>().having(
              (e) => e.message, 'message', contains('no contiene imágenes'))),
        );
      });
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
