import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/reader_page.dart';
import 'package:manga_reader/feature/Reader/presenter/widgets/reader_view.dart';
import '../unit/helpers/archive_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late List<File> hundredPages;

  setUp(() {
    tempDir = createTempDir('reader_cache_test_');
    hundredPages = List.generate(100, (i) {
      final name = 'page_${(i + 1).toString().padLeft(4, '0')}.jpg';
      return writeRawFile(tempDir, name, [0xFF, 0xD8, 0xFF, 0xE0, i % 256]);
    });
  });

  tearDown(() {
    deleteQuietly(tempDir);
  });

  test('ImageCacheConfig bounds image cache limits to prevent OOM', () {
    ImageCacheConfig.configure(maxCount: 150, maxSizeBytes: 128 * 1024 * 1024);
    final cache = PaintingBinding.instance.imageCache;

    expect(cache.maximumSize, 150);
    expect(cache.maximumSizeBytes, 128 * 1024 * 1024);
  });

  testWidgets('evictFarPages evicts off-screen pages outside active window for 100+ page chapters',
      (tester) async {
    const targetWidth = 800.0;
    final evictedPages = <int>{};

    ImageProvider imageFor(int i) {
      final provider = readerPageImageProvider(hundredPages[i], targetWidth);
      return provider;
    }

    // Simulate user reading at page 50 of a 100-page comic
    const currentPage = 50;
    const keepRadius = 4;

    // Track which pages get evicted
    for (var i = 0; i < hundredPages.length; i++) {
      if ((i - currentPage).abs() > keepRadius) {
        evictedPages.add(i);
      }
    }

    evictFarPages(currentPage, hundredPages.length, imageFor, keepRadius: keepRadius);

    // Active pages (46 to 54) must NOT be evicted
    for (var i = currentPage - keepRadius; i <= currentPage + keepRadius; i++) {
      expect(evictedPages.contains(i), isFalse, reason: 'Page $i should remain in active window');
    }

    // Distant pages (0..45 and 55..99) must be evicted
    expect(evictedPages.contains(0), isTrue);
    expect(evictedPages.contains(45), isTrue);
    expect(evictedPages.contains(55), isTrue);
    expect(evictedPages.contains(99), isTrue);
    expect(evictedPages.length, 100 - (keepRadius * 2 + 1));
  });

  testWidgets('evictAllPages evicts all 100 pages and clears live images on reader exit',
      (tester) async {
    const targetWidth = 800.0;
    var evictionCount = 0;

    ImageProvider imageFor(int i) {
      evictionCount++;
      return readerPageImageProvider(hundredPages[i], targetWidth);
    }

    evictAllPages(hundredPages.length, imageFor);

    // Eviction must visit all 100 pages
    expect(evictionCount, 100);
    // Live images cache is cleaned
    expect(PaintingBinding.instance.imageCache.liveImageCount, 0);
  });
}
