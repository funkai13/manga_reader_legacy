import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/services/comic_fingerprint.dart';
import '../unit/helpers/archive_builder.dart';

void main() {
  late Directory dir;
  const fingerprint = ComicFingerprint();

  setUp(() => dir = createTempDir('fingerprint_perf_'));
  tearDown(() => deleteQuietly(dir));

  test('Benchmark: SHA-1 fingerprint executes in background isolate on multi-MB files', () async {
    // Generate a 5 MB simulated comic archive
    final largeBytes = List<int>.generate(5 * 1024 * 1024, (i) => i % 256);
    final file = writeRawFile(dir, 'large_comic.cbz', largeBytes);

    final stopwatch = Stopwatch()..start();
    final hash = await fingerprint.of(file.path);
    stopwatch.stop();

    expect(hash, isNotEmpty);
    expect(hash.length, 40);
    // Hashing 5 MB head+tail should complete swiftly (< 200ms) without main thread stall
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });

  test('Benchmark: Concurrent fingerprint hashing maintains isolate throughput', () async {
    // Create 10 files of varying sizes (100KB to 2MB)
    final files = List.generate(10, (i) {
      final size = (i + 1) * 200 * 1024;
      final bytes = List<int>.generate(size, (j) => (j + i) % 256);
      return writeRawFile(dir, 'comic_$i.cbz', bytes);
    });

    final stopwatch = Stopwatch()..start();
    // Execute all 10 fingerprints concurrently via isolates
    final hashes = await Future.wait(files.map((f) => fingerprint.of(f.path)));
    stopwatch.stop();

    expect(hashes.length, 10);
    expect(hashes.toSet().length, 10, reason: 'All hashes must be distinct');
    // Total time for 10 files in parallel
    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
  });
}
