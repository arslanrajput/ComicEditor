import 'package:flutter/material.dart';

import '../PanelModel/Project.dart';
import '../widgets/panel_content_preview.dart';

/// Builds a full comic page canvas for preview and PDF export.
class PageCanvasBuilder {
  static Widget build({
    required List<LayoutPanel> panels,
    required double canvasWidth,
    required double canvasHeight,
    Color canvasColor = const Color(0xFFEEEEEE),
  }) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: canvasWidth,
        height: canvasHeight,
        color: canvasColor,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (panels.isEmpty)
              const Center(
                child: Text(
                  'Empty Page',
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                ),
              ),
            for (final panel in panels)
              Positioned(
                left: panel.x,
                top: panel.y,
                child: SizedBox(
                  width: panel.width,
                  height: panel.height,
                  child: PanelPreviewTile(panel: panel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
