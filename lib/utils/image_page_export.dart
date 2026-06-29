import 'dart:typed_data';



import 'package:flutter/material.dart';

import 'package:share_plus/share_plus.dart';



import '../PanelModel/Project.dart';

import '../PreviewPdf/PDFPageFormat.dart';

import '../services/app_settings.dart';

import 'page_canvas_builder.dart';

import 'widget_capture.dart';



/// Renders project pages to PNG bytes and shares via the system sheet.

Future<void> sharePagesAsPng({

  required BuildContext context,

  required List<List<LayoutPanel>> pages,

  required String projectName,

  String pageFormatKey = 'A4',

}) async {

  final pixelRatio = AppSettings.exportPixelRatio;

  final pdfFormat = PDFPageFormat.pdfPageFormat(pageFormatKey);

  final pageWidth = pdfFormat.width;

  final pageHeight = pdfFormat.height;



  final files = <XFile>[];

  for (var i = 0; i < pages.length; i++) {

    final scaledPanels =

        PageCanvasBuilder.scalePanelsForExport(pages[i], pageFormatKey);

    final pageWidget = PageCanvasBuilder.build(

      panels: scaledPanels,

      canvasWidth: pageWidth,

      canvasHeight: pageHeight,

      forExport: true,

    );

    final bytes = await renderWidgetToImage(

      context,

      pageWidget,

      width: pageWidth,

      height: pageHeight,

      pixelRatio: pixelRatio,

    );

    files.add(XFile.fromData(

      bytes,

      mimeType: 'image/png',

      name: '${_safeName(projectName)}_page_${i + 1}.png',

    ));

  }



  await Share.shareXFiles(

    files,

    text: '$projectName — ${pages.length} page(s)',

  );

}



/// Exports a single page index as PNG bytes.

Future<Uint8List> renderPageToPng({

  required BuildContext context,

  required List<LayoutPanel> pagePanels,

  String pageFormatKey = 'A4',

  double? pixelRatio,

}) async {

  final ratio = pixelRatio ?? AppSettings.exportPixelRatio;

  final pdfFormat = PDFPageFormat.pdfPageFormat(pageFormatKey);

  final pageWidth = pdfFormat.width;

  final pageHeight = pdfFormat.height;

  final scaledPanels =

      PageCanvasBuilder.scalePanelsForExport(pagePanels, pageFormatKey);



  return renderWidgetToImage(

    context,

    PageCanvasBuilder.build(

      panels: scaledPanels,

      canvasWidth: pageWidth,

      canvasHeight: pageHeight,

      forExport: true,

    ),

    width: pageWidth,

    height: pageHeight,

    pixelRatio: ratio,

  );

}



String _safeName(String name) =>

    name.replaceAll(RegExp(r'[^\w\-]+'), '_').replaceAll(RegExp(r'_+'), '_');

