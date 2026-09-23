import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Cheap content fingerprint of a comic archive, used to detect a comic that
/// is imported twice regardless of its file name.
///
/// Hashing a whole CBZ/CBR (often hundreds of MB) would slow every import
/// down, so only the file size plus the first and last [chunkSize] bytes are
/// hashed. Archives keep their central directory / headers at those ends, so
/// two different comics practically never collide.
class ComicFingerprint {
  const ComicFingerprint({this.chunkSize = 64 * 1024});

  final int chunkSize;

  /// SHA-1 hex digest of `size + head + tail` for the file at [path].
  /// Throws a [FileSystemException] when the file can't be read.
  Future<String> of(String path) async {
    final raf = await File(path).open();
    try {
      final length = await raf.length();
      final header = ByteData(8)..setUint64(0, length);
      final builder = BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List());

      final headLength = length < chunkSize ? length : chunkSize;
      builder.add(await raf.read(headLength));

      final tailStart = length - chunkSize;
      if (tailStart > headLength) {
        await raf.setPosition(tailStart);
      } else {
        // Small file: the tail is whatever follows the head (maybe nothing),
        // so every byte is hashed exactly once.
        await raf.setPosition(headLength);
      }
      builder.add(await raf.read(chunkSize));

      return sha1.convert(builder.takeBytes()).toString();
    } finally {
      await raf.close();
    }
  }

  /// Like [of], but returns null when the file doesn't exist or can't be read.
  Future<String?> tryOf(String path) async {
    try {
      return await of(path);
    } on FileSystemException {
      return null;
    }
  }
}
