import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../Draw/DrawingElementPainter.dart';
import '../PanelModel/PanelElementModel.dart';
import '../PanelModel/Project.dart';

/// Read-only renderer for panel content (elements + background).
class PanelContentPreview extends StatelessWidget {
  final LayoutPanel panel;
  final double? width;
  final double? height;

  const PanelContentPreview({
    super.key,
    required this.panel,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? panel.width;
    final h = height ?? panel.height;

    return SizedBox(
      width: w,
      height: h,
      child: ColoredBox(
        color: panel.backgroundColor,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (panel.elements.isEmpty && panel.customText != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    panel.customText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
            else if (panel.elements.isEmpty)
              Center(
                child: Text(
                  panel.label ?? panel.id,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            for (final element in panel.elements)
              if (!element.hidden)
                Positioned(
                  left: element.offset.dx,
                  top: element.offset.dy,
                  child: SizedBox(
                    width: element.width,
                    height: element.height,
                    child: _buildElement(element),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static Widget _buildElement(PanelElementModel element) {
    switch (element.type) {
      case 'character':
      case 'clipart':
        return ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.asset(
              element.value,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        );

      case 'text':
        return Container(
          alignment: Alignment.center,
          child: Text(
            element.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: element.fontSize ?? 16,
              color: element.color ?? Colors.black,
              fontFamily: element.fontFamily,
              fontWeight: element.fontWeight ?? FontWeight.normal,
              fontStyle: element.fontStyle ?? FontStyle.normal,
            ),
          ),
        );

      case 'speech_bubble':
        return _buildMemoryImage(element);

      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.file(
              File(element.value),
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        );

      case 'Draw':
        final points = element.value.split(';').map((pair) {
          final coords = pair.split(',');
          return Offset(
            double.tryParse(coords[0]) ?? 0,
            double.tryParse(coords[1]) ?? 0,
          );
        }).toList();
        return CustomPaint(
          painter: DrawingElementPainter(
            points: points,
            color: element.color ?? Colors.black,
            strokeWidth: element.fontSize ?? 1.0,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  static Widget _buildMemoryImage(PanelElementModel element) {
    try {
      final bytes = base64Decode(element.value);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

/// Panel tile used in layout / preview stacks.
class PanelPreviewTile extends StatelessWidget {
  final LayoutPanel panel;

  const PanelPreviewTile({super.key, required this.panel});

  @override
  Widget build(BuildContext context) {
    if (panel.previewImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          panel.previewImage!,
          width: panel.width,
          height: panel.height,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: PanelContentPreview(panel: panel),
    );
  }
}
