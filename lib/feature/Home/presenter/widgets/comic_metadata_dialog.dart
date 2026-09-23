import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // null = auto; don't guess the reading direction for the user.
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
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
                  'Nuevo Cómic',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
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
                const SizedBox(height: 16),
                CustomAutocompleteField(
                  label: 'Autor',
                  controller: _authorController,
                  icon: Icons.person,
                  optionsBuilder: () => controller.getSuggestions('author'),
                  onSelected: (value) => _authorController.text = value,
                ),
                const SizedBox(height: 16),
                CustomAutocompleteField(
                  label: 'Género',
                  controller: _genreController,
                  icon: Icons.category,
                  optionsBuilder: () => controller.getSuggestions('genre'),
                  onSelected: (value) => _genreController.text = value,
                ),
                const SizedBox(height: 16),
                CustomAutocompleteField(
                  label: 'Colección',
                  controller: _collectionController,
                  icon: Icons.collections_bookmark,
                  optionsBuilder: () => controller.getSuggestions('collection'),
                  onSelected: (value) => _collectionController.text = value,
                ),
                const SizedBox(height: 24),
                Text(
                  'Tipo de Lectura',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'Manga',
                      label: Text('Manga'),
                      icon: Icon(Icons.auto_stories),
                    ),
                    ButtonSegment<String>(
                      value: 'Comic',
                      label: Text('Cómic'),
                      icon: Icon(Icons.menu_book),
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
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Omitir'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop({
                            'title': _titleController.text.trim(),
                            'author': _authorController.text.trim(),
                            'genre': _genreController.text.trim(),
                            'collection': _collectionController.text.trim(),
                            if (_selectedType != null)
                              'comicType': _selectedType!,
                          });
                        }
                      },
                      child: const Text('Guardar'),
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
