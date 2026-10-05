import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';

/// Calculates the target decode width for a page: twice the screen width keeps it
/// sharp when zoomed without holding a full 4000 px scan (~100 MB) in memory.
double readerTargetDecodeWidth(BuildContext context) {
  final mediaQuery = MediaQuery.sizeOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return mediaQuery.width * dpr * 2;
}

/// Creates a decoded image provider at [targetWidth] pixels.
ImageProvider readerPageImageProvider(File file, double targetWidth) =>
    decodedAtWidth(FileImage(file), targetWidth);

/// Decode width for a page: twice the screen width keeps it sharp when
/// zoomed without holding a full 4000 px scan (~100 MB) in memory.
ImageProvider readerPageImage(BuildContext context, File file) =>
    readerPageImageProvider(file, readerTargetDecodeWidth(context));

/// One zoomable page. Double tap zooms into the tapped point and back;
/// leaving the page ([active] becomes false) resets the zoom.
class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.file,
    required this.active,
    required this.onZoomChanged,
    this.targetWidth,
  });

  final File file;
  final bool active;
  final double? targetWidth;

  /// Called only when the page goes from fit to zoomed or back, so the
  /// reader can lock page swipes while panning a zoomed page.
  final ValueChanged<bool> onZoomChanged;

  static const maxScale = 4.0;
  static const doubleTapScale = 2.5;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..addListener(_onAnimationTick);
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
  }

  @override
  void didUpdateWidget(covariant ReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active && _zoomed) {
      _animation.stop();
      _transform.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged(zoomed);
    }
  }

  void _onAnimationTick() {
    final animation = _zoomAnimation;
    if (animation != null) _transform.value = animation.value;
  }

  void _onDoubleTap() {
    final Matrix4 target;
    if (_zoomed) {
      target = Matrix4.identity();
    } else {
      // Keep the tapped point under the finger while zooming in.
      const s = ReaderPage.doubleTapScale;
      final focal = _doubleTapPosition;
      target = Matrix4.identity()
        ..translateByDouble(-focal.dx * (s - 1), -focal.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }
    _zoomAnimation = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _animation, curve: Curves.easeOut));
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = widget.targetWidth != null && widget.targetWidth! > 0
        ? readerPageImageProvider(widget.file, widget.targetWidth!)
        : readerPageImage(context, widget.file);

    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: ReaderPage.maxScale,
        child: SizedBox.expand(
          child: Image(
            image: imageProvider,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                const _BrokenPage(),
          ),
        ),
      ),
    );
  }
}

class _BrokenPage extends StatelessWidget {
  const _BrokenPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
          SizedBox(height: 8),
          Text('No se pudo mostrar esta página',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
