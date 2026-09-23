import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';

/// Colors of the reader UI; the reader is always dark, whatever the app theme.
abstract final class ReaderColors {
  static const bar = Color(0xE6121214);
  static const surface = Color(0xFF1C1C1E);
  static const text = Colors.white;
  static const textMuted = Color(0xB3FFFFFF);
  static const accent = AppColorsDark.accentColor;
}

IconData readingModeIcon(ReadingMode mode) => switch (mode) {
      ReadingMode.rightToLeft => Icons.format_textdirection_r_to_l,
      ReadingMode.leftToRight => Icons.format_textdirection_l_to_r,
      ReadingMode.vertical => Icons.swap_vert,
    };

class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.onBack,
    required this.onOpenPages,
    required this.onOpenModes,
  });

  final String title;
  final String subtitle;
  final ReadingMode mode;
  final VoidCallback onBack;
  final VoidCallback onOpenPages;
  final VoidCallback onOpenModes;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReaderColors.bar,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back, color: ReaderColors.text),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ReaderColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: ReaderColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Modo de lectura: ${mode.label}',
                icon: Icon(readingModeIcon(mode), color: ReaderColors.text),
                onPressed: onOpenModes,
              ),
              IconButton(
                tooltip: 'Ver páginas',
                icon: const Icon(Icons.grid_view_rounded,
                    color: ReaderColors.text),
                onPressed: onOpenPages,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page slider with a thumbnail preview of the target page while dragging.
/// In right-to-left mode the slider runs right-to-left too.
class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    super.key,
    required this.pages,
    required this.page,
    required this.rightToLeft,
    required this.onJumpToPage,
  });

  final List<File> pages;
  final int page;
  final bool rightToLeft;
  final ValueChanged<int> onJumpToPage;

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final total = widget.pages.length;
    final shown = (_dragValue?.round() ?? widget.page).clamp(0, total - 1);

    return Material(
      color: ReaderColors.bar,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_dragValue != null) _PagePreview(file: widget.pages[shown], page: shown),
              Row(
                children: [
                  _PageNumber(widget.rightToLeft ? '$total' : '${shown + 1}'),
                  Expanded(
                    child: total > 1
                        ? Directionality(
                            textDirection: widget.rightToLeft
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: ReaderColors.accent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: ReaderColors.text,
                                overlayColor: Colors.white12,
                              ),
                              child: Slider(
                                min: 0,
                                max: (total - 1).toDouble(),
                                value: (_dragValue ?? widget.page.toDouble())
                                    .clamp(0, (total - 1).toDouble()),
                                onChanged: (value) =>
                                    setState(() => _dragValue = value),
                                onChangeEnd: (value) {
                                  setState(() => _dragValue = null);
                                  widget.onJumpToPage(value.round());
                                },
                              ),
                            ),
                          )
                        : const SizedBox(height: 48),
                  ),
                  _PageNumber(widget.rightToLeft ? '${shown + 1}' : '$total'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ReaderColors.text,
          fontSize: 13,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.file, required this.page});

  final File file;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: FileThumbnail(file.path, width: 84, height: 120),
          ),
          const SizedBox(height: 4),
          Text('Página ${page + 1}',
              style: const TextStyle(color: ReaderColors.text, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Small "12 / 180" pill shown while the controls are hidden.
class ReaderPageIndicator extends StatelessWidget {
  const ReaderPageIndicator({
    super.key,
    required this.page,
    required this.totalPages,
  });

  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '${page + 1} / $totalPages',
          style: const TextStyle(
            color: ReaderColors.textMuted,
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Shown after the last page.
class ReaderEndPage extends StatelessWidget {
  const ReaderEndPage({
    super.key,
    required this.title,
    required this.totalPages,
    required this.onClose,
    required this.onRestart,
  });

  final String title;
  final int totalPages;
  final VoidCallback onClose;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: ReaderColors.accent, size: 56),
              const SizedBox(height: 16),
              const Text(
                '¡Terminaste!',
                style: TextStyle(
                  color: ReaderColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: ReaderColors.textMuted, fontSize: 15),
              ),
              Text(
                '$totalPages páginas',
                style:
                    const TextStyle(color: ReaderColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.library_books),
                label: const Text('Volver a la biblioteca'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay, color: ReaderColors.textMuted),
                label: const Text('Leer desde el inicio',
                    style: TextStyle(color: ReaderColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to pick the reading mode.
Future<ReadingMode?> showReadingModeSheet(
  BuildContext context,
  ReadingMode current,
) {
  return showModalBottomSheet<ReadingMode>(
    context: context,
    backgroundColor: ReaderColors.surface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Modo de lectura',
              style: TextStyle(
                color: ReaderColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final mode in ReadingMode.values)
            ListTile(
              leading: Icon(readingModeIcon(mode),
                  color: mode == current
                      ? ReaderColors.accent
                      : ReaderColors.textMuted),
              title: Text(mode.label,
                  style: const TextStyle(color: ReaderColors.text)),
              subtitle: Text(mode.description,
                  style: const TextStyle(color: ReaderColors.textMuted)),
              trailing: mode == current
                  ? const Icon(Icons.check, color: ReaderColors.accent)
                  : null,
              onTap: () => Navigator.of(context).pop(mode),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Bottom sheet with every page as a thumbnail, scrolled to the current one.
Future<int?> showPageThumbnailsSheet(
  BuildContext context, {
  required List<File> pages,
  required int currentPage,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ReaderColors.surface,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.75,
      child: _PageThumbnailsGrid(pages: pages, currentPage: currentPage),
    ),
  );
}

class _PageThumbnailsGrid extends StatefulWidget {
  const _PageThumbnailsGrid({required this.pages, required this.currentPage});

  final List<File> pages;
  final int currentPage;

  @override
  State<_PageThumbnailsGrid> createState() => _PageThumbnailsGridState();
}

class _PageThumbnailsGridState extends State<_PageThumbnailsGrid> {
  static const _maxTileWidth = 110.0;
  static const _aspectRatio = 0.7;
  static const _spacing = 8.0;
  static const _padding = 12.0;

  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth - _padding * 2;
      final columns = (width / _maxTileWidth).ceil().clamp(1, 12);
      final tileWidth = (width - _spacing * (columns - 1)) / columns;
      final rowHeight = tileWidth / _aspectRatio + _spacing;
      _scroll ??= ScrollController(
        // One row above the current page stays visible for context.
        initialScrollOffset: ((widget.currentPage ~/ columns) - 1)
            .clamp(0, widget.pages.length)
            .toDouble() *
            rowHeight,
      );

      return GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(_padding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: _aspectRatio,
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
        ),
        itemCount: widget.pages.length,
        itemBuilder: (context, index) {
          final current = index == widget.currentPage;
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: FileThumbnail(widget.pages[index].path),
                ),
                if (current)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: ReaderColors.accent, width: 3),
                    ),
                  ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: current ? ReaderColors.accent : Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            color: ReaderColors.text, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
