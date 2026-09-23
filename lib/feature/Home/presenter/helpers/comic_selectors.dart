import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';

/// "Recientemente Agregados": newest imported first. `lastOpened` is really the
/// import date and gets rewritten when reading, so it mirrored "Continuar
/// Leyendo"; the autoincrement id is a stable proxy for import order.
final lastAddedComicsProvider = Provider<List<ComicEntity>>((ref) {
  final comics = ref.watch(comicControllerProvider).value ?? [];
  final sorted = [...comics]..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  return sorted.take(6).toList();
});

final readingNowComicsProvider = Provider<List<ComicEntity>>((ref) {
  final comics = ref.watch(comicControllerProvider).value ?? [];

  return comics.where((c) {
    return c.isReading && !c.isCompleted;
  }).toList();
});

final unreadComicsProvider = Provider<List<ComicEntity>>((ref) {
  final comics = ref.watch(comicControllerProvider).value ?? [];

  return comics.where((c) {
    return c.currentReadPage == 0 && !c.isReading && !c.isCompleted;
  }).toList();
});
