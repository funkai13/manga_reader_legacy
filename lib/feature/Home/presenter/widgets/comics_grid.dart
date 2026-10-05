import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';

import '../../../../core/widgets/generic_grid.dart';
import 'comic_card.dart';

class ComicsGrid extends ConsumerWidget {
  const ComicsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> fetchComics() async {
      await ref.read(comicControllerProvider.notifier).getAllComics();
    }

    final asyncComics = ref.watch(comicControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;

    return asyncComics.when(
      data: (comics) => RefreshIndicator(
        onRefresh: () async {
          await fetchComics();
        },
        child: GenericGrid(
          items: comics,
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 250,
          itemBuilder: (comic) {
            return ComicCard(
              comic: comic,
              scale: 1.0,
            );
          },
        ),
      ),
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
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
      error: (error, _) => Center(
        child: NeoErrorWidget(
          message: 'ERROR:\n$error',
          onRetry: () => ref.refresh(comicControllerProvider),
        ),
      ),
    );
  }
}
