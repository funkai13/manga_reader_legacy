import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/custom_autocomplete_field.dart';

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
  // null = auto (not chosen yet); the viewer reads it as left-to-right.
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

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título no puede estar vacío')),
      );
      return;
    }

    await ref.read(comicControllerProvider.notifier).updateComicMetadata(
          id: widget.comic.id!,
          author: _authorController.text.isEmpty ? null : _authorController.text,
          genre: _genreController.text.isEmpty ? null : _genreController.text,
          collection: _collectionController.text.isEmpty
              ? null
              : _collectionController.text,
          // Only persist the type when the user actually picked one.
          comicType:
              _comicType != widget.comic.comicType ? _comicType : null,
          title: _titleController.text,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cómic actualizado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final scale = isTablet ? 0.8 : 1.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.h * scale,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred Background
                  if (widget.comic.picture.isNotEmpty)
                    Image.file(
                      File(widget.comic.picture),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: isDark
                          ? AppColorsDark.backgroundColor
                          : AppColorsLight.backgroundColor,
                    ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),

                  // Sharp Cover Image
                  Center(
                    child: Container(
                      height: 200.h * scale,
                      width: 150.w * scale,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r * scale),
                        child: widget.comic.picture.isNotEmpty
                            ? Image.file(
                                File(widget.comic.picture),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey,
                                child: const Icon(Icons.book, size: 50),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _save,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editar Detalles',
                    style: TextStyle(
                      fontSize: 24.sp * scale,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColorsDark.textColor
                          : AppColorsLight.textColor,
                    ),
                  ),
                  SizedBox(height: 24.h * scale),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Título',
                    icon: Icons.title,
                    isDark: isDark,
                    scale: scale,
                  ),
                  SizedBox(height: 16.h * scale),
                  CustomAutocompleteField(
                    controller: _authorController,
                    label: 'Autor',
                    icon: Icons.person,
                    scale: scale,
                    isDark: isDark,
                    optionsBuilder: () => ref
                        .read(comicControllerProvider.notifier)
                        .getSuggestions('author'),
                    onSelected: (value) => _authorController.text = value,
                  ),
                  SizedBox(height: 16.h * scale),
                  CustomAutocompleteField(
                    controller: _genreController,
                    label: 'Género',
                    icon: Icons.category,
                    scale: scale,
                    isDark: isDark,
                    optionsBuilder: () => ref
                        .read(comicControllerProvider.notifier)
                        .getSuggestions('genre'),
                    onSelected: (value) => _genreController.text = value,
                  ),
                  SizedBox(height: 16.h * scale),
                  CustomAutocompleteField(
                    controller: _collectionController,
                    label: 'Colección',
                    icon: Icons.collections_bookmark,
                    scale: scale,
                    isDark: isDark,
                    optionsBuilder: () => ref
                        .read(comicControllerProvider.notifier)
                        .getSuggestions('collection'),
                    onSelected: (value) => _collectionController.text = value,
                  ),
                  SizedBox(height: 24.h * scale),
                  Text(
                    'Tipo de Lectura',
                    style: TextStyle(
                      fontSize: 16.sp * scale,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColorsDark.textColor
                          : AppColorsLight.textColor,
                    ),
                  ),
                  SizedBox(height: 12.h * scale),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Manga',
                        label: Text('Manga (Der-Izq)'),
                        icon: Icon(Icons.auto_stories),
                      ),
                      ButtonSegment(
                        value: 'Comic',
                        label: Text('Comic (Izq-Der)'),
                        icon: Icon(Icons.menu_book),
                      ),
                    ],
                    selected: {if (_comicType != null) _comicType!},
                    emptySelectionAllowed: _comicType == null,
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _comicType = newSelection.firstOrNull;
                      });
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: isDark
                              ? AppColorsDark.accentColor
                              : AppColorsLight.accentColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h * scale),
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
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        fontSize: 16.sp * scale,
        color: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColorsDark.accentColor : AppColorsLight.accentColor,
        ),
        filled: true,
        fillColor: isDark
            ? AppColorsDark.cardColor
            : AppColorsLight.cardColor.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r * scale),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r * scale),
          borderSide: BorderSide(
            color: isDark
                ? AppColorsDark.accentColor
                : AppColorsLight.accentColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
