import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_viewer_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import '../../../../helpers/archive_builder.dart';
import '../../../../helpers/comic_fixtures.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/riverpod_utils.dart';

void main() {
  late MockComicRepository repo;
  late ProviderContainer container;
  late Directory images;

  setUp(() {
    repo = MockComicRepository();
    when(() => repo.getAllComics())
        .thenAnswer((_) async => [buildComicEntity(id: 1)]);
    when(() => repo.startReadingComic(any())).thenAnswer((_) async {});
    container = createContainer(comicRepository: repo);
    images = createTempDir('viewer_');
  });

  tearDown(() => deleteQuietly(images));

  void touch(String name) =>
      File(p.join(images.path, name)).writeAsBytesSync([0]);

  ComicViewerController viewer() =>
      container.read(comicViewerControllerProvider.notifier);

  test('initial state is an empty list', () async {
    expect(await container.read(comicViewerControllerProvider.future), isEmpty);
  });

  test('loadComic: loading -> data with only image files', () async {
    for (final n in [
      '0001.jpg',
      '0002.JPEG',
      '0003.png',
      'ComicInfo.xml',
      'notes.txt',
      'cover.gif'
    ]) {
      touch(n);
    }
    Directory(p.join(images.path, 'sub.jpg')).createSync(); // dir, not file

    await container.read(comicViewerControllerProvider.future);
    final states = recordStates(container, comicViewerControllerProvider);

    await viewer().loadComic(images.path, 1);

    expect(states.any((s) => s.isLoading), isTrue);
    final result = container.read(comicViewerControllerProvider);
    expect(result, isA<AsyncData<List<File>>>());
    expect(result.value!.map((f) => p.basename(f.path)).toSet(),
        {'0001.jpg', '0002.JPEG', '0003.png', 'cover.gif'});
  });

  test('loadComic marks the comic as reading in ComicController', () async {
    await container.read(comicControllerProvider.future);
    touch('0001.jpg');

    await viewer().loadComic(images.path, 1);

    verify(() => repo.startReadingComic(1)).called(1);
    expect(container.read(comicControllerProvider).value!.single.isReading,
        isTrue);
  });

  test('loadComic returns pages sorted by file name', () async {
    // Directory listing order is not guaranteed (NTFS happens to be
    // alphabetical, ext4/F2FS on Android is not), so loadComic must sort.
    for (final n in ['0003.jpg', '0001.jpg', '0010.jpg', '0002.jpg']) {
      touch(n);
    }
    await viewer().loadComic(images.path, 1);
    final names = container
        .read(comicViewerControllerProvider)
        .value!
        .map((f) => p.basename(f.path))
        .toList();
    expect(names, ['0001.jpg', '0002.jpg', '0003.jpg', '0010.jpg']);
  });

  test('empty folder -> AsyncData([])', () async {
    await viewer().loadComic(images.path, 1);
    expect(container.read(comicViewerControllerProvider).value, isEmpty);
  });

  test('missing folder -> AsyncError(FileSystemException)', () async {
    await viewer().loadComic(p.join(images.path, 'missing'), 1);
    final state = container.read(comicViewerControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<FileSystemException>());
  });

  test('markAsReading failure -> AsyncError and no images', () async {
    when(() => repo.startReadingComic(any())).thenThrow(Exception('db'));
    touch('0001.jpg');
    await viewer().loadComic(images.path, 1);
    final state = container.read(comicViewerControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<Exception>());
  });

  test('a new load replaces previous pages', () async {
    touch('0001.jpg');
    await viewer().loadComic(images.path, 1);
    final other = createTempDir('viewer2_');
    addTearDown(() => deleteQuietly(other));
    File(p.join(other.path, 'a.png')).writeAsBytesSync([0]);
    File(p.join(other.path, 'b.png')).writeAsBytesSync([0]);

    await viewer().loadComic(other.path, 1);
    expect(container.read(comicViewerControllerProvider).value, hasLength(2));
  });
}
