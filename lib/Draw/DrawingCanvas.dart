import 'package:flutter/material.dart';

import 'DrawingToolsPanel.dart';
import 'stroke_renderer.dart';

class DrawingCanvas extends StatefulWidget {
  final DrawingTool tool;
  final Color color;
  final double brushSize;
  final ValueChanged<List<Offset>> onDrawingComplete;

  const DrawingCanvas({
    super.key,
    required this.tool,
    required this.color,
    required this.brushSize,
    required this.onDrawingComplete,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset> _points = [];

  void _addPoint(Offset point) {
    if (_points.isEmpty || (point - _points.last).distance >= 1.2) {
      setState(() => _points = [..._points, point]);
    }
  }

  void _finishStroke() {
    if (_points.isEmpty) return;
    widget.onDrawingComplete(filterStrokePoints(_points));
    setState(() => _points = []);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _addPoint(event.localPosition),
      onPointerMove: (event) {
        if (event.down) _addPoint(event.localPosition);
      },
      onPointerUp: (_) => _finishStroke(),
      onPointerCancel: (_) => _finishStroke(),
      child: CustomPaint(
        painter: _DrawingPainter(
          points: _points,
          color: widget.color,
          brushSize: widget.brushSize,
          tool: widget.tool,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double brushSize;
  final DrawingTool tool;

  _DrawingPainter({
    required this.points,
    required this.color,
    required this.brushSize,
    required this.tool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    if (tool == DrawingTool.eraser) {
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.35)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = brushSize
        ..isAntiAlias = true;
      drawSmoothStroke(canvas, points, paint);
      return;
    }

    final paint = paintForDrawingTool(
      tool: tool,
      color: color,
      strokeWidth: brushSize,
    );
    drawSmoothStroke(canvas, points, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.brushSize != brushSize ||
      oldDelegate.tool != tool;
}
