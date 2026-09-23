import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_metadata_dialog.dart';

/// Picks a CBZ/CBR and imports it. The archive is extracted while the user
/// fills in the metadata dialog; if they finish first, a spinner is shown
/// until the extraction is done.
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
      messenger.showSnackBar(const SnackBar(
        content: Text('Seleccione un archivo con extensión .cbr o .cbz'),
      ));
      return;
    }
    if (await notifier.isAlreadyImported(filePath)) {
      messenger.showSnackBar(_alreadyInLibrary);
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
        // The comic couldn't be imported: there is nothing left to describe.
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
    // Same content imported meanwhile (e.g. picked twice in a row).
    messenger.showSnackBar(_alreadyInLibrary);
  } on UnsupportedComicException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(
        e.message.isNotEmpty
            ? e.message
            : 'Este archivo de cómic no está soportado.',
      ),
    ));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Ocurrió un error al agregar el cómic.'),
    ));
  } finally {
    unawaited(_clearPickerCache());
  }
}

const _alreadyInLibrary = SnackBar(
  content: Text('Este cómic ya está en tu biblioteca.'),
);

Future<T> _whileShowingSpinner<T>(NavigatorState navigator, Future<T> work) {
  showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  return work.whenComplete(navigator.pop);
}

/// On mobile file_picker copies the picked file into the app cache; the
/// pages are already extracted, so that copy (often hundreds of MB) can go.
Future<void> _clearPickerCache() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    await FilePicker.platform.clearTemporaryFiles();
  } catch (e) {
    debugPrint('Could not clear file_picker cache: $e');
  }
}
