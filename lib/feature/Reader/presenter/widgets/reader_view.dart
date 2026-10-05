import 'package:flutter/widgets.dart';

/// Navigation shared by the paged and the vertical reader, so the screen
/// (slider, thumbnails, tap zones) doesn't care which one is showing.
abstract class ReaderViewState<T extends StatefulWidget> extends State<T> {
  void jumpToPage(int page);
  void nextPage();
  void previousPage();
}

/// Precaches the pages around [page] so turning pages doesn't flash.
void precacheAround(
  BuildContext context,
  int page,
  int count,
  ImageProvider Function(int index) imageFor,
) {
  for (final i in [page + 1, page - 1, page + 2]) {
    if (i >= 0 && i < count) {
      precacheImage(imageFor(i), context, onError: (_, __) {});
    }
  }
}

/// Evicts pages outside the [keepRadius] window around [page] to prevent
/// memory ballooning in long comics (100+ pages).
void evictFarPages(
  int page,
  int count,
  ImageProvider Function(int index) imageFor, {
  int keepRadius = 4,
}) {
  for (var i = 0; i < count; i++) {
    if ((i - page).abs() > keepRadius) {
      imageFor(i).evict();
    }
  }
}

/// Evicts all pages from the image cache and clears live images on reader exit.
void evictAllPages(
  int count,
  ImageProvider Function(int index) imageFor,
) {
  for (var i = 0; i < count; i++) {
    imageFor(i).evict();
  }
  PaintingBinding.instance.imageCache.clearLiveImages();
}
