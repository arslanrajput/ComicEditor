import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../PanelModel/Project.dart';
import 'page_canvas_builder.dart';
import 'widget_capture.dart';

/// Exports all project pages to a PDF document.
Future<Uint8List> exportPagesToPdf({
  required BuildContext context,
  required List<List<LayoutPanel>> pages,
  required double canvasWidth,
  required double canvasHeight,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) async {
  final pdf = pw.Document();

  for (final pagePanels in pages) {
    final pageWidget = PageCanvasBuilder.build(
      panels: pagePanels,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );

    final imageBytes = await renderWidgetToImage(context, pageWidget);
    final imageProvider = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Center(
          child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  return pdf.save();
}
