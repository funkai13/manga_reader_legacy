import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:manga_reader/feature/Home/presenter/screens/edit_comic_screen.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_card.dart';

class ComicGridWidget extends StatelessWidget {
  final List<ComicEntity> comics;
  final double scale;
  final int crossAxisCount;

  const ComicGridWidget({
    super.key,
    required this.comics,
    this.scale = 1.0,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (comics.isEmpty) {
      return const Center(
        child: Text('No hay cómics para mostrar'),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w * scale),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7, // Matches 3/4 aspect ratio roughly with spacing
        crossAxisSpacing: 16.w * scale,
        mainAxisSpacing: 16.h * scale,
      ),
      itemCount: comics.length,
      itemBuilder: (context, index) {
        final comic = comics[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ComicViewerScreen(comic: comic),
              ),
            );
          },
          child: ComicCard(
            comic: comic,
            scale: scale,
            onEdit: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditComicScreen(comic: comic),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
