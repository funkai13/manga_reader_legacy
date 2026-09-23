import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';

final lastAddedComicsProvider = Provider<List<ComicEntity>>((ref) {
  final comics = ref.watch(comicControllerProvider).value ?? [];
  final sorted = [...comics]..sort(
      (a, b) => _parseDate(b.lastOpened).compareTo(_parseDate(a.lastOpened)));
  return sorted.take(6).toList();
});

// Legacy rows can have an empty lastOpened; sort those last instead of throwing.
DateTime _parseDate(String value) =>
    DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

final readingNowComicsProvider = Provider<List<ComicEntity>>((ref) {
  final comics = ref.watch(comicControllerProvider).value ?? [];

  return comics.where((c) {
    return c.isReading && !c.isCompleted;
  }).toList();
});

final unreadComicsProvider = Provider<List<ComicEntity>>((ref) {
  final comics = ref.watch(comicControllerProvider).value ?? [];

  return comics.where((c) {
    return c.currentReadPage == 0 && !c.isReading;
  }).toList();
});
