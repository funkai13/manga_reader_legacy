import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../models/comic.dart';

class ActiveReadingCard extends StatelessWidget {
  final Comic comic;
  final VoidCallback onContinueReading;
  final VoidCallback? onTapDetails;

  const ActiveReadingCard({
    super.key,
    required this.comic,
    required this.onContinueReading,
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final volumeText = comic.volume != null && comic.volume!.isNotEmpty
        ? 'T.${comic.volume}'
        : 'T.${(comic.currentPage ~/ 20) + 1}'.padLeft(4, '0');

    final authorText = (comic.author != null && comic.author!.isNotEmpty)
        ? comic.author!.toUpperCase()
        : 'AUTOR DESCONOCIDO';

    final genreText = (comic.genre != null && comic.genre!.isNotEmpty)
        ? comic.genre!.toUpperCase()
        : 'MANGA / HISTORIETA';

    final coverPath = comic.picture;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section sub-header with mono badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: NeoColors.terracotta,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LECTURA EN CURSO',
                  style: AppTypography.heading(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                border: Border.all(
                  color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VIÑETA ACTIVA',
                style: AppTypography.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: NeoColors.terracotta,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Showcase Card
        NeoCard(
          padding: const EdgeInsets.all(14),
          onTap: onTapDetails,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comic Cover Thumbnail
                  Stack(
                    children: [
                      Container(
                        width: 95,
                        height: 135,
                        decoration: BoxDecoration(
                          color: isDark ? AppColorsDark.surfaceDeep : Colors.grey[200],
                          border: Border.all(
                            color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: NeoColors.ink,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: coverPath != null && File(coverPath).existsSync()
                            ? Image.file(
                                File(coverPath),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  Icons.menu_book,
                                  size: 36,
                                  color: isDark
                                      ? AppColorsDark.textSecondary
                                      : AppColorsLight.textSecondary,
                                ),
                              ),
                      ),
                      // Format pill
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
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
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Metadata Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Volume & Format tag
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NeoColors.terracotta,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                volumeText,
                                style: AppTypography.mono(
                                  fontSize: 10,
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
                                  color: isDark
                                      ? AppColorsDark.textSecondary
                                      : AppColorsLight.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          comic.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Author & Genre
                        Text(
                          authorText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: NeoColors.terracotta,
                          ),
                        ),
                        Text(
                          genreText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 11,
                            color: isDark
                                ? AppColorsDark.textSecondary
                                : AppColorsLight.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PÁGINA ${comic.currentPage + 1} DE ${comic.totalPages > 0 ? comic.totalPages : 1}',
                        style: AppTypography.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
                  const SizedBox(height: 6),

                  // Progress Bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: comic.progress.clamp(0.0, 1.0),
                      child: Container(
                        color: NeoColors.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Continue Reading Button
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  text: 'CONTINUAR LECTURA ➔',
                  backgroundColor: NeoColors.terracotta,
                  foregroundColor: Colors.white,
                  fontSize: 13,
                  onPressed: onContinueReading,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
