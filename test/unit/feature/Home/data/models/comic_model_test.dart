import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
import 'package:manga_reader/feature/Home/data/models/comic_model.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

import '../../../../helpers/comic_fixtures.dart';

void main() {
  group('ComicModel', () {
    test('is a ComicEntity', () {
      expect(buildComicModel(), isA<ComicEntity>());
    });

    group('toMap', () {
      test('serializes every column', () {
        final model = buildComicModel(
          id: 3,
          title: 'T',
          filePath: '/f.cbz',
          picture: 'p.jpg',
          currentReadPage: 4,
          totalPages: 40,
          lastOpened: '2025-01-01',
          currentReading: 1,
          imagesPath: '/imgs',
          isReading: true,
          isFavorite: true,
          rating: 5,
          bookMarks: '1,2',
          isCompleted: true,
          author: 'A',
          genre: 'G',
          collection: 'C',
          comicType: 'Manga',
          contentHash: 'h',
        );

        expect(model.toMap(), {
          ComicFields.id: 3,
          ComicFields.filePath: '/f.cbz',
          ComicFields.title: 'T',
          ComicFields.picture: 'p.jpg',
          ComicFields.currentPage: 4,
          ComicFields.totalPages: 40,
          ComicFields.lastOpened: '2025-01-01',
          ComicFields.currentReading: 1,
          ComicFields.imagesPath: '/imgs',
          ComicFields.isFavorite: 1,
          ComicFields.isReading: 1,
          ComicFields.rating: 5,
          ComicFields.bookMarks: '1,2',
          ComicFields.isCompleted: 1,
          ComicFields.author: 'A',
          ComicFields.genre: 'G',
          ComicFields.collection: 'C',
          ComicFields.comicType: 'Manga',
          ComicFields.contentHash: 'h',
        });
      });

      test('encodes booleans as 0 and keeps nulls', () {
        final map = buildComicModel(id: null).toMap();
        expect(map[ComicFields.id], isNull);
        expect(map[ComicFields.isFavorite], 0);
        expect(map[ComicFields.isReading], 0);
        expect(map[ComicFields.isCompleted], 0);
        expect(map[ComicFields.rating], isNull);
        expect(map[ComicFields.author], isNull);
        expect(map[ComicFields.genre], isNull);
        expect(map[ComicFields.collection], isNull);
        expect(map[ComicFields.comicType], isNull);
      });
    });

    group('fromMap', () {
      test('parses a complete row', () {
        final model = ComicModel.fromMap(buildComicRow(rating: 4));
        expect(comicFields(model), {
          'id': 1,
          'filePath': '/comics/a.cbz',
          'title': 'A',
          'picture': 'cover.jpg',
          'currentReadPage': 3,
          'totalPages': 20,
          'lastOpened': '2025-01-01T10:00:00.000',
          'currentReading': 0,
          'imagesPath': '/images/a',
          'isReading': false,
          'isFavorite': false,
          'rating': 4,
          'bookMarks': '',
          'isCompleted': false,
          'author': 'Author',
          'genre': 'Seinen',
          'collection': 'Col',
          'comicType': 'Manga',
        });
      });

      test('roundtrip toMap -> fromMap preserves every field', () {
        final model = buildComicModel(
          id: 9,
          picture: 'x.png',
          isFavorite: true,
          isReading: true,
          isCompleted: true,
          rating: 3,
          bookMarks: '5',
          author: 'A',
          genre: 'G',
          collection: 'C',
          comicType: 'Comic',
        );
        final parsed = ComicModel.fromMap(model.toMap());
        expect(comicFields(parsed), comicFields(model));
      });

      test('null id is allowed', () {
        expect(ComicModel.fromMap(buildComicRow(id: null)).id, isNull);
      });

      test('null picture / lastOpened / bookMarks default to empty string',
          () {
        final model = ComicModel.fromMap(
          buildComicRow(picture: null, lastOpened: null, bookMarks: null),
        );
        expect(model.picture, '');
        expect(model.lastOpened, '');
        expect(model.bookMarks, '');
      });

      group('boolean conversion', () {
        final cases = <Object?, bool>{
          null: false,
          0: false,
          1: true,
          2: true,
          -1: true,
          true: true,
          false: false,
          '1': true,
          '0': false,
          'true': true,
          'TRUE': true,
          'True': true,
          'false': false,
          'yes': false,
          '': false,
        };
        cases.forEach((raw, expected) {
          test('${raw.runtimeType}($raw) -> $expected', () {
            final model = ComicModel.fromMap(buildComicRow(
              isFavorite: raw,
              isReading: raw,
              isCompleted: raw,
            ));
            expect(model.isFavorite, expected);
            expect(model.isReading, expected);
            expect(model.isCompleted, expected);
          });
        });
      });

      group('rating conversion', () {
        final cases = <Object?, int?>{
          null: null,
          0: null, // DB default 0 means "no rating"
          5: 5,
          -2: -2,
          '3': 3,
          '0': null,
          'abc': null,
          '': null,
        };
        cases.forEach((raw, expected) {
          test('${raw.runtimeType}($raw) -> $expected', () {
            expect(ComicModel.fromMap(buildComicRow(rating: raw)).rating,
                expected);
          });
        });
      });

      test('doubles are not handled: bool -> false, rating -> null', () {
        // NOTE: 1 == 1.0 in Dart, so these cannot live in the map above.
        final model = ComicModel.fromMap(
            buildComicRow(isFavorite: 1.0, rating: 4.0));
        expect(model.isFavorite, isFalse);
        expect(model.rating, isNull);
      });

      test('throws when a required column is missing', () {
        final row = buildComicRow()..remove(ComicFields.filePath);
        expect(() => ComicModel.fromMap(row), throwsA(isA<TypeError>()));
      });

      test('NULL int columns default to 0', () {
        final row = buildComicRow()
          ..[ComicFields.totalPages] = null
          ..[ComicFields.currentPage] = null
          ..[ComicFields.currentReading] = null;
        final model = ComicModel.fromMap(row);
        expect(model.totalPages, 0);
        expect(model.currentReadPage, 0);
        expect(model.currentReading, 0);
      });

      test('contentHash is optional (legacy rows) and roundtrips', () {
        expect(ComicModel.fromMap(buildComicRow()).contentHash, isNull);
        final row = buildComicRow()..[ComicFields.contentHash] = 'abc';
        final model = ComicModel.fromMap(row);
        expect(model.contentHash, 'abc');
        expect(model.toMap()[ComicFields.contentHash], 'abc');
      });

      test('throws when imagesPath is null', () {
        final row = buildComicRow()..[ComicFields.imagesPath] = null;
        expect(() => ComicModel.fromMap(row), throwsA(isA<TypeError>()));
      });
    });

    test('copyWith returns a ComicEntity (not a ComicModel)', () {
      // Documented: copyWith is inherited from ComicEntity so the model
      // type (and toMap) is lost after copying.
      final copy = buildComicModel().copyWith(title: 'x');
      expect(copy, isNot(isA<ComicModel>()));
      expect(copy.title, 'x');
    });
  });
}
