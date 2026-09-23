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
