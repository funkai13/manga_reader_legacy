import 'dart:io';

import 'package:flutter/material.dart';

import 'reader_page.dart';
import 'reader_view.dart';

/// Page-by-page reader (manga right-to-left or comic left-to-right), with a
/// final "you finished" page after the last one.
class PagedReader extends StatefulWidget {
  const PagedReader({
    super.key,
    required this.pages,
    required this.initialPage,
    required this.rightToLeft,
    required this.endPage,
    required this.onPageChanged,
  });

  final List<File> pages;
  final int initialPage;
  final bool rightToLeft;
  final Widget endPage;

  /// Reports the visible page; the end page reports the last real page.
  final ValueChanged<int> onPageChanged;

  @override
  State<PagedReader> createState() => PagedReaderState();
}

class PagedReaderState extends ReaderViewState<PagedReader> {
  late final PageController _controller;
  late int _current;
  bool _zoomed = false;
  bool _precachedInitial = false;
  double _decodeWidth = 0;

  int get _itemCount => widget.pages.length + 1; // + end page

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage.clamp(0, widget.pages.length - 1);
    _controller = PageController(initialPage: _current);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _decodeWidth = readerTargetDecodeWidth(context);
    if (!_precachedInitial) {
      _precachedInitial = true;
      _precache(_current);
    }
  }

  ImageProvider _imageFor(int i) =>
      readerPageImageProvider(widget.pages[i], _decodeWidth);

  @override
  void dispose() {
    if (_decodeWidth > 0 && widget.pages.isNotEmpty) {
      evictAllPages(widget.pages.length, _imageFor);
    }
    _controller.dispose();
    super.dispose();
  }

  void _precache(int page) {
    if (_decodeWidth <= 0 || widget.pages.isEmpty) return;
    precacheAround(context, page, widget.pages.length, _imageFor);
    evictFarPages(page, widget.pages.length, _imageFor);
  }

  void _onPageChanged(int index) {
    setState(() {
      _current = index;
      _zoomed = false;
    });
    widget.onPageChanged(index.clamp(0, widget.pages.length - 1));
    _precache(index);
  }

  @override
  void jumpToPage(int page) {
    if (_controller.hasClients) _controller.jumpToPage(page);
  }

  @override
  void nextPage() {
    if (_current < _itemCount - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  void previousPage() {
    if (_current > 0) {
      _controller.previousPage(
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      reverse: widget.rightToLeft,
      // Keeps the neighbour pages built so swipes start instantly.
      allowImplicitScrolling: true,
      // A zoomed page pans instead of turning.
      physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
      itemCount: _itemCount,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        if (index == widget.pages.length) return widget.endPage;
        return ReaderPage(
          key: ValueKey(widget.pages[index].path),
          file: widget.pages[index],
          targetWidth: _decodeWidth,
          active: index == _current,
          onZoomChanged: (zoomed) {
            if (index == _current && zoomed != _zoomed) {
              setState(() => _zoomed = zoomed);
            }
          },
        );
      },
    );
  }
}
