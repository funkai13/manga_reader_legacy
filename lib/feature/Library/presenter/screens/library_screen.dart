import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/core/widgets/responsive_layout.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_grid_widget.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/comic_grid_widget.dart';

class NeoLoadingIndicator extends StatelessWidget {
  const NeoLoadingIndicator({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE156),
          border: Border.all(color: const Color(0xFF1A1A2E), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1A1A2E),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A2E)),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

class NeoErrorWidget extends StatelessWidget {
  final String error;
  const NeoErrorWidget({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252),
          border: Border.all(color: const Color(0xFF1A1A2E), width: 3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1A1A2E),
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          'Error: $error',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

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

class LibraryScreenMobile extends ConsumerWidget {
  const LibraryScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComics = ref.watch(comicControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(
            'Biblioteca',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 24,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: textColor,
            unselectedLabelColor: textColor.withValues(alpha: 0.5),
            labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16),
            unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 16),
            indicatorColor: textColor,
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
              loading: () => const NeoLoadingIndicator(),
              error: (error, stack) => NeoErrorWidget(error: error.toString()),
              data: (comics) => ComicGridWidget(comics: comics, crossAxisCount: 2),
            ),
            const CategoryGridWidget(type: 'author', crossAxisCount: 2),
            const CategoryGridWidget(type: 'genre', crossAxisCount: 2),
            const CategoryGridWidget(type: 'collection', crossAxisCount: 2),
          ],
        ),
      ),
    );
  }
}

class LibraryScreenTablet extends ConsumerWidget {
  const LibraryScreenTablet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComics = ref.watch(comicControllerProvider);
    const scale = 0.8;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(
            'Biblioteca',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 28,
            ),
          ),
          bottom: TabBar(
            isScrollable: false,
            labelColor: textColor,
            unselectedLabelColor: textColor.withValues(alpha: 0.5),
            labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 18),
            unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 18),
            indicatorColor: textColor,
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
              loading: () => const NeoLoadingIndicator(),
              error: (error, stack) => NeoErrorWidget(error: error.toString()),
              data: (comics) => ComicGridWidget(
                comics: comics,
                scale: scale,
                crossAxisCount: 3,
              ),
            ),
            const CategoryGridWidget(type: 'author', crossAxisCount: 3),
            const CategoryGridWidget(type: 'genre', crossAxisCount: 3),
            const CategoryGridWidget(type: 'collection', crossAxisCount: 3),
          ],
        ),
      ),
    );
  }
}
