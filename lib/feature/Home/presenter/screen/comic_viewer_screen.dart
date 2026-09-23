import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_page_view.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/long_press_overlay.dart';
import 'package:vibration/vibration.dart';

import '../controller/comic_viewer_controller.dart';
import '../widgets/comic_controls_overlay.dart';
import '../widgets/comic_page_grid_dialog.dart';

class ComicViewerScreen extends ConsumerStatefulWidget {
  final ComicEntity comic;

  const ComicViewerScreen({super.key, required this.comic});

  @override
  ConsumerState<ComicViewerScreen> createState() => _ComicViewerScreenState();
}

class _ComicViewerScreenState extends ConsumerState<ComicViewerScreen> {
  late final PageController _pageController;
  final Map<int, double> _pageScales = {};
  int _currentPageIndex = 0;
  int? _previewPageIndex;
  bool _showControls = false;
  bool _mangaMode = false;
  Timer? _longPressTimer;
  Timer? _persistDebounce;
  int? _pendingBookmark;
  bool _isLongPressing = false;

  static const _persistDelay = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();

    _mangaMode = widget.comic.comicType == 'Manga';
    _pageController = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadComicAndJumpToInitialPage();
    });
  }

  Future<void> _loadComicAndJumpToInitialPage() async {
    await ref
        .read(comicViewerControllerProvider.notifier)
        .loadComic(widget.comic.imagesPath, widget.comic.id!);

    if (!mounted) return;

    final images = ref.read(comicViewerControllerProvider).value ?? <File>[];

    if (images.isEmpty) return;

    final totalPages = images.length;
    final targetPage = widget.comic.currentReadPage.clamp(0, totalPages - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      _pageController.jumpToPage(targetPage);
    });
  }

  void _startLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 300), () async {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 50);
      }
      if (!mounted) return;
      setState(() {
        _isLongPressing = true;
        _showControls = true;
      });
    });
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    if (_isLongPressing) {
      setState(() => _isLongPressing = false);
    }
  }

  bool get _enablePageView => (_pageScales[_currentPageIndex] ?? 1.0) == 1.0;

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _toggleMangaMode() {
    setState(() => _mangaMode = !_mangaMode);
    ref
        .read(comicControllerProvider.notifier)
        .updateComicMetadata(
          id: widget.comic.id!,
          comicType: _mangaMode ? 'Manga' : 'Comic',
        )
        .catchError((Object e) => debugPrint('Error updating comic type: $e'));
  }

  /// Saves the reading position after the user stops turning pages, so
  /// dragging the progress bar or swiping fast doesn't write on every page.
  void _schedulePersist(int page) {
    _pendingBookmark = page;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(_persistDelay, _persistNow);
  }

  void _persistNow() {
    _persistDebounce?.cancel();
    final page = _pendingBookmark;
    if (page == null) return;
    _pendingBookmark = null;
    ref
        .read(comicControllerProvider.notifier)
        .createBookmark(widget.comic.id!, page, widget.comic)
        .catchError((Object e) {
      debugPrint('Error saving bookmark: $e');
      return '';
    });
  }

  void _toggleBookMark() {
    _pendingBookmark = _currentPageIndex;
    _persistNow();
  }

  void _goBack() {
    _toggleBookMark();
    Navigator.pop(context);
  }

  void _handleTap(TapUpDetails details, int totalPages) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;
    final tappedLeft = dx < width * 0.3;
    final tappedRight = dx > width * 0.7;

    if (!tappedLeft && !tappedRight) {
      _toggleControls();
      return;
    }

    // In manga mode the PageView is reversed, so the next page is on the left.
    final goNext = _mangaMode ? tappedLeft : tappedRight;
    if (goNext) {
      if (_currentPageIndex < totalPages - 1) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } else if (_currentPageIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _longPressTimer?.cancel();
    _persistDebounce?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comicState = ref.watch(comicViewerControllerProvider);

    final images = comicState.maybeWhen(
      data: (imgs) => imgs,
      orElse: () => <File>[],
    );
    final totalPages = images.length;
    return PopScope(
      canPop: !_showControls,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          _persistNow();
        } else if (_showControls) {
          _toggleControls();
        }
      },
      child: GestureDetector(
        onLongPressStart: (_) => _startLongPress(),
        onLongPressEnd: (_) => _endLongPress(),
        onTapUp: (details) => _handleTap(details, totalPages),
        child: Stack(
          children: [
            _buildComicViewer(comicState),
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: ComicControlsOverlay(
                  previewPageIndex: _previewPageIndex,
                  currentPageIndex: _currentPageIndex,
                  totalPages: totalPages,
                  mangaMode: _mangaMode,
                  isBookmarked:
                      widget.comic.currentReadPage == _currentPageIndex,
                  onBack: _goBack,
                  onToggleBookmark: _toggleBookMark,
                  onToggleMangaMode: _toggleMangaMode,
                  onOpenPageGrid: () => _showPageSelector(images),
                  onPageSelected: (page) {
                    _pageController.jumpToPage(page);
                  },
                  onPreviewPageChanged: (previewPage) {
                    setState(() {
                      _previewPageIndex = previewPage;
                    });
                  },
                ),
              ),
            ),
            LongPressOverlay(visible: _isLongPressing)
          ],
        ),
      ),
    );
  }

  void _showPageSelector(List<File> images) {
    if (images.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => ComicPageGridDialog(
        images: images,
        currentPageIndex: _currentPageIndex,
        mangaMode: _mangaMode,
        onPageSelected: (page) {
          Navigator.of(context).pop();
          _pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  Widget _buildComicViewer(AsyncValue<List<File>> comicState) {
    return comicState.when(
      data: (images) => ComicPageView(
        controller: _pageController,
        images: images,
        mangaMode: _mangaMode,
        enablePageScroll: _enablePageView,
        pageScales: _pageScales,
        onPageScaleChanged: (index, scale) {
          setState(() => _pageScales[index] = scale);
        },
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
            _previewPageIndex = null;
          });
          _schedulePersist(index);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
