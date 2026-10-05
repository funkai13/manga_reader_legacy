import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Cheap content fingerprint of a comic archive, used to detect a comic that
/// is imported twice regardless of its file name.
///
/// Hashing a whole CBZ/CBR (often hundreds of MB) would slow every import
/// down, so only the file size plus the first and last [chunkSize] bytes are
/// hashed. Archives keep their central directory / headers at those ends, so
/// two different comics practically never collide.
///
/// Hashing is executed via [Isolate.run] off the UI isolate to prevent any
/// frame drops or UI freezes during comic import.
class ComicFingerprint {
  const ComicFingerprint({this.chunkSize = 64 * 1024});

  final int chunkSize;

  /// SHA-1 hex digest of `size + head + tail` for the file at [path],
  /// executed in a background isolate.
  /// Throws a [FileSystemException] when the file can't be read.
  Future<String> of(String path) async {
    return Isolate.run(() => _calculateFingerprint(path, chunkSize));
  }

  static String _calculateFingerprint(String path, int chunkSize) {
    final raf = File(path).openSync();
    try {
      final length = raf.lengthSync();
      final header = ByteData(8)..setUint64(0, length);
      final builder = BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List());

      final headLength = length < chunkSize ? length : chunkSize;
      builder.add(raf.readSync(headLength));

      final tailStart = length - chunkSize;
      if (tailStart > headLength) {
        raf.setPositionSync(tailStart);
      } else {
        // Small file: the tail is whatever follows the head (maybe nothing),
        // so every byte is hashed exactly once.
        raf.setPositionSync(headLength);
      }
      builder.add(raf.readSync(chunkSize));

      return sha1.convert(builder.takeBytes()).toString();
    } finally {
      raf.closeSync();
    }
  }

  /// Like [of], but returns null when the file doesn't exist or can't be read.
  Future<String?> tryOf(String path) async {
    try {
      return await of(path);
    } on FileSystemException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
