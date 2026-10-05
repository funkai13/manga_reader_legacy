import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/core/widgets/neo_button.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/custom_autocomplete_field.dart';
import 'package:path/path.dart' as p;

class EditComicScreen extends ConsumerStatefulWidget {
  final ComicEntity comic;

  const EditComicScreen({super.key, required this.comic});

  @override
  ConsumerState<EditComicScreen> createState() => _EditComicScreenState();
}

class _EditComicScreenState extends ConsumerState<EditComicScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _genreController;
  late TextEditingController _collectionController;
  String? _comicType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.comic.title);
    _authorController = TextEditingController(text: widget.comic.author ?? '');
    _genreController = TextEditingController(text: widget.comic.genre ?? '');
    _collectionController =
        TextEditingController(text: widget.comic.collection ?? '');
    _comicType = widget.comic.comicType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _collectionController.dispose();
    super.dispose();
  }

  String? _formatBadge() {
    final ext = p.extension(widget.comic.title).toLowerCase();
    if (ext == '.cbz') return 'CBZ';
    if (ext == '.cbr') return 'CBR';
    return null;
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showNeoSnackBar(context, 'El título no puede estar vacío', isError: true);
      return;
    }

    await ref.read(comicControllerProvider.notifier).updateComicMetadata(
          id: widget.comic.id!,
          author: _authorController.text.trim(),
          genre: _genreController.text.trim(),
          collection: _collectionController.text.trim(),
          comicType:
              _comicType != widget.comic.comicType ? _comicType : null,
          title: _titleController.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      showNeoSnackBar(context, 'Tomo actualizado correctamente');
    }
  }

  Future<void> _deleteComic() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor,
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            border: Border.all(
              color: isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor,
              width: NeoConstants.borderWidth,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorsLight.errorColor,
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                '¿ELIMINAR TOMO?',
                style: AppTypography.heading(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta acción eliminará el tomo y sus datos de lectura de la aplicación.',
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 13,
                  color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NeoOutlinedButton(
                    text: 'CANCELAR',
                    fontSize: 12,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  const SizedBox(width: 10),
                  NeoButton(
                    text: 'ELIMINAR',
                    backgroundColor: AppColorsLight.errorColor,
                    foregroundColor: Colors.white,
                    fontSize: 12,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(comicControllerProvider.notifier).deleteComic(widget.comic.id!);
      if (mounted) {
        Navigator.pop(context);
        showNeoSnackBar(context, 'Tomo eliminado');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final scale = isTablet ? 0.8 : 1.0;

    final bgColor = isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final format = _formatBadge();

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.h * scale,
            pinned: true,
            backgroundColor: isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.comic.picture.isNotEmpty)
                    FileThumbnail(widget.comic.picture, width: 120, fit: BoxFit.cover)
                  else
                    Container(color: bgColor),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: (isDark ? const Color(0xFF161719) : const Color(0xFF121316))
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 200.h * scale,
                          width: 145.w * scale,
                          decoration: BoxDecoration(
                            color: isDark ? AppColorsDark.surfaceDeep : Colors.white,
                            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                            border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 0,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: widget.comic.picture.isNotEmpty
                                ? FileThumbnail(widget.comic.picture, fit: BoxFit.cover)
                                : Container(
                                    color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceDeep,
                                    child: Icon(
                                      Icons.auto_stories,
                                      size: 48.sp * scale,
                                      color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                        if (format != null)
                          Positioned(
                            top: -8.h * scale,
                            left: -8.w * scale,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w * scale,
                                vertical: 3.h * scale,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorsLight.indigo,
                                borderRadius: BorderRadius.circular(2.r),
                                border: Border.all(color: Colors.black, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black45, offset: Offset(2, 2)),
                                ],
                              ),
                              child: Text(
                                format,
                                style: AppTypography.mono(
                                  fontSize: 11.sp * scale,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(8.w * scale),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8.w * scale),
                decoration: BoxDecoration(
                  color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: IconButton(
                  tooltip: 'Eliminar tomo',
                  icon: const Icon(Icons.delete_outline, color: AppColorsLight.errorColor, size: 20),
                  onPressed: _deleteComic,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 8.w * scale, bottom: 8.w * scale, right: 12.w * scale),
                decoration: BoxDecoration(
                  color: AppColorsLight.terracotta,
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, offset: Offset(2, 2)),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Guardar cambios',
                  icon: const Icon(Icons.save, color: Colors.white, size: 20),
                  onPressed: _save,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FICHA TÉCNICA',
                        style: AppTypography.heading(
                          fontSize: 22.sp * scale,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w * scale, vertical: 3.h * scale),
                        decoration: BoxDecoration(
                          color: AppColorsLight.terracotta.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2.r),
                          border: Border.all(color: AppColorsLight.terracotta, width: 1),
                        ),
                        child: Text(
                          'P. ${widget.comic.currentReadPage + 1}',
                          style: AppTypography.mono(
                            fontSize: 11.sp * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColorsLight.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h * scale),

                  // Narration Note Box ("NOTE //")
                  Container(
                    padding: EdgeInsets.all(14.w * scale),
                    decoration: BoxDecoration(
                      color: isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor,
                      border: Border(
                        left: const BorderSide(color: AppColorsLight.terracotta, width: 4),
                        top: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
                        right: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
                        bottom: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTE // DETALLES EDITORIALES',
                          style: AppTypography.mono(
                            fontSize: 11.sp * scale,
                            fontWeight: FontWeight.w800,
                            color: AppColorsLight.terracotta,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 6.h * scale),
                        Text(
                          'Los cambios en los metadatos se reflejan de inmediato en tus colecciones, filtros y fichas de lectura.',
                          style: AppTypography.body(
                            fontSize: 12.sp * scale,
                            color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h * scale),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Título del Tomo',
                    icon: Icons.title,
                    isDark: isDark,
                    scale: scale,
                    textColor: textColor,
                    borderColor: borderColor,
                    bgColor: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
                  ),
                  SizedBox(height: 14.h * scale),
                  CustomAutocompleteField(
                    controller: _authorController,
                    label: 'Autor / Mangaka',
                    icon: Icons.person_outline,
                    scale: scale,
                    isDark: isDark,
                    optionsBuilder: () => ref
                        .read(comicControllerProvider.notifier)
                        .getSuggestions('author'),
                    onSelected: (value) => _authorController.text = value,
                  ),
                  SizedBox(height: 14.h * scale),
                  CustomAutocompleteField(
                    controller: _genreController,
                    label: 'Género (ej. Shonen, Seinen, Terror)',
                    icon: Icons.category_outlined,
                    scale: scale,
                    isDark: isDark,
                    optionsBuilder: () => ref
                        .read(comicControllerProvider.notifier)
                        .getSuggestions('genre'),
                    onSelected: (value) => _genreController.text = value,
                  ),
                  SizedBox(height: 14.h * scale),
                  CustomAutocompleteField(
                    controller: _collectionController,
                    label: 'Colección / Serie',
                    icon: Icons.collections_bookmark_outlined,
                    scale: scale,
                    isDark: isDark,
                    optionsBuilder: () => ref
                        .read(comicControllerProvider.notifier)
                        .getSuggestions('collection'),
                    onSelected: (value) => _collectionController.text = value,
                  ),

                  SizedBox(height: 28.h * scale),
                  Text(
                    'MODO DE LECTURA POR DEFECTO',
                    style: AppTypography.heading(
                      fontSize: 14.sp * scale,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 12.h * scale),
                  SegmentedButton<String>(
                    segments: [
                      for (final mode in ReadingMode.values)
                        ButtonSegment(
                          value: mode.comicType,
                          label: Text(
                            mode.label,
                            style: AppTypography.heading(
                              fontSize: 12.sp * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          tooltip: mode.description,
                        ),
                    ],
                    selected: {if (_comicType != null) _comicType!},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _comicType = newSelection.firstOrNull;
                      });
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColorsLight.terracotta;
                          }
                          return isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return textColor;
                        },
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                        ),
                      ),
                      side: WidgetStateProperty.all(
                        BorderSide(color: borderColor, width: NeoConstants.borderWidth),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h * scale),
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      text: 'GUARDAR CAMBIOS',
                      icon: Icons.check,
                      backgroundColor: AppColorsLight.terracotta,
                      foregroundColor: Colors.white,
                      onPressed: _save,
                      padding: EdgeInsets.symmetric(vertical: 14.h * scale),
                    ),
                  ),
                  SizedBox(height: 32.h * scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required double scale,
    required Color textColor,
    required Color borderColor,
    required Color bgColor,
  }) {
    return TextFormField(
      controller: controller,
      style: AppTypography.heading(
        fontSize: 14.sp * scale,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body(
          color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
          fontSize: 14.sp * scale,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
          size: 20.sp * scale,
        ),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          borderSide: BorderSide(
            color: isDark ? AppColorsDark.indigo : AppColorsLight.indigo,
            width: NeoConstants.borderWidth + 0.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w * scale, vertical: 14.h * scale),
      ),
    );
  }
}
