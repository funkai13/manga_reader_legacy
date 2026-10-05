import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_loading.dart';
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
      _showImportSnackBar(messenger, 'Seleccione un archivo con extensión .cbr o .cbz', isError: true);
      return;
    }
    if (await notifier.isAlreadyImported(filePath)) {
      _showImportSnackBar(messenger, 'Este cómic ya está en tu biblioteca.', isError: true);
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
    _showImportSnackBar(messenger, 'Este cómic ya está en tu biblioteca.', isError: true);
  } on UnsupportedComicException catch (e) {
    _showImportSnackBar(
      messenger,
      e.message.isNotEmpty ? e.message : 'Este archivo de cómic no está soportado.',
      isError: true,
    );
  } catch (_) {
    _showImportSnackBar(messenger, 'Ocurrió un error al agregar el cómic.', isError: true);
  } finally {
    unawaited(_clearPickerCache());
  }
}

void _showImportSnackBar(ScaffoldMessengerState messenger, String message, {bool isError = false}) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: AppTypography.heading(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.white,
        ),
      ),
      backgroundColor: isError ? AppColorsLight.errorColor : AppColorsLight.terracotta,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
        side: const BorderSide(color: Colors.black, width: NeoConstants.borderWidth),
      ),
      elevation: 0,
      margin: const EdgeInsets.all(16),
    ),
  );
}

Future<T> _whileShowingSpinner<T>(NavigatorState navigator, Future<T> work) {
  final isDark = Theme.of(navigator.context).brightness == Brightness.dark;
  final bgColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;
  final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
  final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
  final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

  showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NeoLoadingIndicator(size: 48),
            const SizedBox(height: 20),
            Text(
              'EXTRAYENDO TOMO...',
              style: AppTypography.mono(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 1.0,
              ).copyWith(decoration: TextDecoration.none),
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
