import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/core/widgets/responsive_layout.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_grid_widget.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_list_widget.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/comic_grid_widget.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: LibraryScreenMobile(),
      tabletBody: LibraryScreenTablet(),
    );
  }
}

class LibraryScreenMobile extends ConsumerStatefulWidget {
  const LibraryScreenMobile({super.key});

  @override
  ConsumerState<LibraryScreenMobile> createState() => _LibraryScreenMobileState();
}

class _LibraryScreenMobileState extends ConsumerState<LibraryScreenMobile> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final asyncComics = ref.watch(comicControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final surfaceColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          shape: Border(
            bottom: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
          ),
          title: Text(
            'Biblioteca',
            style: AppTypography.heading(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 22,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: IconButton(
                tooltip: _isGrid ? 'Cambiar a lista' : 'Cambiar a cuadrícula',
                icon: Icon(
                  _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: textColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _isGrid = !_isGrid);
                },
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColorsLight.terracotta,
            unselectedLabelColor: isDark
                ? AppColorsDark.textSecondary
                : AppColorsLight.textSecondary,
            labelStyle: AppTypography.heading(fontWeight: FontWeight.w800, fontSize: 14),
            unselectedLabelStyle: AppTypography.heading(fontWeight: FontWeight.w600, fontSize: 14),
            indicatorColor: AppColorsLight.terracotta,
            indicatorWeight: 3.5,
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Autores'),
              Tab(text: 'Géneros'),
              Tab(text: 'Colecciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            asyncComics.when(
              loading: () => Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColorsLight.terracotta,
                    borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                    border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ),
              ),
              error: (error, stack) => Center(
                child: NeoErrorWidget(
                  message: 'Error: $error',
                  onRetry: () => ref.refresh(comicControllerProvider),
                ),
              ),
              data: (comics) => ComicGridWidget(comics: comics, crossAxisCount: 2),
            ),
            _isGrid
                ? const CategoryGridWidget(type: 'author', crossAxisCount: 2)
                : const CategoryListWidget(type: 'author'),
            _isGrid
                ? const CategoryGridWidget(type: 'genre', crossAxisCount: 2)
                : const CategoryListWidget(type: 'genre'),
            _isGrid
                ? const CategoryGridWidget(type: 'collection', crossAxisCount: 2)
                : const CategoryListWidget(type: 'collection'),
          ],
        ),
      ),
    );
  }
}

class LibraryScreenTablet extends ConsumerStatefulWidget {
  const LibraryScreenTablet({super.key});

  @override
  ConsumerState<LibraryScreenTablet> createState() => _LibraryScreenTabletState();
}

class _LibraryScreenTabletState extends ConsumerState<LibraryScreenTablet> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final asyncComics = ref.watch(comicControllerProvider);
    const scale = 0.8;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final surfaceColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          shape: Border(
            bottom: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
          ),
          title: Text(
            'Biblioteca',
            style: AppTypography.heading(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 26,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: IconButton(
                tooltip: _isGrid ? 'Cambiar a lista' : 'Cambiar a cuadrícula',
                icon: Icon(
                  _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: textColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() => _isGrid = !_isGrid);
                },
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: false,
            labelColor: AppColorsLight.terracotta,
            unselectedLabelColor: isDark
                ? AppColorsDark.textSecondary
                : AppColorsLight.textSecondary,
            labelStyle: AppTypography.heading(fontWeight: FontWeight.w800, fontSize: 16),
            unselectedLabelStyle: AppTypography.heading(fontWeight: FontWeight.w600, fontSize: 16),
            indicatorColor: AppColorsLight.terracotta,
            indicatorWeight: 4,
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Autores'),
              Tab(text: 'Géneros'),
              Tab(text: 'Colecciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            asyncComics.when(
              loading: () => Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColorsLight.terracotta,
                    borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                    border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ),
              ),
              error: (error, stack) => Center(
                child: NeoErrorWidget(
                  message: 'Error: $error',
                  onRetry: () => ref.refresh(comicControllerProvider),
                ),
              ),
              data: (comics) => ComicGridWidget(
                comics: comics,
                scale: scale,
                crossAxisCount: 3,
              ),
            ),
            _isGrid
                ? const CategoryGridWidget(type: 'author', crossAxisCount: 3)
                : const CategoryListWidget(type: 'author'),
            _isGrid
                ? const CategoryGridWidget(type: 'genre', crossAxisCount: 3)
                : const CategoryListWidget(type: 'genre'),
            _isGrid
                ? const CategoryGridWidget(type: 'collection', crossAxisCount: 3)
                : const CategoryListWidget(type: 'collection'),
          ],
        ),
      ),
    );
  }
}
