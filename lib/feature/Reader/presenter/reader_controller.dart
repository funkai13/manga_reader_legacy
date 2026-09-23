import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/data/services/comic_archive_extractor.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:path/path.dart' as p;

/// The page files of a comic, in reading order. Disposed with the reader.
final readerPagesProvider =
    FutureProvider.autoDispose.family<List<File>, ComicEntity>(
  (ref, comic) async {
    final pages = await Directory(comic.imagesPath)
        .list()
        .where((entity) =>
            entity is File &&
            comicPageExtensions.contains(p.extension(entity.path).toLowerCase()))
        .cast<File>()
        .toList();
    // Directory order is unspecified (ext4/F2FS on Android isn't
    // alphabetical); pages are stored as zero-padded 0001.ext names.
    pages.sort((a, b) => p
        .basename(a.path)
        .toLowerCase()
        .compareTo(p.basename(b.path).toLowerCase()));
    return pages;
  },
);

@immutable
class ReaderState {
  final int page;
  final ReadingMode mode;
  final bool controlsVisible;

  const ReaderState({
    required this.page,
    required this.mode,
    this.controlsVisible = false,
  });

  ReaderState copyWith({int? page, ReadingMode? mode, bool? controlsVisible}) =>
      ReaderState(
        page: page ?? this.page,
        mode: mode ?? this.mode,
        controlsVisible: controlsVisible ?? this.controlsVisible,
      );
}

/// Reader UI state for one comic: current page, reading mode and whether the
/// controls are shown. Reading progress is saved after the user stops
/// turning pages and when the reader closes.
class ReaderController extends Notifier<ReaderState> {
  ReaderController(this.comic);

  final ComicEntity comic;

  static const persistDelay = Duration(milliseconds: 800);

  late ComicController _library;
  Timer? _persistTimer;
  int? _pendingPage;
  int _totalPages = 0;

  @override
  ReaderState build() {
    // Kept so progress can still be saved from onDispose, where ref can no
    // longer be used. The library notifier lives for the whole app.
    _library = ref.read(comicControllerProvider.notifier);
    ref.onDispose(() {
      _persistTimer?.cancel();
      // Providers can't be touched during disposal; save right after.
      if (_pendingPage != null) Future.microtask(_persist);
    });

    if (!comic.isReading) {
      unawaited(_library
          .markAsReading(comic.id!)
          .catchError((Object e) => debugPrint('markAsReading failed: $e')));
    }

    return ReaderState(
      page: comic.currentReadPage < 0 ? 0 : comic.currentReadPage,
      mode: ReadingMode.fromComicType(comic.comicType),
    );
  }

  /// Called by the page views whenever the visible page changes.
  void onPageChanged(int page, {required int totalPages}) {
    _totalPages = totalPages;
    if (page == state.page && _pendingPage == null) return;
    state = state.copyWith(page: page);
    _pendingPage = page;
    _persistTimer?.cancel();
    _persistTimer = Timer(persistDelay, _persist);
  }

  /// Saves any pending progress now (e.g. before leaving the reader).
  void flush() {
    _persistTimer?.cancel();
    _persist();
  }

  void _persist() {
    final page = _pendingPage;
    if (page == null) return;
    _pendingPage = null;
    _library
        .updateReadingProgress(comic.id!, page, totalPages: _totalPages)
        .catchError((Object e) => debugPrint('Saving progress failed: $e'));
  }

  void toggleControls() =>
      state = state.copyWith(controlsVisible: !state.controlsVisible);

  void hideControls() {
    if (state.controlsVisible) state = state.copyWith(controlsVisible: false);
  }

  void setMode(ReadingMode mode) {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    unawaited(_library
        .updateComicMetadata(id: comic.id!, comicType: mode.comicType)
        .catchError((Object e) => debugPrint('Saving reading mode failed: $e')));
  }
}

final readerControllerProvider = NotifierProvider.autoDispose
    .family<ReaderController, ReaderState, ComicEntity>(ReaderController.new);
