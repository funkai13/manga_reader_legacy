import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeoConstants', () {
    test('values match neobrutalist design tokens', () {
      expect(NeoConstants.borderWidth, 2.0);
      expect(NeoConstants.shadowOffset, const Offset(2.5, 2.5));
      expect(NeoConstants.borderRadius, 3.0);
      expect(NeoConstants.cardElevation, 0);
      expect(NeoConstants.animationDuration, const Duration(milliseconds: 150));
    });
  });

  group('ImageCacheConfig', () {
    test('default constants are sized for mobile memory safety', () {
      expect(ImageCacheConfig.maxCacheEntries, 150);
      expect(ImageCacheConfig.maxCacheBytes, 128 * 1024 * 1024);
    });

    test('configure sets imageCache limits to defaults', () {
      ImageCacheConfig.configure();
      expect(PaintingBinding.instance.imageCache.maximumSize, 150);
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes,
          128 * 1024 * 1024);
    });

    test('configure allows custom override parameters', () {
      ImageCacheConfig.configure(
        maxCount: 200,
        maxSizeBytes: 64 * 1024 * 1024,
      );
      expect(PaintingBinding.instance.imageCache.maximumSize, 200);
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes,
          64 * 1024 * 1024);

      // Restore defaults
      ImageCacheConfig.configure();
    });
  });
}
