import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_provider.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/comic_grid_widget.dart';

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
    final bgColor = isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: borderColor, width: NeoConstants.borderWidth)),
        title: Text(
          title,
          style: AppTypography.heading(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncComics.when(
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
            onRetry: () => ref.refresh(filteredComicsProvider((type: type, value: value))),
          ),
        ),
        data: (comics) => ComicGridWidget(comics: comics, scale: scale),
      ),
    );
  }
}
