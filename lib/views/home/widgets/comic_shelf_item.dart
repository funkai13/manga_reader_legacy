import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/constants.dart';
import '../../../models/comic.dart';

class ComicShelfItem extends StatelessWidget {
  final Comic comic;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;

  const ComicShelfItem({
    super.key,
    required this.comic,
    required this.onTap,
    this.onLongPress,
    this.isGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGridCard(context) : _buildListTile(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : NeoColors.ink;
    final cardBg = isDark ? AppColorsDark.surfaceColor : Colors.white;
    final coverPath = comic.picture;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(color: borderColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor,
              offset: const Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverPath != null && File(coverPath).existsSync()
                      ? Image.file(
                          File(coverPath),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                          child: Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 38,
                              color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                            ),
                          ),
                        ),

                  // Format Badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: NeoColors.ink,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        comic.fileExtension,
                        style: AppTypography.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Completed Badge
                  if (comic.isCompleted)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E8E5A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'LEÍDO',
                          style: AppTypography.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Progress bar
            Container(
              height: 4,
              width: double.infinity,
              color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: comic.progress.clamp(0.0, 1.0),
                child: Container(
                  color: comic.isCompleted ? const Color(0xFF3E8E5A) : NeoColors.terracotta,
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          comic.author != null && comic.author!.isNotEmpty
                              ? comic.author!
                              : (comic.genre ?? 'Manga'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 10,
                            color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${comic.currentPage + 1}/${comic.totalPages > 0 ? comic.totalPages : 1}',
                        style: AppTypography.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.terracotta,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : NeoColors.ink;
    final cardBg = isDark ? AppColorsDark.surfaceColor : Colors.white;
    final coverPath = comic.picture;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(color: borderColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor,
              offset: const Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 70,
              height: 95,
              child: coverPath != null && File(coverPath).existsSync()
                  ? Image.file(
                      File(coverPath),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                      child: const Center(child: Icon(Icons.menu_book, size: 28)),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: NeoColors.ink,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            comic.fileExtension,
                            style: AppTypography.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (comic.formattedFileSize.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            comic.formattedFileSize,
                            style: AppTypography.mono(
                              fontSize: 10,
                              color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comic.author ?? comic.genre ?? 'Desconocido',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(
                        fontSize: 11,
                        color: NeoColors.terracotta,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Página ${comic.currentPage + 1} de ${comic.totalPages}',
                          style: AppTypography.body(fontSize: 11),
                        ),
                        Text(
                          '${comic.progressPercent}%',
                          style: AppTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: NeoColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
