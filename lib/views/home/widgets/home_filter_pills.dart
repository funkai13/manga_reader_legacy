import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/constants.dart';

class FilterPillItem {
  final String key;
  final String label;
  final int count;

  const FilterPillItem({
    required this.key,
    required this.label,
    required this.count,
  });
}

class HomeFilterPills extends StatelessWidget {
  final String selectedFilter;
  final int allCount;
  final int cbzCount;
  final int cbrCount;
  final int readingCount;
  final int completedCount;
  final ValueChanged<String> onSelectFilter;

  const HomeFilterPills({
    super.key,
    required this.selectedFilter,
    required this.allCount,
    required this.cbzCount,
    required this.cbrCount,
    required this.readingCount,
    required this.completedCount,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      FilterPillItem(key: 'all', label: 'Todos', count: allCount),
      FilterPillItem(key: 'cbz', label: 'CBZ', count: cbzCount),
      FilterPillItem(key: 'cbr', label: 'CBR', count: cbrCount),
      FilterPillItem(key: 'reading', label: 'En curso', count: readingCount),
      FilterPillItem(key: 'completed', label: 'Completados', count: completedCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          final isSelected = selectedFilter == item.key;
          final borderColor = isDark ? AppColorsDark.borderColor : NeoColors.ink;
          final selectedBg = isDark ? AppColorsDark.primaryColor : NeoColors.ink;
          final selectedFg = isDark ? AppColorsDark.backgroundColor : Colors.white;
          final unselectedBg = isDark ? AppColorsDark.surfaceColor : NeoColors.surfaceWarm;
          final unselectedFg = isDark ? AppColorsDark.textColor : NeoColors.ink;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelectFilter(item.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : unselectedBg,
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  border: Border.all(
                    color: borderColor,
                    width: 2.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor,
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: AppTypography.heading(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? selectedFg : unselectedFg,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.25))
                            : (isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceDeep),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.count}',
                        style: AppTypography.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? selectedFg : unselectedFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
