import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';

import 'comic_card.dart';

class ComicsCarousel extends StatelessWidget {
  final String title;
  final List<ComicEntity> comics;
  final double scale;
  final Function(ComicEntity)? onEdit;

  const ComicsCarousel({
    required this.title,
    required this.comics,
    required this.scale,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (comics.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w * scale),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20.sp * scale,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: 12.h * scale),
        SizedBox(
          height: 240.h * scale,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w * scale),
            itemCount: comics.length,
            itemBuilder: (context, index) {
              final comic = comics[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ComicViewerScreen(comic: comic)));
                },
                child: Container(
                  margin: EdgeInsets.only(right: 12.w * scale),
                  width: 140.w * scale,
                  child: ComicCard(
                    comic: comics[index],
                    scale: scale,
                    onEdit: onEdit != null ? () => onEdit!(comic) : null,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24.h * scale),
      ],
    );
  }
}
