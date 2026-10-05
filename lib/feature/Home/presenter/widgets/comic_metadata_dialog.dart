import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_button.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/custom_autocomplete_field.dart';
import 'package:path/path.dart' as p;

class ComicMetadataDialog extends ConsumerStatefulWidget {
  final String fileName;

  const ComicMetadataDialog({
    super.key,
    required this.fileName,
  });

  @override
  ConsumerState<ComicMetadataDialog> createState() => _ComicMetadataDialogState();
}

class _ComicMetadataDialogState extends ConsumerState<ComicMetadataDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _collectionController = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    final baseTitle = p.basenameWithoutExtension(widget.fileName);
    _titleController = TextEditingController(text: baseTitle);
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
    final ext = p.extension(widget.fileName).toLowerCase();
    if (ext == '.cbz') return 'CBZ';
    if (ext == '.cbr') return 'CBR';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(comicControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;
    final format = _formatBadge();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IMPORTAR TOMO',
                          style: AppTypography.heading(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'FICHA TÉCNICA EDITORIAL',
                          style: AppTypography.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColorsLight.terracotta,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    if (format != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColorsLight.indigo,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Text(
                          format,
                          style: AppTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  style: AppTypography.heading(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Título del Tomo',
                    labelStyle: AppTypography.body(
                      color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                    ),
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
                    filled: true,
                    fillColor: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título no puede estar vacío';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomAutocompleteField(
                  label: 'Autor / Mangaka',
                  isDark: isDark,
                  controller: _authorController,
                  icon: Icons.person_outline,
                  optionsBuilder: () => controller.getSuggestions('author'),
                  onSelected: (value) => _authorController.text = value,
                ),
                const SizedBox(height: 12),
                CustomAutocompleteField(
                  label: 'Género',
                  isDark: isDark,
                  controller: _genreController,
                  icon: Icons.category_outlined,
                  optionsBuilder: () => controller.getSuggestions('genre'),
                  onSelected: (value) => _genreController.text = value,
                ),
                const SizedBox(height: 12),
                CustomAutocompleteField(
                  label: 'Colección / Serie',
                  isDark: isDark,
                  controller: _collectionController,
                  icon: Icons.collections_bookmark_outlined,
                  optionsBuilder: () => controller.getSuggestions('collection'),
                  onSelected: (value) => _collectionController.text = value,
                ),
                const SizedBox(height: 16),
                Text(
                  'TIPO DE LECTURA',
                  style: AppTypography.heading(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'Manga',
                      label: Text(
                        'Manga (D → I)',
                        style: AppTypography.heading(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.auto_stories, size: 16),
                    ),
                    ButtonSegment<String>(
                      value: 'Comic',
                      label: Text(
                        'Cómic (I → D)',
                        style: AppTypography.heading(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.menu_book, size: 16),
                    ),
                  ],
                  selected: {if (_selectedType != null) _selectedType!},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.firstOrNull;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColorsLight.terracotta;
                        }
                        return isDark ? AppColorsDark.surfaceDeep : AppColorsLight.cardColor;
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NeoOutlinedButton(
                      text: 'OMITIR',
                      fontSize: 12,
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                    const SizedBox(width: 10),
                    NeoButton(
                      text: 'IMPORTAR',
                      fontSize: 12,
                      backgroundColor: AppColorsLight.terracotta,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop({
                            'title': _titleController.text.trim(),
                            'author': _authorController.text.trim(),
                            'genre': _genreController.text.trim(),
                            'collection': _collectionController.text.trim(),
                            if (_selectedType != null) 'comicType': _selectedType!,
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
