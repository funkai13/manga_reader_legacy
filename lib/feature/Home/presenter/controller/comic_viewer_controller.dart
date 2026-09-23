import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:path/path.dart' as p;

class ComicViewerController extends AsyncNotifier<List<File>> {
  static const _imageExtensions = {'.jpg', '.jpeg', '.png'};

  @override
  Future<List<File>> build() async => [];

  Future<void> loadComic(String imagesPath, int comicId) async {
    state = const AsyncLoading();

    try {
      await ref.read(comicControllerProvider.notifier).markAsReading(comicId);

      final dir = Directory(imagesPath);

      final images = await dir
          .list()
          .where((entity) =>
              entity is File &&
              _imageExtensions.contains(p.extension(entity.path).toLowerCase()))
          .cast<File>()
          .toList();

      // Directory listing order is unspecified (ext4/F2FS on Android is not
      // alphabetical), and pages are stored as zero-padded 0001.ext names.
      images.sort((a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()));

      state = AsyncData(images);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final comicViewerControllerProvider =
    AsyncNotifierProvider<ComicViewerController, List<File>>(
  ComicViewerController.new,
);
