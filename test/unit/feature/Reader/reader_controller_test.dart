import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';
import 'package:manga_reader/feature/Reader/presenter/reader_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/comic_fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/riverpod_utils.dart';

void main() {
  late MockComicRepository repo;
  late ProviderContainer container;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    repo = MockComicRepository();
    when(() => repo.getAllComics()).thenAnswer((_) async => []);
    when(() => repo.startReadingComic(any())).thenAnswer((_) async {});
    when(() => repo.addBookMark(any(), any())).thenAnswer((_) async {});
    when(() => repo.markCompleted(any())).thenAnswer((_) async {});
    when(() => repo.updateComicMetadata(
          id: any(named: 'id'),
          title: any(named: 'title'),
          author: any(named: 'author'),
          genre: any(named: 'genre'),
          collection: any(named: 'collection'),
          comicType: any(named: 'comicType'),
        )).thenAnswer((_) async {});
    container = createContainer(comicRepository: repo);
  });

  ComicEntity comic({int page = 0, String? type, bool reading = false}) =>
      buildComicEntity(
          id: 3, currentReadPage: page, comicType: type, isReading: reading);

  group('ReadingMode', () {
    test('maps comicType both ways; unknown or null is left to right', () {
      expect(ReadingMode.fromComicType('Manga'), ReadingMode.rightToLeft);
      expect(ReadingMode.fromComicType('Comic'), ReadingMode.leftToRight);
      expect(ReadingMode.fromComicType('Webtoon'), ReadingMode.vertical);
      expect(ReadingMode.fromComicType(null), ReadingMode.leftToRight);
      expect(ReadingMode.fromComicType('???'), ReadingMode.leftToRight);
      for (final mode in ReadingMode.values) {
        expect(ReadingMode.fromComicType(mode.comicType), mode);
      }
      expect(ReadingMode.vertical.isPaged, isFalse);
      expect(ReadingMode.rightToLeft.isPaged, isTrue);
    });
  });

  test('starts at the saved page with the saved mode, controls hidden', () {
    final c = comic(page: 12, type: 'Manga');
    final state = container.read(readerControllerProvider(c));
    expect(state.page, 12);
    expect(state.mode, ReadingMode.rightToLeft);
    expect(state.controlsVisible, isFalse);
  });

  test('marks an unread comic as reading, once', () async {
    final c = comic();
    container.read(readerControllerProvider(c));
    await Future<void>.delayed(Duration.zero);
    verify(() => repo.startReadingComic(3)).called(1);

    final reading = comic(reading: true);
    container.read(readerControllerProvider(reading));
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => repo.startReadingComic(any()));
  });

  test('page changes are saved once after the debounce', () {
    fakeAsync((async) {
      final c = comic();
      final notifier = container.read(readerControllerProvider(c).notifier);
      container.listen(readerControllerProvider(c), (_, __) {});

      notifier.onPageChanged(1, totalPages: 10);
      notifier.onPageChanged(2, totalPages: 10);
      notifier.onPageChanged(3, totalPages: 10);
      expect(container.read(readerControllerProvider(c)).page, 3);
      async.elapse(ReaderController.persistDelay ~/ 2);
      verifyNever(() => repo.addBookMark(any(), any()));

      async.elapse(ReaderController.persistDelay);
      verify(() => repo.addBookMark(3, 3)).called(1);
      verifyNever(() => repo.markCompleted(any()));
    });
  });

  test('flush saves right away; nothing pending means no write', () {
    fakeAsync((async) {
      final c = comic();
      final notifier = container.read(readerControllerProvider(c).notifier);
      container.listen(readerControllerProvider(c), (_, __) {});

      notifier.flush();
      async.flushMicrotasks();
      verifyNever(() => repo.addBookMark(any(), any()));

      notifier.onPageChanged(4, totalPages: 10);
      notifier.flush();
      async.flushMicrotasks();
      verify(() => repo.addBookMark(3, 4)).called(1);

      async.elapse(ReaderController.persistDelay * 2);
      verifyNever(() => repo.addBookMark(any(), any()));
    });
  });

  test('the last page marks the comic completed', () {
    fakeAsync((async) {
      final c = comic();
      final notifier = container.read(readerControllerProvider(c).notifier);
      container.listen(readerControllerProvider(c), (_, __) {});
      notifier.onPageChanged(9, totalPages: 10);
      async.elapse(ReaderController.persistDelay * 2);
      verify(() => repo.markCompleted(3)).called(1);
    });
  });

  test('disposing the reader saves the pending page', () {
    fakeAsync((async) {
      final c = comic();
      final sub = container.listen(readerControllerProvider(c), (_, __) {});
      container.read(readerControllerProvider(c).notifier)
          .onPageChanged(6, totalPages: 10);

      sub.close(); // autoDispose kicks in
      async.flushMicrotasks();
      async.elapse(Duration.zero);
      verify(() => repo.addBookMark(3, 6)).called(1);
    });
  });

  test('toggle/hide controls', () {
    final c = comic();
    final notifier = container.read(readerControllerProvider(c).notifier);
    container.listen(readerControllerProvider(c), (_, __) {});
    notifier.toggleControls();
    expect(container.read(readerControllerProvider(c)).controlsVisible, isTrue);
    notifier.hideControls();
    expect(container.read(readerControllerProvider(c)).controlsVisible, isFalse);
    notifier.hideControls();
    expect(container.read(readerControllerProvider(c)).controlsVisible, isFalse);
  });

  test('setMode updates state and persists comicType; same mode is a no-op',
      () async {
    final c = comic();
    final notifier = container.read(readerControllerProvider(c).notifier);
    container.listen(readerControllerProvider(c), (_, __) {});

    notifier.setMode(ReadingMode.vertical);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(readerControllerProvider(c)).mode,
        ReadingMode.vertical);
    verify(() => repo.updateComicMetadata(
          id: 3,
          title: null,
          author: null,
          genre: null,
          collection: null,
          comicType: 'Webtoon',
        )).called(1);

    notifier.setMode(ReadingMode.vertical);
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => repo.updateComicMetadata(
          id: any(named: 'id'),
          comicType: any(named: 'comicType'),
        ));
  });

  test('a failing save does not throw into the reader', () {
    fakeAsync((async) {
      when(() => repo.addBookMark(any(), any()))
          .thenAnswer((_) => Future.error(Exception('disk full')));
      final c = comic();
      final notifier = container.read(readerControllerProvider(c).notifier);
      container.listen(readerControllerProvider(c), (_, __) {});
      notifier.onPageChanged(2, totalPages: 10);
      async.elapse(ReaderController.persistDelay * 2);
      verify(() => repo.addBookMark(3, 2)).called(1);
    });
  });
}
