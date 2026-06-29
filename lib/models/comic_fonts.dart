import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Comic-friendly font families available in the editor.
class ComicFonts {
  ComicFonts._();

  static const List<String> families = [
    'Roboto',
    'Comic Neue',
    'Bangers',
    'Permanent Marker',
    'Bubblegum Sans',
    'Arial',
    'Impact',
    'Courier New',
  ];

  static TextStyle style({
    required String family,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
    double? strokeWidth,
    Color? strokeColor,
  }) {
    TextStyle base;
    switch (family) {
      case 'Comic Neue':
        base = GoogleFonts.comicNeue(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        );
      case 'Bangers':
        base = GoogleFonts.bangers(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        );
      case 'Permanent Marker':
        base = GoogleFonts.permanentMarker(
          fontSize: fontSize,
          color: color,
          fontStyle: fontStyle,
        );
      case 'Bubblegum Sans':
        base = GoogleFonts.bubblegumSans(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        );
      default:
        base = TextStyle(
          fontFamily: family,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        );
    }

    if (strokeWidth != null && strokeWidth > 0 && strokeColor != null) {
      return base.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = strokeColor,
      ).copyWith(color: color);
    }
    return base;
  }
}
