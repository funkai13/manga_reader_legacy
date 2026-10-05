import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Renombrar ${widget.type}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Nuevo nombre',
                  labelStyle: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor, width: 2.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF5252), width: 3),
                    borderRadius: BorderRadius.circular(4),
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor,
                          offset: const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                // Save Button
                GestureDetector(
                  onTap: () async {
                    if (_formKey.currentState!.validate()) {
                      final newName = _controller.text.trim();
                      if (newName != widget.currentName) {
                        try {
                          await ref
                              .read(libraryControllerProvider(widget.type).notifier)
                              .renameCategory(widget.currentName, newName, widget.type);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            _showNeoSnackBar(context, 'Renombrado con éxito', const Color(0xFFA8E86C), borderColor); // Success Lime
                          }
                        } catch (e) {
                          if (context.mounted) {
                            _showNeoSnackBar(context, 'Error al renombrar', const Color(0xFFFF5252), borderColor); // Error Red
                          }
                        }
                      } else {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE156), // Hot Yellow
                      border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1A1A2E),
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'Guardar',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A2E), // Black text
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNeoSnackBar(BuildContext context, String message, Color bgColor, Color borderColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: const Color(0xFF1A1A2E), width: 3), // Always black border for snackbar
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1A1A2E),
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF1A1A2E), // Black text
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
