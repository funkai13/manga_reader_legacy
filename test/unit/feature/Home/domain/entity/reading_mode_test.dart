import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/reading_mode.dart';

void main() {
  group('ReadingMode enum', () {
    test('contains expected values with proper labels and descriptions', () {
      expect(ReadingMode.values, [
        ReadingMode.rightToLeft,
        ReadingMode.leftToRight,
        ReadingMode.vertical,
      ]);

      expect(ReadingMode.rightToLeft.comicType, 'Manga');
      expect(ReadingMode.rightToLeft.label, 'Manga');
      expect(ReadingMode.rightToLeft.description, 'Derecha a izquierda');
      expect(ReadingMode.rightToLeft.isPaged, isTrue);

      expect(ReadingMode.leftToRight.comicType, 'Comic');
      expect(ReadingMode.leftToRight.label, 'Cómic');
      expect(ReadingMode.leftToRight.description, 'Izquierda a derecha');
      expect(ReadingMode.leftToRight.isPaged, isTrue);

      expect(ReadingMode.vertical.comicType, 'Webtoon');
      expect(ReadingMode.vertical.label, 'Webtoon');
      expect(ReadingMode.vertical.description, 'Scroll vertical continuo');
      expect(ReadingMode.vertical.isPaged, isFalse);
    });

    test('fromComicType maps correctly and defaults to leftToRight', () {
      expect(ReadingMode.fromComicType('Manga'), ReadingMode.rightToLeft);
      expect(ReadingMode.fromComicType('Comic'), ReadingMode.leftToRight);
      expect(ReadingMode.fromComicType('Webtoon'), ReadingMode.vertical);
      expect(ReadingMode.fromComicType(null), ReadingMode.leftToRight);
      expect(ReadingMode.fromComicType(''), ReadingMode.leftToRight);
      expect(ReadingMode.fromComicType('NonExistent'), ReadingMode.leftToRight);
    });
  });
}
