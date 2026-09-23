import 'package:manga_reader/core/widgets/file_thumbnail.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12 * scale,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r * scale),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (comic.picture.isNotEmpty)
                FileThumbnail(
                  comic.picture,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(isDark);
                  },
                )
              else
                _buildPlaceholder(isDark),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w * scale,
                    vertical: 6.h * scale,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: _buildBottomRow(isDark),
                ),
              ),
              if (onEdit != null)
                Positioned(
                  top: 8.h * scale,
                  right: 8.w * scale,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.all(6.w * scale),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 14.sp * scale,
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

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
      child: Center(
        child: Icon(
          Icons.book,
          color: isDark
              ? AppColorsDark.textColor.withValues(alpha: 0.3)
              : AppColorsLight.textColor.withValues(alpha: 0.3),
          size: 40.sp * scale,
        ),
      ),
    );
  }

  /// Status chip on the left, "Pág. N" on the right. Both sides are
  /// Flexible and scale down instead of overflowing when the card is narrow
  /// (e.g. ComicsGrid on tablets, where .sp grows faster than the cell).
  Widget _buildBottomRow(bool isDark) {
    final chip = _buildStatusChip(isDark);
    final showPage = comic.currentReadPage > 0 && !comic.isCompleted;

    return Row(
      mainAxisAlignment:
          chip == null ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
      children: [
        if (chip != null)
          Flexible(
            // The chip gets the larger share; the page label takes the rest.
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
                  style: TextStyle(
                    fontSize: 10.sp * scale,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
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
      label = 'Completado';
      color = Colors.greenAccent.shade400;
    } else if (comic.isReading) {
      label = 'Leyendo';
      color = Colors.orangeAccent.shade400;
    } else if (comic.currentReadPage == 0) {
      label = 'Nuevo';
      color = Colors.blueAccent.shade400;
    }

    if (label == null || color == null) return null;

    if (isDark) {
      color = color.withValues(alpha: 0.9);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w * scale,
        vertical: 4.h * scale,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999.r * scale),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontSize: 10.sp * scale,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
