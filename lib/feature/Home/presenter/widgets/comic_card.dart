import 'package:manga_reader/core/widgets/file_thumbnail.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final cardColor = isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8.r * scale),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((8 - 2.5).r * scale),
          child: Stack(
            fit: StackFit.expand,
            children: [
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w * scale,
                    vertical: 8.h * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    border: Border(
                      top: BorderSide(color: borderColor, width: 2.5),
                    ),
                  ),
                  child: _buildBottomRow(isDark, borderColor),
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
                        color: isDark ? const Color(0xFFFF6B9D) : const Color(0xFFFFE156),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 14.sp * scale,
                        color: Colors.black,
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

  Widget _buildPlaceholder(bool isDark, Color borderColor) {
    return Container(
      color: isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF),
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
    final chip = _buildStatusChip(isDark, borderColor);
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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp * scale,
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

  Widget? _buildStatusChip(bool isDark, Color borderColor) {
    String? label;
    Color? color;

    if (comic.isCompleted) {
      label = 'Completado';
      color = const Color(0xFFA8E86C);
    } else if (comic.isReading) {
      label = 'Leyendo';
      color = const Color(0xFFFF9F43);
    } else if (comic.currentReadPage == 0) {
      label = 'Nuevo';
      color = const Color(0xFF4ECDC4);
    }

    if (label == null || color == null) return null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w * scale,
        vertical: 4.h * scale,
      ),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4.r * scale),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        softWrap: false,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10.sp * scale,
          color: Colors.black,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
