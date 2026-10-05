import 'package:flutter/material.dart';

class NeoConstants {
  static const double borderWidth = 2.5;
  static const Offset shadowOffset = Offset(4, 4);
  static const double borderRadius = 8.0;
  static const double cardElevation = 0;
  static const Duration animationDuration = Duration(milliseconds: 200);
}

class ImageCacheConfig {
  /// Maximum number of image entries kept in cache (Flutter default is 1000).
  /// Sized for low-end to mid-range devices to prevent memory exhaustion.
  static const int maxCacheEntries = 150;

  /// Maximum byte size for the image cache (128 MB).
  static const int maxCacheBytes = 128 * 1024 * 1024;

  /// Configures PaintingBinding.instance.imageCache with active memory limits.
  static void configure({int? maxCount, int? maxSizeBytes}) {
    PaintingBinding.instance.imageCache.maximumSize =
        maxCount ?? maxCacheEntries;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        maxSizeBytes ?? maxCacheBytes;
  }
}
