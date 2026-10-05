import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/helpers/comic_selectors.dart';
import 'package:manga_reader/feature/Home/presenter/helpers/import_comic_flow.dart';
import 'package:manga_reader/feature/Home/presenter/screens/edit_comic_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comics_carousel.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart';

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
  final int _selectedIndex = 0;

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

    final bgColor = isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final navBgColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: asyncComics.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const NeoLoadingIndicator(size: 48),
              SizedBox(height: 16.h),
              Text(
                'CARGANDO TOMOS...',
                style: AppTypography.mono(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: textColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: NeoErrorWidget(
            message: 'Error cargando los tomos:\n$error',
            onRetry: () => ref.refresh(comicControllerProvider.future),
          ),
        ),
        data: (comics) {
          if (comics.isEmpty) {
            return EmptyComicsScreen(
              onAddComic: () => importComicFlow(context, ref),
            );
          }

          return RefreshIndicator(
            color: AppColorsLight.terracotta,
            backgroundColor: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
            onRefresh: () async {
              return ref.refresh(comicControllerProvider.future);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHomeAppBar(context, isDark, scale, isTablet, textColor, borderColor),
                buildSearchBar(context, comics, isDark, scale, _searchController, _searchFocusNode, isTablet),
                SliverToBoxAdapter(
                  child: SizedBox(height: 12.h * scale),
                ),
                if (readingNow.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ComicsCarousel(
                      scale: scale,
                      title: 'Continuar Leyendo',
                      comics: readingNow,
                      onEdit: (comic) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditComicScreen(comic: comic),
                          ),
                        );
                      },
                    ),
                  ),
                if (lastAdded.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ComicsCarousel(
                      scale: scale,
                      title: 'Recientemente Agregados',
                      comics: lastAdded,
                      onEdit: (comic) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditComicScreen(comic: comic),
                          ),
                        );
                      },
                    ),
                  ),
                if (unread.isNotEmpty)
                  SliverToBoxAdapter(
                    child: ComicsCarousel(
                      scale: scale,
                      title: 'Sin Leer',
                      comics: unread,
                      onEdit: (comic) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditComicScreen(comic: comic),
                          ),
                        );
                      },
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            top: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColorsLight.terracotta,
          unselectedItemColor: isDark
              ? AppColorsDark.textSecondary
              : AppColorsLight.textSecondary,
          selectedLabelStyle: AppTypography.heading(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: AppTypography.heading(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LibraryScreen(),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Biblioteca',
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHomeAppBar(
    BuildContext context,
    bool isDark,
    double scale,
    bool isTablet,
    Color textColor,
    Color borderColor,
  ) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BIBLIOTECA DE TOMOS',
            style: AppTypography.heading(
              fontSize: 20.sp * scale,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          Text(
            'TANKŌBON ARCHIVE // COLECCIÓN',
            style: AppTypography.mono(
              fontSize: 10.sp * scale,
              fontWeight: FontWeight.w700,
              color: AppColorsLight.terracotta,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 18.w * scale),
          decoration: BoxDecoration(
            color: AppColorsLight.terracotta,
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
            boxShadow: [
              BoxShadow(
                color: isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor,
                offset: NeoConstants.shadowOffset,
                blurRadius: 0,
              ),
            ],
          ),
          child: Consumer(
            builder: (ctx, ref, _) {
              return IconButton(
                tooltip: 'Agregar cómic',
                onPressed: () => importComicFlow(ctx, ref),
                icon: Icon(
                  Icons.add,
                  size: 20.sp * scale,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
