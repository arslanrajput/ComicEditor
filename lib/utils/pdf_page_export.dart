import 'dart:typed_data';



import 'package:flutter/material.dart';

import 'package:pdf/widgets.dart' as pw;



import '../PanelModel/Project.dart';

import '../PreviewPdf/PDFPageFormat.dart';

import 'page_canvas_builder.dart';

import 'widget_capture.dart';



/// Exports all project pages to a PDF document.

///

/// Panel [x]/[y]/[width]/[height] values are stored in editor (display) space.

/// They are scaled up to fill the full PDF page before capture.

Future<Uint8List> exportPagesToPdf({

  required BuildContext context,

  required List<List<LayoutPanel>> pages,

  String pageFormatKey = 'A4',

  double pixelRatio = 3.0,

}) async {

  final pdfFormat = PDFPageFormat.pdfPageFormat(pageFormatKey);

  final pageWidth = pdfFormat.width;

  final pageHeight = pdfFormat.height;

  final pdf = pw.Document();



  for (final pagePanels in pages) {

    final scaledPanels =

        PageCanvasBuilder.scalePanelsForExport(pagePanels, pageFormatKey);



    final pageWidget = PageCanvasBuilder.build(

      panels: scaledPanels,

      canvasWidth: pageWidth,

      canvasHeight: pageHeight,

      forExport: true,

    );



    final imageBytes = await renderWidgetToImage(

      context,

      pageWidget,

      width: pageWidth,

      height: pageHeight,

      pixelRatio: pixelRatio,

    );



    // PNG pixels are much larger than PDF points; FittedBox maps the full bitmap

    // onto the page without cropping the right/bottom edges.

    final imageDpi = 72.0 * pixelRatio;

    final imageProvider = pw.MemoryImage(imageBytes, dpi: imageDpi);



    pdf.addPage(

      pw.Page(

        pageFormat: pdfFormat,

        margin: pw.EdgeInsets.zero,

        build: (context) => pw.SizedBox(

          width: pageWidth,

          height: pageHeight,

          child: pw.FittedBox(

            fit: pw.BoxFit.contain,

            child: pw.Image(

              imageProvider,

              dpi: imageDpi,

            ),

          ),

        ),

      ),

    );

  }



  return pdf.save();

}

