import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../models/comic.dart';
import 'comic_shelf_item.dart';

class ShelfSection extends StatelessWidget {
  final List<Comic> comics;
  final bool isGridView;
  final ValueChanged<bool> onToggleView;
  final ValueChanged<Comic> onSelectComic;
  final ValueChanged<Comic>? onLongPressComic;
  final VoidCallback onImportComic;

  const ShelfSection({
    super.key,
    required this.comics,
    required this.isGridView,
    required this.onToggleView,
    required this.onSelectComic,
    required this.onImportComic,
    this.onLongPressComic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelf Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'TU ESTANTERÍA',
                  style: AppTypography.heading(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '[${comics.length} ARCHIVOS]',
                    style: AppTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColorsDark.textColor : NeoColors.ink,
                    ),
                  ),
                ),
              ],
            ),

            // Toggle Grid / List
            GestureDetector(
              onTap: () => onToggleView(!isGridView),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColorsDark.surfaceColor : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  size: 18,
                  color: isDark ? AppColorsDark.textColor : NeoColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Shelf Content
        if (comics.isEmpty)
          _buildEmptyShelf(context, isDark)
        else if (isGridView)
          _buildGridView(context)
        else
          _buildListView(context),
      ],
    );
  }

  Widget _buildEmptyShelf(BuildContext context, bool isDark) {
    return NeoCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.auto_stories_outlined,
                size: 40,
                color: NeoColors.terracotta,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ESTANTERÍA VACÍA',
              style: AppTypography.heading(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No hay cómics en esta vista. Importa archivos CBZ o CBR desde tu dispositivo.',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            NeoButton(
              text: '+ IMPORTAR ARCHIVO CBZ/CBR',
              backgroundColor: NeoColors.terracotta,
              foregroundColor: Colors.white,
              onPressed: onImportComic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: comics.length,
      itemBuilder: (context, index) {
        final comic = comics[index];
        return ComicShelfItem(
          comic: comic,
          isGrid: true,
          onTap: () => onSelectComic(comic),
          onLongPress: onLongPressComic != null ? () => onLongPressComic!(comic) : null,
        );
      },
    );
  }

  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comics.length,
      itemBuilder: (context, index) {
        final comic = comics[index];
        return ComicShelfItem(
          comic: comic,
          isGrid: false,
          onTap: () => onSelectComic(comic),
          onLongPress: onLongPressComic != null ? () => onLongPressComic!(comic) : null,
        );
      },
    );
  }
}
