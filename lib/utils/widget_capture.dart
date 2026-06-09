import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders a widget off-screen and captures it as a PNG byte array.
Future<Uint8List> renderWidgetToImage(
  BuildContext context,
  Widget widget, {
  Duration settleDelay = const Duration(milliseconds: 300),
  int maxRetries = 10,
  double pixelRatio = 3.0,
}) async {
  final repaintKey = GlobalKey();

  final overlayEntry = OverlayEntry(
    builder: (context) => Center(
      child: RepaintBoundary(
        key: repaintKey,
        child: widget,
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  await Future.delayed(settleDelay);
  await WidgetsBinding.instance.endOfFrame;

  RenderRepaintBoundary? boundary;
  var retries = 0;
  while (retries < maxRetries) {
    await Future.delayed(const Duration(milliseconds: 100));
    boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null && !boundary.debugNeedsPaint) break;
    retries++;
  }

  if (boundary == null || boundary.debugNeedsPaint) {
    overlayEntry.remove();
    throw Exception('Widget is not fully painted after retries.');
  }

  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  overlayEntry.remove();

  return byteData!.buffer.asUint8List();
}
