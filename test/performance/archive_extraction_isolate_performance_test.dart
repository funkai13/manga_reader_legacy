import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:manga_reader/feature/Home/data/services/comic_archive_extractor.dart';
import 'package:path/path.dart' as p;
import '../unit/helpers/archive_builder.dart';

void main() {
  late Directory tempDir;
  late Directory outputDir;
  const extractor = ComicArchiveExtractor();

  setUp(() {
    tempDir = createTempDir('archive_perf_in_');
    outputDir = createTempDir('archive_perf_out_');
  });

  tearDown(() {
    deleteQuietly(tempDir);
    deleteQuietly(outputDir);
  });

  test('Benchmark: Large archive (50 pages) background isolate decompression and thumbnailing', () async {
    // Generate 50 realistic image pages
    final sampleImg = img.Image(width: 200, height: 300);
    img.fill(sampleImg, color: img.ColorRgb8(100, 150, 200));
    final sampleJpgBytes = img.encodeJpg(sampleImg, quality: 75);

    final entries = <String, Object?>{
      'ComicInfo.xml': comicInfoXml(
        title: 'Performance Benchmark Comic',
        writer: 'Performance Tester',
        series: 'Isolate Benchmark Series',
        manga: 'Yes',
      ),
    };

    for (var i = 1; i <= 50; i++) {
      final name = 'page_${i.toString().padLeft(3, '0')}.jpg';
      entries[name] = sampleJpgBytes;
    }

    final archiveFile = buildArchive(tempDir, 'benchmark_comic.cbz', entries);
    expect(archiveFile.existsSync(), isTrue);

    final stopwatch = Stopwatch()..start();
    final result = await extractor.extract(archiveFile.path, outputDir.path);
    stopwatch.stop();

    // Verify all 50 pages extracted in natural order
    expect(result.pages.length, 50);
    expect(p.basename(result.pages.first), '0001.jpg');
    expect(p.basename(result.pages.last), '0050.jpg');

    // Verify thumbnail generation in isolate
    expect(result.thumbnail, isNotNull);
    expect(File(result.thumbnail!).existsSync(), isTrue);

    // Verify ComicInfo metadata was parsed
    expect(result.info?.title, 'Performance Benchmark Comic');
    expect(result.info?.comicType, 'Manga');

    // Extraction, image decoding, and resizing of 50 pages in background isolate completes rapidly
    expect(stopwatch.elapsedMilliseconds, lessThan(10000));
  });
}
