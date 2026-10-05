import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/feature/Library/presenter/controller/library_controller.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/rename_category_dialog.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart';

class CategoryListWidget extends ConsumerWidget {
  final String type; // 'author', 'genre', 'collection'

  const CategoryListWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryControllerProvider(type));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final cardColor = isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF);

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
        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: categories.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor, width: 2.5),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: borderColor,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  title: Text(
                    category.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: textColor,
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4), // Cyan
                      border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1A1A2E),
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      category.count.toString(),
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
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
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => RenameCategoryDialog(
                        currentName: category.name,
                        type: type,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const NeoLoadingIndicator(),
      error: (error, stack) => NeoErrorWidget(error: error.toString()),
    );
  }
}
