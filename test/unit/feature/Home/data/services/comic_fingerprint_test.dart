import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/services/comic_fingerprint.dart';
import 'package:path/path.dart' as p;

import '../../../../helpers/archive_builder.dart';

void main() {
  late Directory dir;
  const fingerprint = ComicFingerprint();
  // Tiny chunks so "head", "middle" and "tail" are easy to hit.
  const small = ComicFingerprint(chunkSize: 4);

  setUp(() => dir = createTempDir('fingerprint_'));
  tearDown(() => deleteQuietly(dir));

  File write(String name, List<int> bytes) =>
      writeRawFile(dir, name, bytes);

  List<int> bytes(int length, [int seed = 0]) =>
      List<int>.generate(length, (i) => (i * 31 + seed) % 256);

  test('same content under different names -> same hash', () async {
    final a = write('one.cbz', bytes(300000));
    final b = write('renamed copy.cbr', bytes(300000));
    expect(await fingerprint.of(a.path), await fingerprint.of(b.path));
  });

  test('different content with the same name -> different hash', () async {
    final a = write('same.cbz', bytes(1000, 1));
    final other = Directory(p.join(dir.path, 'other'))..createSync();
    final b = writeRawFile(other, 'same.cbz', bytes(1000, 2));
    expect(await fingerprint.of(a.path),
        isNot(await fingerprint.of(b.path)));
  });

  test('is a 40-char SHA-1 hex digest', () async {
    final hash = await fingerprint.of(write('a.cbz', bytes(10)).path);
    expect(hash, matches(RegExp(r'^[0-9a-f]{40}$')));
  });

  test('hashes size + head + tail only', () async {
    final data = bytes(20);
    final base = await small.of(write('base', data).path);

    final middle = [...data]..[10] ^= 0xFF;
    expect(await small.of(write('middle', middle).path), base,
        reason: 'bytes between head and tail are not read');

    final head = [...data]..[0] ^= 0xFF;
    expect(await small.of(write('head', head).path), isNot(base));

    final tail = [...data]..[19] ^= 0xFF;
    expect(await small.of(write('tail', tail).path), isNot(base));

    expect(await small.of(write('longer', [...data, 0]).path), isNot(base));
  });

  test('small files hash every byte once, plus the size', () async {
    final data = bytes(6); // head 4 + remaining 2 with chunkSize 4
    final expected = sha1.convert([0, 0, 0, 0, 0, 0, 0, 6, ...data]);
    expect(await small.of(write('small', data).path), expected.toString());
  });

  test('empty files are fingerprinted', () async {
    final expected = sha1.convert(List<int>.filled(8, 0));
    expect(
        await fingerprint.of(write('empty', []).path), expected.toString());
  });

  test('missing file: of throws, tryOf returns null', () async {
    final missing = p.join(dir.path, 'ghost.cbz');
    await expectLater(
        fingerprint.of(missing), throwsA(isA<FileSystemException>()));
    expect(await fingerprint.tryOf(missing), isNull);
  });
}
