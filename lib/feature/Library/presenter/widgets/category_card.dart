import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
// Keeping import per user request
import 'package:google_fonts/google_fonts.dart';

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
    
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final cardColor = isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF);
    final shadowColor = isDark ? const Color(0xFF000000) : const Color(0xFF1A1A2E);
    final accentColor = const Color(0xFFFFE156);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8.r * scale),
            border: Border.all(
              color: borderColor,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (category.coverPath != null)
                FileThumbnail(
                  category.coverPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: cardColor,
                    child: Icon(
                      Icons.image_not_supported,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                Container(
                  color: cardColor,
                  child: Icon(
                    Icons.category,
                    size: 48.sp * scale,
                    color: textColor.withValues(alpha: 0.2),
                  ),
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(12.w * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp * scale,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h * scale),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4), // Cyan badge
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        '${category.count} cómics',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp * scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Badge
              if (onEdit != null)
                Positioned(
                  top: 8.h * scale,
                  right: 8.w * scale,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.all(8.w * scale),
                      decoration: BoxDecoration(
                        color: accentColor,
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
                        size: 16.sp * scale,
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
}
