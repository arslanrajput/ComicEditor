import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../PanelModel/PanelElementModel.dart';
import '../SpeechDrag/DragSpeechBubbleComponents.dart';
import '../SpeechDrag/DragSpeechBubbleData.dart';
import '../SpeechDrag/SpeechBubblePainterWithText.dart';

/// Rasterizes a speech bubble to PNG bytes for placement on the canvas.
class SpeechBubbleRasterizer {
  SpeechBubbleRasterizer._();

  static Future<Map<String, dynamic>> rasterize({
    required DragSpeechBubbleData data,
    Size logicalSize = const Size(280, 180),
    double pixelRatio = 3.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    SpeechBubblePainterWithText(data).paint(canvas, logicalSize);
    final picture = recorder.endRecording();

    final widthPx = (logicalSize.width * pixelRatio).round();
    final heightPx = (logicalSize.height * pixelRatio).round();
    final bigImg = await picture.toImage(widthPx, heightPx);

    final bd = await bigImg.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) {
      final fullPng = await bigImg.toByteData(format: ui.ImageByteFormat.png);
      return {
        'bytes': fullPng!.buffer.asUint8List(),
        'logicalWidth': logicalSize.width,
        'logicalHeight': logicalSize.height,
      };
    }

    final bytes = bd.buffer.asUint8List();
    final stride = widthPx * 4;
    int minX = widthPx, minY = heightPx, maxX = -1, maxY = -1;

    for (int y = 0; y < heightPx; y++) {
      final row = y * stride;
      for (int x = 0; x < widthPx; x++) {
        final a = bytes[row + x * 4 + 3];
        if (a != 0) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      final fullPng = await bigImg.toByteData(format: ui.ImageByteFormat.png);
      return {
        'bytes': fullPng!.buffer.asUint8List(),
        'logicalWidth': logicalSize.width,
        'logicalHeight': logicalSize.height,
      };
    }

    final srcRect = Rect.fromLTWH(
      minX.toDouble(),
      minY.toDouble(),
      (maxX - minX + 1).toDouble(),
      (maxY - minY + 1).toDouble(),
    );

    final cropRecorder = ui.PictureRecorder();
    final cropCanvas = Canvas(cropRecorder);
    cropCanvas.drawImageRect(
      bigImg,
      srcRect,
      Rect.fromLTWH(0, 0, srcRect.width, srcRect.height),
      Paint(),
    );
    final croppedPic = cropRecorder.endRecording();
    final croppedImg = await croppedPic.toImage(
      srcRect.width.toInt(),
      srcRect.height.toInt(),
    );
    final png = await croppedImg.toByteData(format: ui.ImageByteFormat.png);

    return {
      'bytes': png!.buffer.asUint8List(),
      'logicalWidth': srcRect.width / pixelRatio,
      'logicalHeight': srcRect.height / pixelRatio,
    };
  }

  static Future<PanelElementModel> createElement({
    required String text,
    required Offset offset,
    double fontSize = 16,
    String fontFamily = 'Roboto',
    Color textColor = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
    String id = '',
  }) async {
    final bubbleData = DragSpeechBubbleData(
      text: text,
      bubbleColor: Colors.white,
      borderColor: Colors.black,
      borderWidth: 2,
      bubbleShape: DragBubbleShape.rectangle,
      tailOffset: const Offset(140, 120),
      padding: 12,
      fontSize: fontSize,
      textColor: textColor,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );

    final raster = await rasterize(data: bubbleData);
    final width = (raster['logicalWidth'] as num).toDouble();
    final height = (raster['logicalHeight'] as num).toDouble();
    final pngBytes = raster['bytes'] as Uint8List;

    return PanelElementModel(
      id: id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'speech_bubble',
      value: base64Encode(pngBytes),
      offset: offset,
      width: width,
      height: height,
      size: Size(width, height),
      meta: jsonEncode({
        'kind': 'speech_bubble_original',
        'data': bubbleData.toMap(),
      }),
    );
  }
}
