import 'dart:io';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';

import 'package:flutter/material.dart';

class ComicPage extends StatefulWidget {
  final File image;
  final Function(double) onScaleChanged;
  final double initialScale;

  const ComicPage({
    super.key,
    required this.image,
    required this.onScaleChanged,
    required this.initialScale,
  });

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  late Offset _doubleTapLocalPosition = Offset.zero;
  final double minScale = 1.0;
  final double maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);
    _transformationController.value = Matrix4.identity()
      ..scale(widget.initialScale);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    widget.onScaleChanged(scale);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _animateTransition(Matrix4 endMatrix) {
    final animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    animation.addListener(() {
      _transformationController.value = animation.value;
    });
    _animationController.forward(from: 0);
  }

  void _onDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = currentScale <= minScale ? maxScale : minScale;

    final newMatrix = Matrix4.identity()
      ..translate(
        -_doubleTapLocalPosition.dx * (targetScale - 1),
        -_doubleTapLocalPosition.dy * (targetScale - 1),
      )
      ..scale(targetScale);
    _animateTransition(newMatrix);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onDoubleTapDown: (details) {
        _doubleTapLocalPosition = details.localPosition;
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(20),
        maxScale: maxScale,
        minScale: minScale,
        onInteractionUpdate: (_) => widget.onScaleChanged(
          _transformationController.value.getMaxScaleOnAxis(),
        ),
        // Decode at twice the screen width: sharp when zoomed, but a 4000 px
        // scan no longer takes ~100 MB of memory per page.
        child: Image(
          image: decodedAtWidth(
            FileImage(widget.image),
            MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context) *
                2,
          ),
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
