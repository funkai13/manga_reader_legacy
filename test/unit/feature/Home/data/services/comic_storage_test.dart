import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/services/comic_storage.dart';
import 'package:path/path.dart' as p;

void main() {
  final docs = p.join(Directory.systemTemp.path, 'docs');
  var calls = 0;
  late ComicStorage storage;

  setUp(() {
    calls = 0;
    storage = ComicStorage(documentsDirectory: () async {
      calls++;
      return Directory(docs);
    });
  });

  test('stores paths under documents as relative with "/" separators',
      () async {
    expect(await storage.toStored(p.join(docs, 'comics', 'c_1', '0001.jpg')),
        'comics/c_1/0001.jpg');
  });

  test('paths outside documents and empty paths are stored unchanged',
      () async {
    final outside = p.join(Directory.systemTemp.path, 'other', 'a.jpg');
    expect(await storage.toStored(outside), outside);
    expect(await storage.toStored(''), '');
  });

  test('resolve turns stored paths back into absolute ones', () async {
    expect(await storage.resolve('comics/c_1/thumb/cover.jpg'),
        p.join(docs, 'comics', 'c_1', 'thumb', 'cover.jpg'));
    final legacy = p.join(docs, 'comics', '3');
    expect(await storage.resolve(legacy), legacy);
    expect(await storage.resolve(''), '');
    expect(await storage.resolveNullable(null), isNull);
  });

  test('round-trips through toStored/resolve', () async {
    final path = p.join(docs, 'comics', 'c_9', '0012.webp');
    expect(await storage.resolve(await storage.toStored(path)), path);
  });

  test('new folders live under documents/comics and are unique', () async {
    final a = await storage.newComicFolder();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final b = await storage.newComicFolder();
    expect(p.dirname(a), p.join(docs, 'comics'));
    expect(a, isNot(b));
  });

  test('looks up the documents directory only once', () async {
    await storage.resolve('a');
    await storage.toStored(p.join(docs, 'b'));
    await storage.newComicFolder();
    expect(calls, 1);
  });
}
