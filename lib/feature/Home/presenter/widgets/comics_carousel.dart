import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final accentColor = isDark ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B9D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: accentColor, width: 4)),
                  ),
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20.sp * scale,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to list
                },
                style: TextButton.styleFrom(
                  foregroundColor: textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: textColor, width: 2),
                  ),
                  backgroundColor: isDark ? const Color(0xFF252542) : Colors.white,
                ),
                child: Text(
                  'Ver todos →',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp * scale,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h * scale),
        SizedBox(
          height: 250.h * scale,
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
                  margin: EdgeInsets.only(right: 16.w * scale, bottom: 8.h),
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
