import 'package:flutter/material.dart';

import 'DrawingToolsPanel.dart';
import 'stroke_renderer.dart';

class DrawingElementPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  DrawingElementPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.tool = DrawingTool.pen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nonZeroPoints = points.where((p) => p != Offset.zero).toList();
    if (nonZeroPoints.isEmpty) return;

    final minX = nonZeroPoints.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final minY = nonZeroPoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final maxX = nonZeroPoints.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final maxY = nonZeroPoints.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    final originalWidth = maxX - minX;
    final originalHeight = maxY - minY;
    if (originalWidth < 1e-6 && originalHeight < 1e-6) return;

    final scaleX = originalWidth < 1e-6 ? 1.0 : size.width / originalWidth;
    final scaleY = originalHeight < 1e-6 ? 1.0 : size.height / originalHeight;

    final scaled = <Offset>[
      for (final p in points)
        if (p != Offset.zero)
          Offset(
            (p.dx - minX) * scaleX,
            (p.dy - minY) * scaleY,
          ),
    ];

    if (scaled.isEmpty) return;

    final paint = paintForDrawingTool(
      tool: tool,
      color: color,
      strokeWidth: strokeWidth,
    );

    drawSmoothStroke(canvas, scaled, paint);
  }

  @override
  bool shouldRepaint(DrawingElementPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.tool != tool;
}
