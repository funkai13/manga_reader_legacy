import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_button.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
import 'package:manga_reader/feature/Library/presenter/controller/library_controller.dart';

class RenameCategoryDialog extends ConsumerStatefulWidget {
  final String currentName;
  final String type; // 'author', 'genre', 'collection'

  const RenameCategoryDialog({
    super.key,
    required this.currentName,
    required this.type,
  });

  @override
  ConsumerState<RenameCategoryDialog> createState() => _RenameCategoryDialogState();
}

class _RenameCategoryDialogState extends ConsumerState<RenameCategoryDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _typeLabel() {
    switch (widget.type) {
      case 'author':
        return 'Autor';
      case 'genre':
        return 'Género';
      case 'collection':
        return 'Colección';
      default:
        return 'Categoría';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Renombrar ${_typeLabel()}',
              style: AppTypography.heading(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                style: AppTypography.heading(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Nuevo nombre',
                  labelStyle: AppTypography.body(
                    color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
                    borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? AppColorsDark.indigo : AppColorsLight.indigo,
                      width: NeoConstants.borderWidth + 0.5,
                    ),
                    borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColorsLight.errorColor, width: 2),
                    borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColorsLight.errorColor, width: 2.5),
                    borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre no puede estar vacío';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NeoOutlinedButton(
                  text: 'Cancelar',
                  isUppercase: false,
                  onPressed: () => Navigator.of(context).pop(),
                  fontSize: 12,
                ),
                const SizedBox(width: 12),
                NeoButton(
                  text: 'Guardar',
                  isUppercase: false,
                  backgroundColor: AppColorsLight.terracotta,
                  foregroundColor: Colors.white,
                  fontSize: 12,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final newName = _controller.text.trim();
                      if (newName != widget.currentName) {
                        try {
                          await ref
                              .read(libraryControllerProvider(widget.type).notifier)
                              .renameCategory(widget.currentName, newName, widget.type);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            showNeoSnackBar(context, 'Renombrado con éxito');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showNeoSnackBar(context, 'Error al renombrar', isError: true);
                          }
                        }
                      } else {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
