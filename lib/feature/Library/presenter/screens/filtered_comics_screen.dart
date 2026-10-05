import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_provider.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/comic_grid_widget.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart';

final filteredComicsProvider = FutureProvider.autoDispose
    .family<List<ComicEntity>, ({String type, String value})>((ref, arg) async {
  final repository = ref.read(comicRepositoryProvider);
  switch (arg.type) {
    case 'author':
      return await repository.getComicsByAuthor(arg.value);
    case 'genre':
      return await repository.getComicsByGenre(arg.value);
    case 'collection':
      return await repository.getComicsByCollection(arg.value);
    default:
      return [];
  }
});

class FilteredComicsScreen extends ConsumerWidget {
  final String title;
  final String type; // 'author', 'genre', 'collection'
  final String value;

  const FilteredComicsScreen({
    super.key,
    required this.title,
    required this.type,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComics = ref.watch(filteredComicsProvider((type: type, value: value)));
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final scale = isTablet ? 0.8 : 1.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B9D), // Hot pink
        elevation: 0,
        shape: Border(bottom: BorderSide(color: borderColor, width: 3)),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A2E), // Hard black text for pink background
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: asyncComics.when(
        loading: () => const NeoLoadingIndicator(),
        error: (error, stack) => NeoErrorWidget(error: error.toString()),
        data: (comics) => ComicGridWidget(comics: comics, scale: scale),
      ),
    );
  }
}
