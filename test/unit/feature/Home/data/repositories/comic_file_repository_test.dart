import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/repositories/comic_file_repository.dart';
import 'package:path/path.dart' as p;

import '../../../../helpers/archive_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ComicFileRepositoryImpl repo;
  late Directory sandbox;
  final createdDirs = <Directory>[];

  const unrarChannel = MethodChannel('unrar_file');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    repo = ComicFileRepositoryImpl();
    sandbox = createTempDir('file_repo_');
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(unrarChannel, null);
    deleteQuietly(sandbox);
    createdDirs.forEach(deleteQuietly);
    createdDirs.clear();
  });

  Future<List<File>> extract(String path) async {
    final files = await repo.extractComic(path);
    // The implementation leaks a system temp dir per call; clean it up.
    for (final f in files) {
      createdDirs.add(f.parent);
    }
    return files;
  }

  group('extractComic (.cbz)', () {
    test('extracts only .jpg/.png files with their content', () async {
      final file = buildArchive(sandbox, 'a.cbz', {
        '01.jpg': fakeJpg,
        '02.png': fakePng,
        'ComicInfo.xml': comicInfoXml(manga: 'YesAndRightToLeft'),
        'notes.txt': 'x',
      });

      final files = await extract(file.path);

      expect(files.map((f) => p.basename(f.path)).toSet(), {'01.jpg', '02.png'});
      final png = files.firstWhere((f) => f.path.endsWith('02.png'));
      expect(png.readAsBytesSync(), fakePng);
      for (final f in files) {
        expect(f.existsSync(), isTrue);
      }
    });

    test('archive without images returns an empty list', () async {
      final file = buildArchive(sandbox, 'e.cbz', {'readme.txt': 'hi'});
      expect(await extract(file.path), isEmpty);
    });

    test('garbage bytes do not throw (lenient decoder) and yield no pages',
        () async {
      final file = writeRawFile(
          sandbox, 'bad.cbz', List<int>.generate(300, (i) => (i * 7) % 256));
      expect(await extract(file.path), isEmpty);
    });

    test(
      'returns pages in natural order',
      () async {
        final file = buildArchive(sandbox, 'o.cbz', {
          'p10.jpg': [10],
          'p2.jpg': [2],
          'p1.jpg': [1],
        });
        final files = await extract(file.path);
        expect(files.map((f) => p.basename(f.path)),
            ['p1.jpg', 'p2.jpg', 'p10.jpg']);
      },
      skip: 'BUG: ComicFileRepositoryImpl returns pages in archive entry '
          'order (no sorting), unlike ComicRepositoryImpl which uses a '
          'natural sort.',
    );

    test(
      'supports images inside sub-folders',
      () async {
        final file = buildArchive(sandbox, 'n.cbz', {
          'chapter1/': null,
          'chapter1/01.jpg': fakeJpg,
        });
        final files = await extract(file.path);
        expect(files, hasLength(1));
      },
      skip: 'BUG: _extractFiles writes "<temp>/<entry name>" without creating '
          'parent folders, so archives with sub-folders throw '
          'PathNotFoundException.',
    );

    test('current behaviour: sub-folders throw a FileSystemException',
        () async {
      final file = buildArchive(sandbox, 'n.cbz', {
        'chapter1/01.jpg': fakeJpg,
      });
      await expectLater(
          repo.extractComic(file.path), throwsA(isA<FileSystemException>()));
    });

    test(
      'supports .jpeg and upper-case extensions',
      () async {
        final file = buildArchive(sandbox, 'U.CBZ', {
          'a.JPG': fakeJpg,
          'b.jpeg': fakeJpg,
        });
        expect(await extract(file.path), hasLength(2));
      },
      skip: 'BUG: ComicFileRepositoryImpl checks extensions case-sensitively '
          'and ignores .jpeg (".CBZ" archives are rejected as unsupported, '
          '"A.JPG"/"b.jpeg" pages are dropped). ComicRepositoryImpl handles '
          'both.',
    );

    test('current behaviour: .jpeg and .JPG pages are ignored', () async {
      final file = buildArchive(sandbox, 'x.cbz', {
        'a.JPG': fakeJpg,
        'b.jpeg': fakeJpg,
        'c.jpg': fakeJpg,
      });
      final files = await extract(file.path);
      expect(files.map((f) => p.basename(f.path)), ['c.jpg']);
    });
  });

  group('extractComic errors', () {
    test('unsupported extension throws', () async {
      final file = buildArchive(sandbox, 'a.zip', {'1.jpg': fakeJpg});
      await expectLater(
        repo.extractComic(file.path),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'toString', contains('Unsupported file format'))),
      );
    });

    test('current behaviour: upper-case .CBZ is rejected', () async {
      final file = buildArchive(sandbox, 'A.CBZ', {'1.jpg': fakeJpg});
      await expectLater(repo.extractComic(file.path), throwsException);
    });

    test('missing file throws FileSystemException', () async {
      await expectLater(
        repo.extractComic(p.join(sandbox.path, 'nope.cbz')),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('extractComic (.cbr, unrar channel mocked)', () {
    test('returns extracted .jpg/.png recursively', () async {
      final file = writeRawFile(sandbox, 'a.cbr', [1, 2, 3]);
      messenger.setMockMethodCallHandler(unrarChannel, (call) async {
        final dest = (call.arguments as Map)['destination_path'] as String;
        createdDirs.add(Directory(dest));
        Directory(p.join(dest, 'sub')).createSync();
        File(p.join(dest, '1.jpg')).writeAsBytesSync([1]);
        File(p.join(dest, 'sub', '2.png')).writeAsBytesSync([2]);
        File(p.join(dest, 'x.txt')).writeAsStringSync('x');
        return 'Extraction Success';
      });

      final files = await extract(file.path);
      expect(files.map((f) => p.basename(f.path)).toSet(), {'1.jpg', '2.png'});
    });

    test('wraps extraction errors', () async {
      final file = writeRawFile(sandbox, 'b.cbr', [1]);
      messenger.setMockMethodCallHandler(unrarChannel, (call) async {
        throw PlatformException(code: 'err', message: 'corrupt rar');
      });

      await expectLater(
        repo.extractComic(file.path),
        throwsA(isA<Exception>().having((e) => e.toString(), 'toString',
            allOf(contains('Error extracting CBR file'), contains('corrupt rar')))),
      );
    });
  });
}
