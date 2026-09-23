import 'dart:io';

import 'package:flutter/material.dart';

/// Shows an image file decoded at the size it is displayed, not at its full
/// resolution: a 2400x3600 scan takes ~34 MB decoded, a 140 px card ~1 MB.
class FileThumbnail extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Decode width in logical pixels when the layout width is unbounded.
  static const _fallbackWidth = 300.0;

  const FileThumbnail(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final logicalWidth = width ??
          (constraints.hasBoundedWidth ? constraints.maxWidth : _fallbackWidth);
      return Image(
        image: decodedAtWidth(
          FileImage(File(path)),
          logicalWidth * MediaQuery.devicePixelRatioOf(context),
        ),
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: errorBuilder,
      );
    });
  }
}

/// Wraps [provider] so it decodes at most [physicalWidth] pixels wide,
/// keeping the aspect ratio and never upscaling.
ImageProvider decodedAtWidth(ImageProvider provider, double physicalWidth) =>
    ResizeImage(
      provider,
      width: physicalWidth.ceil().clamp(1, 1 << 14),
      policy: ResizeImagePolicy.fit,
    );
