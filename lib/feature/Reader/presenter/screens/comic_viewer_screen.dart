import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/widgets/neo_button.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';
import 'package:path/path.dart' as p;

import '../reader_controller.dart';
import '../widgets/paged_reader.dart';
import '../widgets/reader_chrome.dart';
import '../widgets/reader_view.dart';
import '../widgets/vertical_reader.dart';

/// Full-screen reader.
///
/// Taps: left/right edge turn pages (mirrored in manga mode), top/bottom
/// edge scroll in vertical mode, the center shows the controls. Progress is saved automatically.
class ComicViewerScreen extends ConsumerStatefulWidget {
  const ComicViewerScreen({super.key, required this.comic});

  final ComicEntity comic;

  @override
  ConsumerState<ComicViewerScreen> createState() => _ComicViewerScreenState();
}

class _ComicViewerScreenState extends ConsumerState<ComicViewerScreen> {
  final _readerKey = GlobalKey<ReaderViewState>();

  static const _edgeFraction = 0.3;

  ComicEntity get comic => widget.comic;

  ReaderController get _controller =>
      ref.read(readerControllerProvider(comic).notifier);

  String get _title {
    final ext = p.extension(comic.title).toLowerCase();
    return ext == '.cbz' || ext == '.cbr'
        ? p.basenameWithoutExtension(comic.title)
        : comic.title;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _close() {
    _controller.flush();
    Navigator.of(context).maybePop();
  }

  void _onTapUp(TapUpDetails details, ReaderState state) {
    if (state.controlsVisible) {
      _controller.hideControls();
      return;
    }
    final size = MediaQuery.sizeOf(context);
    final reader = _readerKey.currentState;
    if (state.mode == ReadingMode.vertical) {
      final dy = details.globalPosition.dy;
      if (dy < size.height * _edgeFraction) return reader?.previousPage();
      if (dy > size.height * (1 - _edgeFraction)) return reader?.nextPage();
    } else {
      final dx = details.globalPosition.dx;
      final left = dx < size.width * _edgeFraction;
      final right = dx > size.width * (1 - _edgeFraction);
      if (left || right) {
        // In manga mode the next page is on the left.
        final forward = state.mode == ReadingMode.rightToLeft ? left : right;
        return forward ? reader?.nextPage() : reader?.previousPage();
      }
    }
    _controller.toggleControls();
  }

  Future<void> _openPages(List<File> pages, int page) async {
    final selected = await showPageThumbnailsSheet(context,
        pages: pages, currentPage: page);
    if (selected != null) _readerKey.currentState?.jumpToPage(selected);
  }

  Future<void> _openModes(ReadingMode mode) async {
    final selected = await showReadingModeSheet(context, mode);
    if (selected != null) _controller.setMode(selected);
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(readerPagesProvider(comic));
    final state = ref.watch(readerControllerProvider(comic));

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _controller.flush();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101113),
        body: pagesAsync.when(
          loading: () => const Center(
            child: NeoLoadingIndicator(size: 48),
          ),
          error: (error, _) => _ReaderMessage(
            icon: Icons.error_outline,
            message: 'No se pudieron cargar las páginas.\n$error',
            onBack: _close,
          ),
          data: (pages) => pages.isEmpty
              ? _ReaderMessage(
                  icon: Icons.image_not_supported_outlined,
                  message: 'Este cómic no tiene páginas disponibles.',
                  onBack: _close,
                )
              : _buildReader(pages, state),
        ),
      ),
    );
  }

  Widget _buildReader(List<File> pages, ReaderState state) {
    final page = state.page.clamp(0, pages.length - 1);
    final endPage = ReaderEndPage(
      title: _title,
      totalPages: pages.length,
      onClose: _close,
      onRestart: () => _readerKey.currentState?.jumpToPage(0),
    );
    void onPageChanged(int index) =>
        _controller.onPageChanged(index, totalPages: pages.length);

    final reader = state.mode == ReadingMode.vertical
        ? VerticalReader(
            key: _readerKey,
            pages: pages,
            initialPage: page,
            endPage: endPage,
            onPageChanged: onPageChanged,
          )
        : PagedReader(
            key: _readerKey,
            pages: pages,
            initialPage: page,
            rightToLeft: state.mode == ReadingMode.rightToLeft,
            endPage: endPage,
            onPageChanged: onPageChanged,
          );

    const duration = Duration(milliseconds: 200);
    final visible = state.controlsVisible;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _onTapUp(details, state),
            child: reader,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: visible ? 0 : 1,
              duration: duration,
              child: Center(
                child: ReaderPageIndicator(
                  page: page,
                  totalPages: pages.length,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _SlideIn(
            visible: visible,
            fromTop: true,
            child: ReaderTopBar(
              title: _title,
              subtitle: 'P. ${(page + 1).toString().padLeft(3, '0')} / ${pages.length.toString().padLeft(3, '0')}',
              mode: state.mode,
              onBack: _close,
              onOpenPages: () => _openPages(pages, page),
              onOpenModes: () => _openModes(state.mode),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _SlideIn(
            visible: visible,
            fromTop: false,
            child: ReaderBottomBar(
              pages: pages,
              page: page,
              rightToLeft: state.mode == ReadingMode.rightToLeft,
              onJumpToPage: (target) =>
                  _readerKey.currentState?.jumpToPage(target),
            ),
          ),
        ),
      ],
    );
  }
}

/// Slides a bar in from its edge; hidden bars don't take touches.
class _SlideIn extends StatelessWidget {
  const _SlideIn({
    required this.visible,
    required this.fromTop,
    required this.child,
  });

  final bool visible;
  final bool fromTop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : Offset(0, fromTop ? -1 : 1),
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          child: child,
        ),
      ),
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({
    required this.icon,
    required this.message,
    required this.onBack,
  });

  final IconData icon;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ReaderColors.textMuted, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: ReaderColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            NeoButton(
              text: 'VOLVER',
              backgroundColor: AppColorsLight.terracotta,
              foregroundColor: Colors.white,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
