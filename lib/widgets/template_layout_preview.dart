import 'package:comic_editor/models/template_layout_preview_data.dart';
import 'package:comic_editor/theme/comic_theme.dart';
import 'package:flutter/material.dart';

/// Mini page thumbnail showing panel layout shapes for a template.
class TemplateLayoutPreview extends StatelessWidget {
  final String templateId;
  final Color accentColor;
  final double? width;
  final double? height;
  final bool showPageBorder;

  const TemplateLayoutPreview({
    super.key,
    required this.templateId,
    required this.accentColor,
    this.width,
    this.height,
    this.showPageBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final panels = previewPanelsForTemplate(templateId);
    final isBlank = templateId.isEmpty;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _TemplateLayoutPainter(
          panels: panels,
          accentColor: accentColor,
          showPageBorder: showPageBorder,
          isBlank: isBlank,
        ),
      ),
    );
  }
}

class _TemplateLayoutPainter extends CustomPainter {
  final List<PreviewPanel> panels;
  final Color accentColor;
  final bool showPageBorder;
  final bool isBlank;

  _TemplateLayoutPainter({
    required this.panels,
    required this.accentColor,
    required this.showPageBorder,
    required this.isBlank,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pageRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final inset = Rect.fromLTRB(
      pageRect.left + 1,
      pageRect.top + 1,
      pageRect.right - 1,
      pageRect.bottom - 1,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, const Radius.circular(4)),
      Paint()..color = Colors.white,
    );

    if (showPageBorder) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(inset, const Radius.circular(4)),
        Paint()
          ..color = ComicTheme.panelBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    if (isBlank) {
      final cx = size.width / 2;
      final cy = size.height / 2;
      final plusPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.45)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx - 8, cy),
        Offset(cx + 8, cy),
        plusPaint,
      );
      canvas.drawLine(
        Offset(cx, cy - 8),
        Offset(cx, cy + 8),
        plusPaint,
      );
      return;
    }

    final fillPaint = Paint()..color = accentColor.withValues(alpha: 0.22);
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final panel in panels) {
      final rect = Rect.fromLTRB(
        inset.left + panel.left * inset.width,
        inset.top + panel.top * inset.height,
        inset.left + panel.right * inset.width,
        inset.top + panel.bottom * inset.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TemplateLayoutPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.isBlank != isBlank ||
        oldDelegate.panels != panels;
  }
}
