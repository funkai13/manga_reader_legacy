import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

import '../../../../helpers/comic_fixtures.dart';

void main() {
  group('ComicEntity constructor', () {
    test('uses defaults for optional fields', () {
      final comic = ComicEntity(
        title: 't',
        filePath: '/f.cbz',
        currentReadPage: 0,
        totalPages: 0,
        lastOpened: '',
        currentReading: 0,
        imagesPath: '',
        isReading: false,
        isFavorite: false,
        bookMarks: '',
        isCompleted: false,
      );

      expect(comic.id, isNull);
      expect(comic.picture, '');
      expect(comic.rating, isNull);
      expect(comic.author, isNull);
      expect(comic.genre, isNull);
      expect(comic.collection, isNull);
      expect(comic.comicType, isNull);
    });
  });

  group('ComicEntity.copyWith', () {
    final original = buildComicEntity(
      id: 7,
      title: 'Original',
      rating: 4,
      author: 'Author',
      genre: 'Seinen',
      collection: 'Col',
      comicType: 'Manga',
      isFavorite: true,
    );

    test('with no arguments returns an equivalent copy (new instance)', () {
      final copy = original.copyWith();
      expect(identical(copy, original), isFalse);
      expect(comicFields(copy), comicFields(original));
    });

    test('overrides every field that is provided', () {
      final copy = original.copyWith(
        id: 8,
        filePath: '/new.cbz',
        title: 'New',
        currentReadPage: 5,
        totalPages: 50,
        picture: 'p.jpg',
        lastOpened: '2025-02-02',
        currentReading: 1,
        imagesPath: '/imgs',
        isReading: true,
        isFavorite: false,
        rating: 2,
        bookMarks: '1,2',
        isCompleted: true,
        author: 'A2',
        genre: 'G2',
        collection: 'C2',
        comicType: 'Comic',
      );

      expect(comicFields(copy), {
        'id': 8,
        'filePath': '/new.cbz',
        'title': 'New',
        'picture': 'p.jpg',
        'currentReadPage': 5,
        'totalPages': 50,
        'lastOpened': '2025-02-02',
        'currentReading': 1,
        'imagesPath': '/imgs',
        'isReading': true,
        'isFavorite': false,
        'rating': 2,
        'bookMarks': '1,2',
        'isCompleted': true,
        'author': 'A2',
        'genre': 'G2',
        'collection': 'C2',
        'comicType': 'Comic',
      });
    });

    test('only changes the given field', () {
      final copy = original.copyWith(currentReadPage: 3);
      final expected = comicFields(original)..['currentReadPage'] = 3;
      expect(comicFields(copy), expected);
    });

    test('does not mutate the original', () {
      original.copyWith(title: 'Changed', isReading: true);
      expect(original.title, 'Original');
      expect(original.isReading, isFalse);
    });

    test('cannot reset nullable fields to null (limitation of ?? pattern)',
        () {
      // Documenting current behaviour: passing null keeps the old value.
      final copy = original.copyWith(rating: null, author: null);
      expect(copy.rating, 4);
      expect(copy.author, 'Author');
    });
  });

  group('ComicEntity equality', () {
    test('has no value equality (identity only)', () {
      // ComicEntity does not override ==/hashCode. Two entities with the
      // same data are therefore NOT equal. Documented so that a future
      // change to value equality is a conscious decision.
      final a = buildComicEntity();
      final b = buildComicEntity();
      expect(a == b, isFalse);
      expect(a == a, isTrue);
      expect(comicFields(a), comicFields(b));
    });
  });
}
