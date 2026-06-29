import 'package:flutter/material.dart';

import 'DrawingToolsPanel.dart';

/// Builds a [Paint] tuned for each sketch tool.
Paint paintForDrawingTool({
  required DrawingTool tool,
  required Color color,
  required double strokeWidth,
}) {
  final paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..isAntiAlias = true;

  switch (tool) {
    case DrawingTool.pen:
      paint.color = color;
    case DrawingTool.pencil:
      paint.color = Color.lerp(color, Colors.grey, 0.15)!.withValues(alpha: 0.82);
      paint.strokeWidth = strokeWidth * 0.85;
    case DrawingTool.marker:
      paint.color = color.withValues(alpha: 0.55);
      paint.strokeWidth = strokeWidth * 1.15;
    case DrawingTool.eraser:
      paint.color = Colors.transparent;
      paint.blendMode = BlendMode.clear;
      paint.strokeWidth = strokeWidth;
  }

  return paint;
}

/// Filters noisy touch samples for a steadier hand-drawn line.
List<Offset> filterStrokePoints(List<Offset> raw, {double minDistance = 1.4}) {
  if (raw.isEmpty) return raw;
  final filtered = <Offset>[raw.first];
  for (var i = 1; i < raw.length; i++) {
    if ((raw[i] - filtered.last).distance >= minDistance) {
      filtered.add(raw[i]);
    }
  }
  if (filtered.length == 1 && raw.length > 1) {
    filtered.add(raw.last);
  }
  return filtered;
}

/// Draws a smooth stroke through [points] using quadratic curves.
void drawSmoothStroke(Canvas canvas, List<Offset> points, Paint paint) {
  if (points.isEmpty) return;

  if (points.length == 1) {
    canvas.drawCircle(points.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
    return;
  }

  if (points.length == 2) {
    canvas.drawLine(points[0], points[1], paint);
    return;
  }

  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length - 1; i++) {
    final mid = Offset(
      (points[i].dx + points[i + 1].dx) / 2,
      (points[i].dy + points[i + 1].dy) / 2,
    );
    path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
  canvas.drawPath(path, paint);
}

String drawingToolToMeta(DrawingTool tool) => tool.name;

DrawingTool drawingToolFromMeta(String? meta) {
  switch (meta) {
    case 'pencil':
      return DrawingTool.pencil;
    case 'marker':
      return DrawingTool.marker;
    case 'eraser':
      return DrawingTool.eraser;
    default:
      return DrawingTool.pen;
  }
}
