import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_metadata_dialog.dart';

Future<void> importComicFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final notifier = ref.read(comicControllerProvider.notifier);

  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  final file = result?.files.singleOrNull;
  final filePath = file?.path;
  if (file == null || filePath == null) return;

  try {
    if (!ComicController.isSupportedArchive(file.name)) {
      _showNeoSnackBar(messenger, 'Seleccione un archivo con extensión .cbr o .cbz', isError: true);
      return;
    }
    if (await notifier.isAlreadyImported(filePath)) {
      _showNeoSnackBar(messenger, 'Este cómic ya está en tu biblioteca.', isError: true);
      return;
    }
    if (!context.mounted) return;

    final processing = notifier.importComic(filePath, file.name);
    var processingDone = false;
    var dialogOpen = true;
    processing.then<void>(
      (_) => processingDone = true,
      onError: (Object _) {
        processingDone = true;
        if (dialogOpen) navigator.pop();
      },
    );

    final metadata = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ComicMetadataDialog(fileName: file.name),
    ).whenComplete(() => dialogOpen = false);

    final ComicEntity created = processingDone
        ? await processing
        : await _whileShowingSpinner(navigator, processing);
    await notifier.finishImport(created, metadata);
  } on DuplicateComicException {
    _showNeoSnackBar(messenger, 'Este cómic ya está en tu biblioteca.', isError: true);
  } on UnsupportedComicException catch (e) {
    _showNeoSnackBar(messenger, e.message.isNotEmpty ? e.message : 'Este archivo de cómic no está soportado.', isError: true);
  } catch (_) {
    _showNeoSnackBar(messenger, 'Ocurrió un error al agregar el cómic.', isError: true);
  } finally {
    unawaited(_clearPickerCache());
  }
}

void _showNeoSnackBar(ScaffoldMessengerState messenger, String message, {bool isError = false}) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          color: isError ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: isError ? const Color(0xFFFF5252) : const Color(0xFFA8E86C),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Colors.black, width: 3),
      ),
      elevation: 0,
      margin: const EdgeInsets.all(16),
    ),
  );
}

Future<T> _whileShowingSpinner<T>(NavigatorState navigator, Future<T> work) {
  final isDark = Theme.of(navigator.context).brightness == Brightness.dark;
  final bgColor = isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF);
  final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
  final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
  final accentColor = isDark ? const Color(0xFFFFE156) : const Color(0xFF4ECDC4);

  showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => Center(
      child: Container(
        padding: const EdgeInsets.all(32),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor,
                border: Border.all(color: borderColor, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'IMPORTANDO CÓMIC...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
                decoration: TextDecoration.none,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return work.whenComplete(navigator.pop);
}

Future<void> _clearPickerCache() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    await FilePicker.platform.clearTemporaryFiles();
  } catch (e) {
    debugPrint('Could not clear file_picker cache: $e');
  }
}
