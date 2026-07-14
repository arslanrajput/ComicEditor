import 'package:flutter/material.dart';

import '../PanelModel/Project.dart';
import '../models/template_layout_preview_data.dart';

/// Builds [LayoutPanel]s from the same geometry used in template thumbnails.
List<LayoutPanel> layoutPanelsFromTemplate({
  required String templateId,
  required double pageWidth,
  required double pageHeight,
}) {
  final rects = previewPanelsForTemplate(templateId);
  if (rects.isEmpty) return [];

  return [
    for (var i = 0; i < rects.length; i++)
      LayoutPanel(
        id: panelLabelForTemplate(templateId, i, rects.length),
        x: rects[i].left * pageWidth,
        y: rects[i].top * pageHeight,
        width: (rects[i].right - rects[i].left) * pageWidth,
        height: (rects[i].bottom - rects[i].top) * pageHeight,
        backgroundColor: Colors.white,
      ),
  ];
}

String panelLabelForTemplate(String templateId, int index, int total) {
  switch (templateId) {
    case 'manga_page':
      const names = [
        'Scene 1',
        'Scene 2',
        'Scene 3',
        'Scene 4',
        'Scene 5',
        'Scene 6',
      ];
      return names[index.clamp(0, names.length - 1)];
    case 'single_splash':
      const names = ['Hero Splash', 'Action Left', 'Action Right'];
      return index < names.length ? names[index] : 'Panel ${index + 1}';
    case 'webtoon':
      return 'Scroll ${index + 1}';
    case 'grid_2x2':
    case 'comic_strip':
      const names = ['Top Left', 'Top Right', 'Bottom Left', 'Bottom Right'];
      return names[index.clamp(0, names.length - 1)];
    default:
      return 'Panel ${index + 1}';
  }
}
