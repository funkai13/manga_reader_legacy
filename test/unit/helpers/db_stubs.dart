import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

/// Stubs [MockComicDatabase.updateComic] for any combination of arguments.
void stubUpdateComic(MockComicDatabase db) {
  when(() => db.updateComic(
        id: any(named: 'id'),
        imagesPath: any(named: 'imagesPath'),
        picture: any(named: 'picture'),
        filePath: any(named: 'filePath'),
        title: any(named: 'title'),
        totalPages: any(named: 'totalPages'),
        isReading: any(named: 'isReading'),
        isCompleted: any(named: 'isCompleted'),
        author: any(named: 'author'),
        genre: any(named: 'genre'),
        collection: any(named: 'collection'),
        comicType: any(named: 'comicType'),
      )).thenAnswer((_) async {});
}

/// Captures the named arguments of the last updateComic calls.
List<Map<String, Object?>> captureUpdateComicCalls(MockComicDatabase db) {
  final calls = verify(() => db.updateComic(
        id: captureAny(named: 'id'),
        imagesPath: captureAny(named: 'imagesPath'),
        picture: captureAny(named: 'picture'),
        filePath: captureAny(named: 'filePath'),
        title: captureAny(named: 'title'),
        totalPages: captureAny(named: 'totalPages'),
        isReading: captureAny(named: 'isReading'),
        isCompleted: captureAny(named: 'isCompleted'),
        author: captureAny(named: 'author'),
        genre: captureAny(named: 'genre'),
        collection: captureAny(named: 'collection'),
        comicType: captureAny(named: 'comicType'),
      )).captured;
  const keys = [
    'id',
    'imagesPath',
    'picture',
    'filePath',
    'title',
    'totalPages',
    'isReading',
    'isCompleted',
    'author',
    'genre',
    'collection',
    'comicType',
  ];
  final result = <Map<String, Object?>>[];
  for (var i = 0; i < calls.length; i += keys.length) {
    result.add({
      for (var k = 0; k < keys.length; k++) keys[k]: calls[i + k],
    });
  }
  return result;
}
