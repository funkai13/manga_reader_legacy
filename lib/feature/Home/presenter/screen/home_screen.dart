import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/helpers/comic_selectors.dart';
import 'package:manga_reader/feature/Home/presenter/helpers/import_comic_flow.dart';
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 19) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
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

    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      body: asyncComics.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFFFE156) : const Color(0xFF4ECDC4),
                  border: Border.all(color: borderColor, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 3,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Cargando...',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            margin: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error cargando comics',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => ref.refresh(comicControllerProvider.future),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text('Reintentar', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                )
              ],
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
                _buildHomeAppBar(context, isDark, scale, isTablet, textColor, borderColor),
                buildSearchBar(context, comics, isDark, scale, _searchController, _searchFocusNode, isTablet),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF),
          border: Border(top: BorderSide(color: borderColor, width: 3)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: isDark ? const Color(0xFFFFE156) : const Color(0xFFFF6B9D),
          unselectedItemColor: textColor.withValues(alpha: 0.5),
          selectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
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
      BuildContext context, bool isDark, double scale, bool isTablet, Color textColor, Color borderColor) {
    final greeting = _getGreeting();
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        greeting,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 24.sp * scale,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16.w * scale),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF4ECDC4) : const Color(0xFFFFE156),
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Consumer(
            builder: (ctx, ref, _) {
              return IconButton(
                onPressed: () => importComicFlow(ctx, ref),
                icon: Icon(
                  Icons.add,
                  size: 20.sp * scale,
                  color: Colors.black,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
