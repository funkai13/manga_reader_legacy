class UnsupportedComicException implements Exception {
  final String message;

  UnsupportedComicException([this.message = '']);

  @override
  String toString() => 'UnsupportedComicException: $message';
}

/// The archive being imported has the same content as a comic that is
/// already in the library (detected by content, not by file name).
class DuplicateComicException implements Exception {
  /// Id of the comic already in the library, when known.
  final int? existingId;

  DuplicateComicException({this.existingId});

  @override
  String toString() => 'DuplicateComicException: existingId=$existingId';
}
