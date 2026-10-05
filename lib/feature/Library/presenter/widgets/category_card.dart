import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';

class CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final double scale;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.onEdit,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final cardColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius * scale),
            border: Border.all(
              color: borderColor,
              width: NeoConstants.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: NeoConstants.shadowOffset,
                blurRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Cover
              if (category.coverPath != null)
                FileThumbnail(
                  category.coverPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceDeep,
                    child: Icon(
                      Icons.image_not_supported,
                      color: textColor.withValues(alpha: 0.3),
                      size: 36.sp * scale,
                    ),
                  ),
                )
              else
                Container(
                  color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceDeep,
                  child: Icon(
                    Icons.category,
                    size: 44.sp * scale,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                ),

              // Ink Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark ? const Color(0xFF161719) : const Color(0xFF121316))
                          .withValues(alpha: 0.92),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),

              // Title and count badge
              Padding(
                padding: EdgeInsets.all(10.w * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.heading(
                        fontSize: 14.sp * scale,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h * scale),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w * scale,
                        vertical: 3.h * scale,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsLight.indigo,
                        borderRadius: BorderRadius.circular(2.r),
                        border: Border.all(color: Colors.black54, width: 1),
                      ),
                      child: Text(
                        '${category.count} cómics',
                        style: AppTypography.mono(
                          fontSize: 10.sp * scale,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Action Badge
              if (onEdit != null)
                Positioned(
                  top: 7.h * scale,
                  right: 7.w * scale,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.all(6.w * scale),
                      decoration: BoxDecoration(
                        color: AppColorsLight.terracotta,
                        borderRadius: BorderRadius.circular(2.r),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 13.sp * scale,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
