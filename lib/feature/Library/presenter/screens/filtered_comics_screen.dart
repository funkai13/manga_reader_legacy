import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_provider.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/comic_grid_widget.dart';

/// Comics of one category. autoDispose so a list reopened later (e.g. after
/// a rename) is always read fresh from the DB.
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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: asyncComics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (comics) => ComicGridWidget(comics: comics, scale: scale),
      ),
    );
  }
}
