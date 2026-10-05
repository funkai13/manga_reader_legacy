import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:path/path.dart' as p;

class ComicCard extends StatelessWidget {
  final ComicEntity comic;
  final double scale;
  final VoidCallback? onEdit;

  const ComicCard({
    super.key,
    required this.comic,
    required this.scale,
    this.onEdit,
  });

  String? _formatBadge() {
    final ext = p.extension(comic.title).toLowerCase();
    if (ext == '.cbz') return 'CBZ';
    if (ext == '.cbr') return 'CBR';
    if (comic.comicType != null && comic.comicType!.isNotEmpty) {
      return comic.comicType!.toUpperCase();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;
    final format = _formatBadge();

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius * scale),
          border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 0,
              offset: NeoConstants.shadowOffset,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (NeoConstants.borderRadius - NeoConstants.borderWidth).clamp(0.0, double.infinity) * scale,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover thumbnail
              if (comic.picture.isNotEmpty)
                FileThumbnail(
                  comic.picture,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(isDark, borderColor);
                  },
                )
              else
                _buildPlaceholder(isDark, borderColor),

              // Format Badge (CBZ, CBR) at top-left
              if (format != null)
                Positioned(
                  top: 6.h * scale,
                  left: 6.w * scale,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w * scale,
                      vertical: 2.h * scale,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsLight.indigo,
                      borderRadius: BorderRadius.circular(2.r * scale),
                      border: Border.all(
                        color: isDark ? AppColorsDark.borderColor : Colors.black,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      format,
                      style: AppTypography.mono(
                        fontSize: 9.sp * scale,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Edit Action Button at top-right
              if (onEdit != null)
                Positioned(
                  top: 6.h * scale,
                  right: 6.w * scale,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.all(5.w * scale),
                      decoration: BoxDecoration(
                        color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
                        borderRadius: BorderRadius.circular(2.r * scale),
                        border: Border.all(
                          color: isDark ? AppColorsDark.borderColor : Colors.black,
                          width: 1.5,
                        ),
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
                        color: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
                      ),
                    ),
                  ),
                ),

              // Bottom status & progress panel
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w * scale,
                    vertical: 7.h * scale,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF161719) : const Color(0xFF121316))
                        .withValues(alpha: 0.88),
                    border: Border(
                      top: BorderSide(
                        color: borderColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: _buildBottomRow(isDark, borderColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, Color borderColor) {
    return Container(
      color: isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
      child: Center(
        child: Icon(
          Icons.book,
          color: borderColor.withValues(alpha: 0.5),
          size: 40.sp * scale,
        ),
      ),
    );
  }

  Widget _buildBottomRow(bool isDark, Color borderColor) {
    final chip = _buildStatusChip(isDark);
    final showPage = comic.currentReadPage > 0 && !comic.isCompleted;

    return Row(
      mainAxisAlignment: chip == null ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
      children: [
        if (chip != null)
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: chip,
            ),
          ),
        if (showPage)
          Flexible(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 6.w * scale),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  'Pág. ${comic.currentReadPage + 1}',
                  maxLines: 1,
                  softWrap: false,
                  style: AppTypography.mono(
                    fontSize: 11.sp * scale,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget? _buildStatusChip(bool isDark) {
    String? label;
    Color? color;

    if (comic.isCompleted) {
      label = 'COMPLETADO';
      color = AppColorsLight.successColor;
    } else if (comic.isReading) {
      label = 'LEYENDO';
      color = AppColorsLight.terracotta;
    } else if (comic.currentReadPage == 0) {
      label = 'NUEVO';
      color = AppColorsLight.indigo;
    }

    if (label == null || color == null) return null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w * scale,
        vertical: 3.h * scale,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.r * scale),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(1.5, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AppTypography.mono(
          fontSize: 9.sp * scale,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
