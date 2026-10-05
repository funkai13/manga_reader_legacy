import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'reader_page.dart';
import 'reader_view.dart';

/// Continuous top-to-bottom scroll (webtoon style), pages fit to width.
///
/// Every item gets the height of the first page's aspect ratio: pages of a
/// volume are practically all the same size, and a fixed extent makes
/// jumping to any page exact without measuring every image first.
class VerticalReader extends StatefulWidget {
  const VerticalReader({
    super.key,
    required this.pages,
    required this.initialPage,
    required this.endPage,
    required this.onPageChanged,
  });

  final List<File> pages;
  final int initialPage;
  final Widget endPage;
  final ValueChanged<int> onPageChanged;

  /// Height / width used until the first page has been measured (B5 manga).
  static const defaultAspectRatio = 1.42;

  @override
  State<VerticalReader> createState() => VerticalReaderState();
}

class VerticalReaderState extends ReaderViewState<VerticalReader> {
  ScrollController? _scroll;
  double _aspectRatio = VerticalReader.defaultAspectRatio;
  double _extent = 0;
  double _viewport = 0;
  double _decodeWidth = 0;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage.clamp(0, widget.pages.length - 1);
    _measureFirstPage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _decodeWidth = readerTargetDecodeWidth(context);
  }

  ImageProvider _imageFor(int i) =>
      readerPageImageProvider(widget.pages[i], _decodeWidth);

  Future<void> _measureFirstPage() async {
    try {
      final buffer =
          await ui.ImmutableBuffer.fromFilePath(widget.pages.first.path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final ratio = descriptor.height / descriptor.width;
      descriptor.dispose();
      buffer.dispose();
      if (mounted && ratio.isFinite && ratio > 0) {
        setState(() => _aspectRatio = ratio);
        _keepCurrentPageInView();
      }
    } catch (_) {
      // Keep the default ratio.
    }
  }

  void _keepCurrentPageInView() {
    final page = _current;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) jumpToPage(page);
    });
  }

  @override
  void dispose() {
    if (_decodeWidth > 0 && widget.pages.isNotEmpty) {
      evictAllPages(widget.pages.length, _imageFor);
    }
    _scroll?.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (_extent <= 0) return false;
    final center = notification.metrics.pixels + _viewport / 2;
    final page = (center / _extent).floor().clamp(0, widget.pages.length);
    if (page != _current) {
      _current = page;
      widget.onPageChanged(page.clamp(0, widget.pages.length - 1));
      if (_decodeWidth > 0 && widget.pages.isNotEmpty) {
        precacheAround(context, page, widget.pages.length, _imageFor);
        evictFarPages(page, widget.pages.length, _imageFor);
      }
    }
    return false;
  }

  @override
  void jumpToPage(int page) {
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients) return;
    scroll.jumpTo((page * _extent).clamp(0, scroll.position.maxScrollExtent));
  }

  void _scrollBy(double delta) {
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients) return;
    final target = (scroll.offset + delta)
        .clamp(0.0, scroll.position.maxScrollExtent);
    scroll.animateTo(target,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void nextPage() => _scrollBy(_viewport * 0.85);

  @override
  void previousPage() => _scrollBy(-_viewport * 0.85);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final extent = constraints.maxWidth * _aspectRatio;
      _viewport = constraints.maxHeight;
      if (_scroll == null) {
        _scroll = ScrollController(initialScrollOffset: _current * extent);
      } else if (extent != _extent && _extent > 0) {
        _keepCurrentPageInView(); // rotation or measured ratio
      }
      _extent = extent;

      return NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
          controller: _scroll,
          itemExtent: extent,
          scrollCacheExtent: ScrollCacheExtent.pixels(extent * 2),
          itemCount: widget.pages.length + 1, // + end page
          itemBuilder: (context, index) {
            if (index == widget.pages.length) return widget.endPage;
            return Image(
              key: ValueKey(widget.pages[index].path),
              image: _decodeWidth > 0
                  ? _imageFor(index)
                  : readerPageImage(context, widget.pages[index]),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.white54, size: 48),
              ),
            );
          },
        ),
      );
    });
  }
}
