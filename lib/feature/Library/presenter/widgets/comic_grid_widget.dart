import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (comics.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B9D), // Hot pink
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: borderColor,
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            'No hay cómics para mostrar',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E), // Dark text on pink
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w * scale),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7, // Matches 3/4 aspect ratio roughly with spacing
        crossAxisSpacing: 16.w * scale,
        mainAxisSpacing: 16.h * scale,
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
