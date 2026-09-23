import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/helpers/comic_selectors.dart';
import 'package:manga_reader/feature/Home/presenter/helpers/import_comic_flow.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comics_carousel.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart';

import '../../../../core/theme/colors.dart';
import '../widgets/emtpy_comics_screen.dart';
import '../widgets/search_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = SearchController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncComics = ref.watch(comicControllerProvider);
    final readingNow = ref.watch(readingNowComicsProvider);
    final lastAdded = ref.watch(lastAddedComicsProvider);
    final unread = ref.watch(unreadComicsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final scale = isTablet ? 0.8 : 1.0;
    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundColor
          : AppColorsLight.backgroundColor,
      body: asyncComics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error cargando comics',
            style: TextStyle(
              color:
                  isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
            ),
          ),
        ),
        data: (comics) {
          if (comics.isEmpty) {
            return EmptyComicsScreen(
              onAddComic: () => importComicFlow(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(comicControllerProvider.future);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHomeAppBar(context, isDark, scale, isTablet),
                buildSearchBar(context, comics, isDark, scale, _searchController,
                    _searchFocusNode, isTablet),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24.h * scale),
                ),
                if (readingNow.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ComicsCarousel(
                      scale: scale,
                      title: 'Continuar Leyendo',
                      comics: readingNow,
                    ),
                  ),
                if (lastAdded.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ComicsCarousel(
                      scale: scale,
                      title: 'Recientemente Agregados',
                      comics: lastAdded,
                    ),
                  ),
                if (unread.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ComicsCarousel(
                      scale: scale,
                      title: 'Sin Leer',
                      comics: unread,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24.h * scale),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

SliverAppBar _buildHomeAppBar(
    BuildContext context, bool isDark, double scale, bool isTablet) {
  return SliverAppBar(
    floating: true,
    snap: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    title: Text(
      'Bienvenido',
      style: TextStyle(
        fontSize: 22.sp * scale,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
      ),
    ),
    actions: [
      Container(
        margin: EdgeInsets.only(right: 16.w * scale),
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8 * scale,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LibraryScreen(),
              ),
            );
          },
          icon: Icon(
            Icons.library_books,
            size: 16.sp * scale,
            color:
                isDark ? AppColorsDark.accentColor : AppColorsLight.accentColor,
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.only(right: 16.w * scale),
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8 * scale,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Consumer(
          builder: (ctx, ref, _) {
            return IconButton(
              onPressed: () => importComicFlow(ctx, ref),
              icon: Icon(
                Icons.add,
                size: 16.sp * scale,
                color: isDark
                    ? AppColorsDark.accentColor
                    : AppColorsLight.accentColor,
              ),
            );
          },
        ),
      ),
    ],
  );
}
