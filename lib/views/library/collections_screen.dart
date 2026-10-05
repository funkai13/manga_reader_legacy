import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/neo_card.dart';
import '../../core/widgets/neo_loading.dart';
import '../../models/comic.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../details/comic_details_screen.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryViewModelProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(libraryViewModelProvider.notifier).loadCategories(),
          color: NeoColors.terracotta,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'COLECCIONES & SAGAS',
                  style: AppTypography.heading(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AGRUPACIONES POR SERIE Y UNIVERSO',
                  style: AppTypography.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Category Tabs
                Row(
                  children: [
                    _buildTab(context, ref, 'Colecciones', 'collections', state.activeTab, isDark),
                    const SizedBox(width: 8),
                    _buildTab(context, ref, 'Autores', 'authors', state.activeTab, isDark),
                    const SizedBox(width: 8),
                    _buildTab(context, ref, 'Géneros', 'genres', state.activeTab, isDark),
                  ],
                ),
                const SizedBox(height: 18),

                // Content
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: NeoLoadingIndicator(size: 36),
                    ),
                  )
                else
                  _buildCategoryGrid(context, ref, state, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    String label,
    String key,
    String activeKey,
    bool isDark,
  ) {
    final isSelected = key == activeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(libraryViewModelProvider.notifier).setActiveTab(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : NeoColors.ink)
                : (isDark ? AppColorsDark.surfaceColor : NeoColors.surfaceWarm),
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            border: Border.all(
              color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
              width: 2.0,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: NeoColors.ink,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.heading(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? AppColorsDark.textColor : NeoColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    WidgetRef ref,
    LibraryState state,
    bool isDark,
  ) {
    final List<Map<String, dynamic>> items;
    switch (state.activeTab) {
      case 'authors':
        items = state.authors;
        break;
      case 'genres':
        items = state.genres;
        break;
      case 'collections':
      default:
        items = state.collections;
        break;
    }

    if (items.isEmpty) {
      return NeoCard(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.collections_bookmark_outlined, size: 38, color: NeoColors.terracotta),
              const SizedBox(height: 12),
              Text(
                'SIN AGRUPACIONES DISPONIBLES',
                style: AppTypography.heading(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Los cómics con metadatos de serie o autor se organizarán automáticamente aquí.',
                textAlign: TextAlign.center,
                style: AppTypography.body(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name'] as String? ?? 'Sin nombre';
        final count = item['count'] as int? ?? 0;
        final coverPath = item['coverPath'] as String?;

        return _buildFannedCollectionCard(context, ref, name, count, coverPath, isDark);
      },
    );
  }

  Widget _buildFannedCollectionCard(
    BuildContext context,
    WidgetRef ref,
    String name,
    int count,
    String? coverPath,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () async {
        final comics =
            await ref.read(libraryViewModelProvider.notifier).getComicsForCollection(name);
        if (context.mounted && comics.isNotEmpty) {
          _showCollectionDetailsModal(context, name, comics);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.surfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(
            color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.ink,
              offset: Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fanned out cover stack
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back page tilt right
                  Transform.rotate(
                    angle: 0.08,
                    child: Container(
                      width: 78,
                      height: 105,
                      decoration: BoxDecoration(
                        color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: NeoColors.ink, width: 1.5),
                      ),
                    ),
                  ),
                  // Middle page tilt left
                  Transform.rotate(
                    angle: -0.06,
                    child: Container(
                      width: 80,
                      height: 108,
                      decoration: BoxDecoration(
                        color: isDark ? AppColorsDark.surfaceDeep : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: NeoColors.ink, width: 1.5),
                      ),
                    ),
                  ),
                  // Front Cover
                  Container(
                    width: 85,
                    height: 115,
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.surfaceDeep : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: NeoColors.ink, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.ink,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: coverPath != null && File(coverPath).existsSync()
                        ? Image.file(File(coverPath), fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.collections_bookmark, size: 30)),
                  ),

                  // Count badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: NeoColors.terracotta,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '$count TOMOS',
                        style: AppTypography.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Collection Name & Info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                    width: 2.0,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SAGA COMPLETA',
                    style: AppTypography.mono(
                      fontSize: 9,
                      color: NeoColors.terracotta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionDetailsModal(
    BuildContext context,
    String title,
    List<Comic> comics,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
              width: 2.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: AppTypography.heading(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                '${comics.length} TOMOS EN ESTA COLECCIÓN',
                style: AppTypography.mono(fontSize: 11, color: NeoColors.terracotta),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: comics.length,
                  itemBuilder: (cContext, idx) {
                    final c = comics[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 45,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: NeoColors.ink, width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: c.picture != null && File(c.picture!).existsSync()
                            ? Image.file(File(c.picture!), fit: BoxFit.cover)
                            : const Icon(Icons.menu_book, size: 20),
                      ),
                      title: Text(c.title, style: AppTypography.heading(fontSize: 14)),
                      subtitle: Text(
                        'Pág. ${c.currentPage + 1}/${c.totalPages} — ${c.progressPercent}%',
                        style: AppTypography.mono(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ComicDetailsScreen(comic: c),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
