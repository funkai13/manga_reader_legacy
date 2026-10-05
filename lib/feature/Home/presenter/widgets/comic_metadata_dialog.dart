import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/custom_autocomplete_field.dart';

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
    _titleController = TextEditingController(text: widget.fileName);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _collectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(comicControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final accentColor = isDark ? const Color(0xFFFFE156) : const Color(0xFFFF6B9D);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(6, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'NUEVO CÓMIC',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.spaceGrotesk(color: textColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Título',
                    labelStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: accentColor, width: 3),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título no puede estar vacío';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomAutocompleteField(
                  label: 'Autor',
                  isDark: isDark,
                  controller: _authorController,
                  icon: Icons.person,
                  optionsBuilder: () => controller.getSuggestions('author'),
                  onSelected: (value) => _authorController.text = value,
                ),
                const SizedBox(height: 16),
                CustomAutocompleteField(
                  label: 'Género',
                  isDark: isDark,
                  controller: _genreController,
                  icon: Icons.category,
                  optionsBuilder: () => controller.getSuggestions('genre'),
                  onSelected: (value) => _genreController.text = value,
                ),
                const SizedBox(height: 16),
                CustomAutocompleteField(
                  label: 'Colección',
                  isDark: isDark,
                  controller: _collectionController,
                  icon: Icons.collections_bookmark,
                  optionsBuilder: () => controller.getSuggestions('collection'),
                  onSelected: (value) => _collectionController.text = value,
                ),
                const SizedBox(height: 24),
                Text(
                  'TIPO DE LECTURA',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'Manga',
                      label: Text('Manga', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                      icon: const Icon(Icons.auto_stories),
                    ),
                    ButtonSegment<String>(
                      value: 'Comic',
                      label: Text('Cómic', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                      icon: const Icon(Icons.menu_book),
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
                    visualDensity: VisualDensity.comfortable,
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return accentColor;
                        }
                        return isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.black;
                        }
                        return textColor;
                      },
                    ),
                    shape: WidgetStateProperty.all(
                      const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    side: WidgetStateProperty.all(
                      BorderSide(color: borderColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: TextButton.styleFrom(
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: borderColor, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text('OMITIR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                    ),
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF4ECDC4) : const Color(0xFFFFE156),
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        side: const BorderSide(color: Colors.black, width: 2),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ).copyWith(
                        elevation: WidgetStateProperty.resolveWith<double>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) return 0;
                            return 4; // Use simple elevation to mimic hard shadow if no custom container
                          },
                        ),
                      ),
                      child: Text('GUARDAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
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
