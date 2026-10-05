import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';

import 'comic_card.dart';

class ComicsCarousel extends StatelessWidget {
  final String title;
  final List<ComicEntity> comics;
  final double scale;
  final Function(ComicEntity)? onEdit;
  final VoidCallback? onSeeAll;

  const ComicsCarousel({
    required this.title,
    required this.comics,
    required this.scale,
    this.onEdit,
    this.onSeeAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (comics.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final accentColor = isDark ? AppColorsDark.terracotta : AppColorsLight.terracotta;
    final surfaceColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 4.w * scale,
                      height: 18.h * scale,
                      margin: EdgeInsets.only(right: 8.w * scale),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading(
                          fontSize: 16.sp * scale,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onSeeAll != null) ...[
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w * scale,
                      vertical: 5.h * scale,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor,
                          offset: const Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'VER TODOS →',
                      style: AppTypography.mono(
                        fontSize: 10.sp * scale,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 14.h * scale),
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
                      builder: (_) => ComicViewerScreen(comic: comic),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(right: 14.w * scale, bottom: 6.h),
                  width: 140.w * scale,
                  child: ComicCard(
                    comic: comic,
                    scale: scale,
                    onEdit: onEdit != null ? () => onEdit!(comic) : null,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 18.h * scale),
      ],
    );
  }
}
