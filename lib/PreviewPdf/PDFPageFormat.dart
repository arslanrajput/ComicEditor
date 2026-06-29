import 'dart:ui' show Size;

import 'package:pdf/pdf.dart';

class PDFPageFormat {
  /// Must match [PdfPageFormat.a4] / [PdfPageFormat.letter] exactly so export
  /// does not crop when the raster image is placed on the PDF page.
  static const double A4_WIDTH = 595.28;
  static const double A4_HEIGHT = 841.89;
  static const double LETTER_WIDTH = 612.0;
  static const double LETTER_HEIGHT = 792.0;

  static const double DISPLAY_SCALE = 0.6;

  static Map<String, Size> get formats => {
        'A4': Size(A4_WIDTH * DISPLAY_SCALE, A4_HEIGHT * DISPLAY_SCALE),
        'Letter': Size(LETTER_WIDTH * DISPLAY_SCALE, LETTER_HEIGHT * DISPLAY_SCALE),
      };

  static double get aspectRatioA4 => A4_WIDTH / A4_HEIGHT;

  static ({double width, double height}) exportSize(String format) {
    switch (format) {
      case 'Letter':
        return (width: LETTER_WIDTH, height: LETTER_HEIGHT);
      default:
        return (width: A4_WIDTH, height: A4_HEIGHT);
    }
  }

  /// Scale factor from on-screen layout coordinates to PDF export coordinates.
  static double exportScale(String format) {
    final editor = formats[format] ?? formats['A4']!;
    final export = exportSize(format);
    return export.width / editor.width;
  }

  static PdfPageFormat pdfPageFormat(String format) {
    switch (format) {
      case 'Letter':
        return PdfPageFormat.letter;
      default:
        return PdfPageFormat.a4;
    }
  }
}
