import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/neo_loading.dart';
import '../../feature/Reader/presenter/screens/comic_viewer_screen.dart';
import '../../models/comic.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../details/comic_details_screen.dart';
import 'widgets/active_reading_card.dart';
import 'widgets/comic_search_bar.dart';
import 'widgets/home_filter_pills.dart';
import 'widgets/shelf_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pickAndImportComic(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cbz', 'cbr', 'zip', 'rar'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final imported =
            await ref.read(homeViewModelProvider.notifier).importComic(path);
        if (context.mounted) {
          if (imported != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cómic importado: ${imported.title}'),
                backgroundColor: NeoColors.ink,
              ),
            );
          } else {
            final error = ref.read(homeViewModelProvider).errorMessage;
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: NeoColors.terracotta,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: NeoColors.terracotta,
          ),
        );
      }
    }
  }

  void _openReader(BuildContext context, WidgetRef ref, Comic comic) {
    ref.read(homeViewModelProvider.notifier).setActive(comic);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComicViewerScreen(comic: comic.toEntity()),
      ),
    ).then((_) {
      ref.read(homeViewModelProvider.notifier).loadComics();
    });
  }

  void _openDetails(BuildContext context, Comic comic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComicDetailsScreen(comic: comic),
      ),
    );
  }

  void _showComicOptions(BuildContext context, WidgetRef ref, Comic comic) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColorsDark.surfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: NeoColors.ink,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        comic.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1.5, color: NeoColors.ink),
              ListTile(
                leading: const Icon(Icons.chrome_reader_mode_outlined, color: NeoColors.terracotta),
                title: Text('Leer cómic', style: AppTypography.heading(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openReader(context, ref, comic);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: NeoColors.mutedIndigo),
                title: Text('Ficha técnica / Detalles', style: AppTypography.heading(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDetails(context, comic);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Eliminar de la biblioteca',
                    style: AppTypography.heading(fontSize: 14, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: Text('¿Eliminar cómic?', style: AppTypography.heading(fontSize: 16)),
                      content: Text('Se eliminarán los archivos extraídos de "${comic.title}".',
                          style: AppTypography.body(fontSize: 13)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('CANCELAR'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(homeViewModelProvider.notifier).deleteComic(comic);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.read(homeViewModelProvider.notifier).loadComics(),
              color: NeoColors.terracotta,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'TINTA & PAPEL',
                              style: AppTypography.heading(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NeoColors.terracotta,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CBZ/CBR',
                                style: AppTypography.mono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Add Button
                        GestureDetector(
                          onTap: () => _pickAndImportComic(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                                width: 2.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: NeoColors.ink,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 16, color: NeoColors.terracotta),
                                const SizedBox(width: 4),
                                Text(
                                  'AÑADIR',
                                  style: AppTypography.heading(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Bar
                    ComicSearchBar(
                      query: state.searchQuery,
                      onChanged: (q) =>
                          ref.read(homeViewModelProvider.notifier).setSearchQuery(q),
                      onClear: () =>
                          ref.read(homeViewModelProvider.notifier).setSearchQuery(''),
                    ),
                    const SizedBox(height: 14),

                    // Filter Pills
                    HomeFilterPills(
                      selectedFilter: state.activeFilter,
                      allCount: state.allCount,
                      cbzCount: state.cbzCount,
                      cbrCount: state.cbrCount,
                      readingCount: state.readingCount,
                      completedCount: state.completedCount,
                      onSelectFilter: (filter) =>
                          ref.read(homeViewModelProvider.notifier).setFilter(filter),
                    ),
                    const SizedBox(height: 18),

                    // Active Reading Showcase
                    if (state.activeComic != null && state.searchQuery.isEmpty && state.activeFilter == 'all') ...[
                      ActiveReadingCard(
                        comic: state.activeComic!,
                        onContinueReading: () => _openReader(context, ref, state.activeComic!),
                        onTapDetails: () => _openDetails(context, state.activeComic!),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Shelf Section
                    ShelfSection(
                      comics: state.filteredComics,
                      isGridView: state.isGridView,
                      onToggleView: (isGrid) =>
                          ref.read(homeViewModelProvider.notifier).setGridView(isGrid),
                      onSelectComic: (comic) => _openReader(context, ref, comic),
                      onLongPressComic: (comic) => _showComicOptions(context, ref, comic),
                      onImportComic: () => _pickAndImportComic(context, ref),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Loading overlay during archive extraction
            if (state.isLoading)
              const Positioned.fill(
                child: NeoLoadingOverlay(
                  message: 'EXTRAYENDO ARCHIVO...',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
