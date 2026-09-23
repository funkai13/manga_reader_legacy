import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/repositories/comic_file_repository.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_file_provider.dart';
import 'package:manga_reader/feature/Home/domain/repositories/comic_file_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockComicFileRepository fileRepo;

  setUp(() => fileRepo = MockComicFileRepository());

  group('ExtractComicImagesUseCase', () {
    test('delegates to ComicFileRepository.extractComic', () async {
      final files = [File('a.jpg'), File('b.jpg')];
      when(() => fileRepo.extractComic('/c.cbz'))
          .thenAnswer((_) async => files);

      final useCase = ExtractComicImagesUseCase(fileRepo);
      expect(await useCase('/c.cbz'), files);
      verify(() => fileRepo.extractComic('/c.cbz')).called(1);
    });

    test('propagates errors', () async {
      when(() => fileRepo.extractComic(any()))
          .thenThrow(Exception('Unsupported file format'));
      expect(() => ExtractComicImagesUseCase(fileRepo)('/x.pdf'),
          throwsException);
    });
  });

  group('providers', () {
    test('comicFileRepositoryProvider defaults to ComicFileRepositoryImpl',
        () {
      final container = ProviderContainer.test();
      expect(container.read(comicFileRepositoryProvider),
          isA<ComicFileRepositoryImpl>());
    });

    test('extractComicImagesUseCaseProvider uses the (overridden) repository',
        () async {
      when(() => fileRepo.extractComic(any())).thenAnswer((_) async => []);
      final container = ProviderContainer.test(overrides: [
        comicFileRepositoryProvider.overrideWithValue(fileRepo),
      ]);
      final useCase = container.read(extractComicImagesUseCaseProvider);
      expect(useCase.comicFileRepository, same(fileRepo));
      await useCase('/a.cbz');
      verify(() => fileRepo.extractComic('/a.cbz')).called(1);
    });
  });
}
