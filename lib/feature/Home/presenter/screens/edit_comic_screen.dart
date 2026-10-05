import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';
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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El título no puede estar vacío',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.black, width: 2),
          ),
        ),
      );
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
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cómic actualizado',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          backgroundColor: const Color(0xFFA8E86C),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.black, width: 2),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final scale = isTablet ? 0.8 : 1.0;
    
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final accentColor = isDark ? const Color(0xFFFFE156) : const Color(0xFFFF6B9D);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.h * scale,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.comic.picture.isNotEmpty)
                    FileThumbnail(widget.comic.picture, width: 120)
                  else
                    Container(
                      color: bgColor,
                    ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                  Center(
                    child: Container(
                      height: 200.h * scale,
                      width: 150.w * scale,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252542) : Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 0,
                            offset: Offset(6, 6),
                          ),
                        ],
                      ),
                      child: widget.comic.picture.isNotEmpty
                          ? FileThumbnail(widget.comic.picture, fit: BoxFit.cover)
                          : Container(
                              color: isDark ? const Color(0xFF252542) : Colors.white,
                              child: const Icon(Icons.book, size: 50, color: Colors.black),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(8.w * scale),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8.w * scale),
                decoration: BoxDecoration(
                  color: accentColor,
                  border: Border.all(color: Colors.black, width: 2),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.save, color: Colors.black),
                  onPressed: _save,
                ),
              ),
              SizedBox(width: 8.w * scale),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EDITAR DETALLES',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28.sp * scale,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 24.h * scale),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Título',
                    icon: Icons.title,
                    isDark: isDark,
                    scale: scale,
                    textColor: textColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    bgColor: bgColor,
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
                  SizedBox(height: 32.h * scale),
                  Text(
                    'TIPO DE LECTURA',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16.sp * scale,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 16.h * scale),
                  SegmentedButton<String>(
                    segments: [
                      for (final mode in ReadingMode.values)
                        ButtonSegment(
                          value: mode.comicType,
                          label: Text(mode.label, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                          tooltip: mode.description,
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
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return accentColor;
                          }
                          return isDark ? const Color(0xFF252542) : Colors.white;
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
                  SizedBox(height: 16.h * scale),
                  Container(
                    padding: EdgeInsets.all(12.w * scale),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252542) : Colors.white,
                      border: Border(left: BorderSide(color: accentColor, width: 4), top: BorderSide(color: borderColor, width: 2), right: BorderSide(color: borderColor, width: 2), bottom: BorderSide(color: borderColor, width: 2)),
                    ),
                    child: Text(
                      _comicType == null
                          ? 'Automático: se lee de izquierda a derecha'
                          : ReadingMode.fromComicType(_comicType).description,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp * scale,
                        color: textColor,
                        fontWeight: FontWeight.bold,
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
    required Color textColor,
    required Color borderColor,
    required Color accentColor,
    required Color bgColor,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 16.sp * scale,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
        prefixIcon: Icon(
          icon,
          color: textColor,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7),
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
          borderSide: BorderSide(
            color: accentColor,
            width: 3,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w * scale, vertical: 18.h * scale),
      ),
    );
  }
}
