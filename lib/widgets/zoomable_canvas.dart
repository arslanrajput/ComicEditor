import 'package:flutter/material.dart';

/// Pinch-to-zoom and pan wrapper for panel editing canvas.
class ZoomableCanvas extends StatelessWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const ZoomableCanvas({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: minScale,
      maxScale: maxScale,
      panEnabled: true,
      scaleEnabled: true,
      clipBehavior: Clip.none,
      boundaryMargin: const EdgeInsets.all(80),
      child: child,
    );
  }
}
