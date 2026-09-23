import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';

void main() {
  group('UnsupportedComicException', () {
    test('defaults to empty message', () {
      final e = UnsupportedComicException();
      expect(e.message, '');
      expect(e.toString(), 'UnsupportedComicException: ');
    });

    test('keeps the given message', () {
      final e = UnsupportedComicException('RAR5 no soportado');
      expect(e.message, 'RAR5 no soportado');
      expect(e.toString(), 'UnsupportedComicException: RAR5 no soportado');
    });

    test('is an Exception and can be thrown/caught by type', () {
      expect(UnsupportedComicException(), isA<Exception>());
      expect(
        () => throw UnsupportedComicException('x'),
        throwsA(isA<UnsupportedComicException>()
            .having((e) => e.message, 'message', 'x')),
      );
    });
  });
}
