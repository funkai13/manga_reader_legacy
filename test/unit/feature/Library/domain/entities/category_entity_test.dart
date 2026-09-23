import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';

void main() {
  CategoryEntity build({
    String name = 'Oda',
    int count = 3,
    String type = 'author',
    String? coverPath = '/c.jpg',
  }) =>
      CategoryEntity(name: name, count: count, type: type, coverPath: coverPath);

  group('CategoryEntity', () {
    test('stores fields; coverPath is optional', () {
      final c = CategoryEntity(name: 'n', count: 0, type: 'genre');
      expect(c.name, 'n');
      expect(c.count, 0);
      expect(c.type, 'genre');
      expect(c.coverPath, isNull);
    });

    test('value equality and hashCode', () {
      final a = build();
      final b = build();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect({a, b}.length, 1);
    });

    test('identical instance is equal', () {
      final a = build();
      expect(a == a, isTrue);
    });

    test('differs when any field differs', () {
      final base = build();
      expect(base, isNot(equals(build(name: 'Other'))));
      expect(base, isNot(equals(build(count: 4))));
      expect(base, isNot(equals(build(type: 'genre'))));
      expect(base, isNot(equals(build(coverPath: null))));
      expect(base, isNot(equals(build(coverPath: '/other.jpg'))));
    });

    test('is not equal to other types', () {
      // ignore: unrelated_type_equality_checks
      expect(build() == 'Oda', isFalse);
    });
  });
}
