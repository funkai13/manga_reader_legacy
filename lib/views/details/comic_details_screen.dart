import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/neo_button.dart';
import '../../core/widgets/neo_card.dart';
import '../../feature/Reader/presenter/screens/comic_viewer_screen.dart';
import '../../models/comic.dart';
import '../../models/reading_mode.dart';
import '../../services/database/comic_database.dart';
import '../../viewmodels/home_viewmodel.dart';

class ComicDetailsScreen extends ConsumerStatefulWidget {
  final Comic comic;

  const ComicDetailsScreen({super.key, required this.comic});

  @override
  ConsumerState<ComicDetailsScreen> createState() => _ComicDetailsScreenState();
}

class _ComicDetailsScreenState extends ConsumerState<ComicDetailsScreen> {
  late Comic _comic;

  @override
  void initState() {
    super.initState();
    _comic = widget.comic;
  }

  Future<void> _updateReadingMode(ReadingMode mode) async {
    setState(() {
      _comic = _comic.copyWith(comicType: mode);
    });
    await ComicDatabase.instance.updateComic(_comic);
    ref.read(homeViewModelProvider.notifier).loadComics();
  }

  void _openReader() {
    ref.read(homeViewModelProvider.notifier).setActive(_comic);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComicViewerScreen(comic: _comic.toEntity()),
      ),
    ).then((_) {
      ref.read(homeViewModelProvider.notifier).loadComics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coverPath = _comic.picture;

    final volumeText = _comic.volume != null && _comic.volume!.isNotEmpty
        ? 'T.${_comic.volume}'
        : 'T.01';

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : NeoColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'FICHA TÉCNICA',
          style: AppTypography.heading(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            NeoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover
                  Container(
                    width: 105,
                    height: 155,
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.surfaceDeep : Colors.grey[200],
                      border: Border.all(
                        color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.ink,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: coverPath != null && File(coverPath).existsSync()
                        ? Image.file(File(coverPath), fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.menu_book, size: 40)),
                  ),
                  const SizedBox(width: 14),

                  // Metadata Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NeoColors.terracotta,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                volumeText,
                                style: AppTypography.mono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: NeoColors.ink,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                _comic.fileExtension,
                                style: AppTypography.mono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _comic.title,
                          style: AppTypography.heading(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _comic.author ?? 'Autor no especificado',
                          style: AppTypography.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NeoColors.terracotta,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _comic.genre ?? 'Manga / Historieta',
                          style: AppTypography.body(
                            fontSize: 12,
                            color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'PÁG. ${_comic.currentPage + 1} DE ${_comic.totalPages} (${_comic.progressPercent}%)',
                          style: AppTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Editorial Notes Callout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sticky_note_2_outlined, size: 16, color: NeoColors.terracotta),
                      const SizedBox(width: 6),
                      Text(
                        'NOTE // DETALLES EDITORIALES',
                        style: AppTypography.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _comic.summary != null && _comic.summary!.isNotEmpty
                        ? _comic.summary!
                        : 'Archivo importado directamente desde el almacenamiento local. Listo para leer con renderizado optimizado por ventanas activas y rotación nativa.',
                    style: AppTypography.body(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Specs Grid
            Text(
              'ESPECIFICACIONES DEL ARCHIVO',
              style: AppTypography.heading(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSpecBox('FORMATO', _comic.fileExtension, isDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSpecBox('PÁGINAS', '${_comic.totalPages}', isDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSpecBox(
                    'TAMAÑO',
                    _comic.formattedFileSize.isNotEmpty ? _comic.formattedFileSize : 'Local',
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSpecBox('ESTADO', _comic.isCompleted ? 'COMPLETADO' : 'EN CURSO', isDark),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reading Mode Switcher
            Text(
              'MODO DE LECTURA',
              style: AppTypography.heading(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: ReadingMode.values.map((mode) {
                final isSelected = _comic.comicType == mode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => _updateReadingMode(mode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : NeoColors.ink)
                              : (isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm),
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
                            mode.label.split(' ').first,
                            style: AppTypography.mono(
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
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Read Now Button
            SizedBox(
              width: double.infinity,
              child: NeoButton(
                text: _comic.currentPage > 0
                    ? 'CONTINUAR EN PÁGINA ${_comic.currentPage + 1} ➔'
                    : 'ABRIR EN EL VISOR ➔',
                backgroundColor: NeoColors.terracotta,
                foregroundColor: Colors.white,
                fontSize: 14,
                onPressed: _openReader,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.heading(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
