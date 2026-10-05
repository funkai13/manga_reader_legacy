import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Library/presenter/controller/library_controller.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/rename_category_dialog.dart';

class CategoryListWidget extends ConsumerWidget {
  final String type; // 'author', 'genre', 'collection'

  const CategoryListWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryControllerProvider(type));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final cardColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor;
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
        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: categories.length,
          separatorBuilder: (context, index) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: NeoConstants.shadowOffset,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceDeep,
                      borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Icon(
                      Icons.folder_open,
                      size: 20.sp,
                      color: textColor,
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: AppTypography.heading(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: textColor,
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColorsLight.indigo,
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5)),
                      ],
                    ),
                    child: Text(
                      category.count.toString(),
                      style: AppTypography.mono(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
