import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../PanelModel/PanelElementModel.dart';
import '../PanelModel/Project.dart';
import '../PreviewPdf/PDFPageFormat.dart';
import '../theme/comic_theme.dart';
import '../widgets/panel_content_preview.dart';

/// Must match [PanelLayoutEditorScreen] page margin so export maps edge-to-edge.
const double kEditorPageMargin = 10.0;

/// Inner padding so panel borders are not clipped at canvas edges (reader/preview).
const double kCanvasBleed = 6.0;

/// Builds a full comic page canvas for preview and PDF export.
class PageCanvasBuilder {
  static Widget build({
    required List<LayoutPanel> panels,
    required double canvasWidth,
    required double canvasHeight,
    Color canvasColor = Colors.white,
    bool forExport = false,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: ColoredBox(
          color: canvasColor,
          child: Stack(
            clipBehavior: Clip.none,
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
                child: Container(
                  width: panel.width,
                  height: panel.height,
                  decoration: forExport
                      ? ComicTheme.comicPanelFrameExport()
                      : ComicTheme.comicPanelFrame(selected: false),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: PanelPreviewTile(panel: panel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Maps editor layout (with margins) onto a target canvas edge-to-edge.
  static List<LayoutPanel> scalePanelsEdgeToEdge(
    List<LayoutPanel> panels, {
    required double editorCanvasWidth,
    required double editorCanvasHeight,
    required double targetWidth,
    required double targetHeight,
  }) {
    final srcW = editorCanvasWidth - 2 * kEditorPageMargin;
    final srcH = editorCanvasHeight - 2 * kEditorPageMargin;
    final scaleX = targetWidth / srcW;
    final scaleY = targetHeight / srcH;
    final scale = math.min(scaleX, scaleY);

    final scaled = panels
        .map(
          (p) => LayoutPanel(
            id: p.id,
            label: p.label,
            x: math.max(0, (p.x - kEditorPageMargin) * scale),
            y: math.max(0, (p.y - kEditorPageMargin) * scale),
            width: p.width * scale,
            height: p.height * scale,
            customText: p.customText,
            backgroundColor: p.backgroundColor,
            previewImage: p.previewImage,
            elements: p.elements
                .map((e) => _scaleElementForExport(e, scale))
                .toList(),
          ),
        )
        .toList();

    return _fitPanelsToPage(scaled, targetWidth, targetHeight);
  }

  /// Maps editor layout coordinates to full PDF page size (edge-to-edge).
  static List<LayoutPanel> scalePanelsForExport(
    List<LayoutPanel> panels,
    String formatKey,
  ) {
    final editor = PDFPageFormat.formats[formatKey] ?? PDFPageFormat.formats['A4']!;
    final page = PDFPageFormat.exportSize(formatKey);
    return scalePanelsEdgeToEdge(
      panels,
      editorCanvasWidth: editor.width,
      editorCanvasHeight: editor.height,
      targetWidth: page.width,
      targetHeight: page.height,
    );
  }

  /// Maps editor layout to on-screen reader/preview size (edge-to-edge).
  static List<LayoutPanel> scalePanelsForReader(
    List<LayoutPanel> panels,
    String formatKey,
  ) {
    final editor = PDFPageFormat.formats[formatKey] ?? PDFPageFormat.formats['A4']!;
    return scalePanelsEdgeToEdge(
      panels,
      editorCanvasWidth: editor.width,
      editorCanvasHeight: editor.height,
      targetWidth: editor.width,
      targetHeight: editor.height,
    );
  }

  /// Builds a page widget that scales to fit [maxWidth] x [maxHeight] without clipping.
  static Widget buildFittedPage({
    required List<LayoutPanel> panels,
    required String formatKey,
    required double maxWidth,
    required double maxHeight,
    bool flatFrames = true,
  }) {
    final editor = PDFPageFormat.formats[formatKey] ?? PDFPageFormat.formats['A4']!;
    final aspect = editor.width / editor.height;

    var fitW = maxWidth;
    var fitH = fitW / aspect;
    if (fitH > maxHeight) {
      fitH = maxHeight;
      fitW = fitH * aspect;
    }

    final contentW = math.max(1.0, fitW - 2 * kCanvasBleed);
    final contentH = math.max(1.0, fitH - 2 * kCanvasBleed);

    final scaledPanels = scalePanelsEdgeToEdge(
      panels,
      editorCanvasWidth: editor.width,
      editorCanvasHeight: editor.height,
      targetWidth: contentW,
      targetHeight: contentH,
    );

    return SizedBox(
      width: fitW,
      height: fitH,
      child: Padding(
        padding: const EdgeInsets.all(kCanvasBleed),
        child: build(
          panels: scaledPanels,
          canvasWidth: contentW,
          canvasHeight: contentH,
          forExport: flatFrames,
        ),
      ),
    );
  }

  /// Shrinks or shifts layout so all panels stay inside the canvas.
  static List<LayoutPanel> _fitPanelsToPage(
    List<LayoutPanel> panels,
    double pageW,
    double pageH,
  ) {
    if (panels.isEmpty) return panels;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxRight = 0.0;
    var maxBottom = 0.0;
    for (final p in panels) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      maxRight = math.max(maxRight, p.x + p.width);
      maxBottom = math.max(maxBottom, p.y + p.height);
    }

    var working = panels;
    if (minX < 0 || minY < 0) {
      final dx = minX < 0 ? -minX : 0.0;
      final dy = minY < 0 ? -minY : 0.0;
      working = working
          .map(
            (p) => LayoutPanel(
              id: p.id,
              label: p.label,
              x: p.x + dx,
              y: p.y + dy,
              width: p.width,
              height: p.height,
              customText: p.customText,
              backgroundColor: p.backgroundColor,
              previewImage: p.previewImage,
              elements: p.elements,
            ),
          )
          .toList();
      maxRight += dx;
      maxBottom += dy;
    }

    const safety = 1.0;
    final limitW = pageW - safety;
    final limitH = pageH - safety;
    if (maxRight <= limitW && maxBottom <= limitH) return working;

    final shrink = math.min(limitW / maxRight, limitH / maxBottom);
    return working.map((p) => _scalePanelFromOrigin(p, shrink)).toList();
  }

  static LayoutPanel _scalePanelFromOrigin(LayoutPanel panel, double factor) {
    return LayoutPanel(
      id: panel.id,
      label: panel.label,
      x: panel.x * factor,
      y: panel.y * factor,
      width: panel.width * factor,
      height: panel.height * factor,
      customText: panel.customText,
      backgroundColor: panel.backgroundColor,
      previewImage: panel.previewImage,
      elements: panel.elements
          .map((e) => _scaleElementForExport(e, factor))
          .toList(),
    );
  }

  static PanelElementModel _scaleElementForExport(
    PanelElementModel element,
    double scale,
  ) {
    return element.copyWith(
      offset: Offset(element.offset.dx * scale, element.offset.dy * scale),
      width: element.width * scale,
      height: element.height * scale,
      size: Size(element.width * scale, element.height * scale),
      fontSize: element.fontSize != null ? element.fontSize! * scale : null,
    );
  }
}
