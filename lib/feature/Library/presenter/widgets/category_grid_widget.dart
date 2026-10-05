import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Library/presenter/controller/library_controller.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_card.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/rename_category_dialog.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart'; // To reuse NeoLoadingIndicator/NeoErrorWidget

class CategoryGridWidget extends ConsumerWidget {
  final String type; // 'author', 'genre', 'collection'
  final int crossAxisCount;

  const CategoryGridWidget({
    super.key,
    required this.type,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryControllerProvider(type));
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final scale = isTablet ? 0.8 : 1.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return state.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE156), // Hot yellow
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
                'No hay elementos en esta categoría',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
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
            childAspectRatio: 0.7, 
            crossAxisSpacing: 16.w * scale,
            mainAxisSpacing: 16.h * scale,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              category: category,
              scale: scale,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FilteredComicsScreen(
                      title: category.name,
                      type: type,
                      value: category.name,
                    ),
                  ),
                );
              },
              onEdit: () {
                showDialog(
                  context: context,
                  builder: (context) => RenameCategoryDialog(
                    currentName: category.name,
                    type: type,
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const NeoLoadingIndicator(),
      error: (error, stack) => NeoErrorWidget(error: error.toString()),
    );
  }
}
