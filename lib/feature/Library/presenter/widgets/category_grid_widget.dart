import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Library/presenter/controller/library_controller.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_card.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/rename_category_dialog.dart';

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
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final cardColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return state.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: NeoConstants.shadowOffset,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                'No hay elementos en esta categoría',
                style: AppTypography.heading(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
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
            crossAxisSpacing: 14.w * scale,
            mainAxisSpacing: 14.h * scale,
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
      loading: () => Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColorsLight.terracotta,
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: NeoErrorWidget(
          message: 'Error: $error',
          onRetry: () => ref.refresh(libraryControllerProvider(type)),
        ),
      ),
    );
  }
}
