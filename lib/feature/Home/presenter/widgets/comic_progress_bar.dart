import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ComicProgressBar extends StatefulWidget {
  final int currentPageIndex;
  final int totalPages;
  final bool mangaMode;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int?> onPreviewPageChanged;

  const ComicProgressBar({
    super.key,
    required this.currentPageIndex,
    required this.totalPages,
    required this.mangaMode,
    required this.onPageSelected,
    required this.onPreviewPageChanged,
  });

  @override
  State<ComicProgressBar> createState() => _ComicProgressBarState();
}

class _ComicProgressBarState extends State<ComicProgressBar> {
  int? _draggingPageIndex;

  double get _displayedProgress {
    if (widget.totalPages <= 0) return 0.0;

    final index = _draggingPageIndex ?? widget.currentPageIndex;
    return (index + 1) / widget.totalPages;
  }

  int _positionToPage(double dx, double width) {
    if (width <= 0 || widget.totalPages <= 0) {
      return widget.currentPageIndex;
    }

    final clampedDx = dx.clamp(0, width);
    final page = (clampedDx / width * widget.totalPages)
        .floor()
        .clamp(0, widget.totalPages - 1);

    return page;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalPages <= 0) {
      return SizedBox(height: 24.h);
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(widget.mangaMode ? pi : 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final page = _positionToPage(
                details.localPosition.dx,
                constraints.maxWidth,
              );

              setState(() {
                _draggingPageIndex = page;
              });

              widget.onPreviewPageChanged(page);
              widget.onPageSelected(page);
            },
            onHorizontalDragStart: (_) {
              setState(() {
                _draggingPageIndex = widget.currentPageIndex;
              });
              widget.onPreviewPageChanged(_draggingPageIndex);
            },
            onHorizontalDragUpdate: (details) {
              final page = _positionToPage(
                details.localPosition.dx,
                constraints.maxWidth,
              );
              setState(() {
                _draggingPageIndex = page;
              });
              // Only preview while dragging; jumping on every update turns
              // one drag into dozens of page changes and bookmark writes.
              widget.onPreviewPageChanged(page);
            },
            onHorizontalDragEnd: (_) {
              final page = _draggingPageIndex;
              setState(() {
                _draggingPageIndex = null;
              });
              widget.onPreviewPageChanged(null);
              if (page != null) widget.onPageSelected(page);
            },
            onHorizontalDragCancel: () {
              setState(() {
                _draggingPageIndex = null;
              });
              widget.onPreviewPageChanged(null);
            },
            child: SizedBox(
              height: 32.h,
              child: Center(
                child: SizedBox(
                  height: 20.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value: _displayedProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
