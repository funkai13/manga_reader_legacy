import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';

/// Colors of the reader UI; always deep Night Inking palette for immersive reading.
abstract final class ReaderColors {
  static const bar = Color(0xF2161719); // 95% Night Inking Base
  static const surface = Color(0xFF212328);
  static const surfaceDeep = Color(0xFF2A2D35);
  static const border = Color(0xFF383B44);
  static const text = Color(0xFFE8E6E1);
  static const textMuted = Color(0xFF9DA1AA);
  static const accent = AppColorsDark.terracotta;
  static const indigo = AppColorsDark.indigo;
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
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: ReaderColors.bar,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(color: ReaderColors.border, width: NeoConstants.borderWidth),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: NeoConstants.shadowOffset,
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back, color: ReaderColors.text, size: 22),
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading(
                      color: ReaderColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.mono(
                      color: ReaderColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: ReaderColors.surfaceDeep,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(color: ReaderColors.border, width: 1.5),
              ),
              child: IconButton(
                tooltip: 'Modo de lectura: ${mode.label}',
                icon: Icon(readingModeIcon(mode), color: ReaderColors.accent, size: 18),
                onPressed: onOpenModes,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: ReaderColors.surfaceDeep,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(color: ReaderColors.border, width: 1.5),
              ),
              child: IconButton(
                tooltip: 'Ver páginas',
                icon: const Icon(Icons.grid_view_rounded, color: ReaderColors.text, size: 18),
                onPressed: onOpenPages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page slider with a thumbnail preview of the target page while dragging.
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

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: ReaderColors.bar,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(color: ReaderColors.border, width: NeoConstants.borderWidth),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: NeoConstants.shadowOffset,
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_dragValue != null)
              _PagePreview(file: widget.pages[shown], page: shown),
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
                              inactiveTrackColor: ReaderColors.surfaceDeep,
                              thumbColor: ReaderColors.text,
                              overlayColor: ReaderColors.accent.withValues(alpha: 0.2),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                      : const SizedBox(height: 36),
                ),
                _PageNumber(widget.rightToLeft ? '${shown + 1}' : '$total'),
              ],
            ),
          ],
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
        style: AppTypography.mono(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ReaderColors.text,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
              border: Border.all(color: ReaderColors.border, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: FileThumbnail(file.path, width: 80, height: 115),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Página ${page + 1}',
            style: AppTypography.mono(
              color: ReaderColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE6161719),
        borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
        border: Border.all(color: ReaderColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(1.5, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        '${page + 1} / $totalPages',
        style: AppTypography.mono(
          color: ReaderColors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
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
      color: const Color(0xFF161719),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorsLight.terracotta,
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  border: Border.all(color: ReaderColors.border, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(3, 3)),
                  ],
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Terminaste!',
                style: AppTypography.heading(
                  color: ReaderColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: ReaderColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalPages páginas',
                style: AppTypography.mono(
                  color: ReaderColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLight.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                    side: const BorderSide(color: ReaderColors.border, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: onClose,
                icon: const Icon(Icons.library_books),
                label: const Text('Volver a la biblioteca'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay, color: ReaderColors.textMuted),
                label: const Text(
                  'Leer desde el inicio',
                  style: TextStyle(color: ReaderColors.textMuted),
                ),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(NeoConstants.borderRadius)),
      side: const BorderSide(color: ReaderColors.border, width: NeoConstants.borderWidth),
    ),
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                'Modo de lectura',
                style: AppTypography.heading(
                  color: ReaderColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final mode in ReadingMode.values)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  border: Border.all(
                    color: mode == current ? ReaderColors.accent : ReaderColors.border,
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: mode == current ? ReaderColors.surfaceDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  child: ListTile(
                    leading: Icon(
                      readingModeIcon(mode),
                      color: mode == current ? ReaderColors.accent : ReaderColors.textMuted,
                    ),
                    title: Text(
                      mode.label,
                      style: AppTypography.heading(
                        color: ReaderColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      mode.description,
                      style: AppTypography.body(color: ReaderColors.textMuted, fontSize: 12),
                    ),
                    trailing: mode == current
                        ? const Icon(Icons.check, color: ReaderColors.accent)
                        : null,
                    onTap: () => Navigator.of(context).pop(mode),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(NeoConstants.borderRadius)),
      side: const BorderSide(color: ReaderColors.border, width: NeoConstants.borderWidth),
    ),
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
  static const _spacing = 10.0;
  static const _padding = 14.0;

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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(
                  color: current ? ReaderColors.accent : ReaderColors.border,
                  width: current ? 2.5 : 1.5,
                ),
                boxShadow: current
                    ? const [
                        BoxShadow(
                          color: ReaderColors.accent,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FileThumbnail(widget.pages[index].path, fit: BoxFit.cover),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: current ? ReaderColors.accent : Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.mono(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
