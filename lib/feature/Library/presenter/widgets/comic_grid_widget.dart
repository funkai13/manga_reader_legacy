import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final cardColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    if (comics.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: NeoConstants.shadowOffset,
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book,
                size: 40.sp,
                color: AppColorsLight.terracotta,
              ),
              SizedBox(height: 12.h),
              Text(
                'No hay cómics para mostrar',
                style: AppTypography.heading(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w * scale),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14.w * scale,
        mainAxisSpacing: 14.h * scale,
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
