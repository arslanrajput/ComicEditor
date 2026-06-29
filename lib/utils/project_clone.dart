import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../PanelModel/PanelElementModel.dart';
import '../PanelModel/Project.dart';

/// Deep-copy helpers for undo/redo and backup.
class ProjectClone {
  ProjectClone._();

  static PanelElementModel cloneElement(PanelElementModel e) {
    return PanelElementModel(
      id: e.id,
      type: e.type,
      value: e.value,
      width: e.width,
      height: e.height,
      offset: e.offset,
      size: e.size == null ? null : Size(e.size!.width, e.size!.height),
      color: e.color,
      fontSize: e.fontSize,
      fontFamily: e.fontFamily,
      locked: e.locked,
      fontWeight: e.fontWeight,
      fontStyle: e.fontStyle,
      meta: e.meta,
      groupId: e.groupId,
      hidden: e.hidden,
    );
  }

  static LayoutPanel clonePanel(LayoutPanel p) {
    return LayoutPanel(
      id: p.id,
      label: p.label,
      width: p.width,
      height: p.height,
      x: p.x,
      y: p.y,
      customText: p.customText,
      elements: p.elements.map(cloneElement).toList(),
      backgroundColor: p.backgroundColor,
      previewImage: p.previewImage == null
          ? null
          : Uint8List.fromList(p.previewImage!),
    );
  }

  static List<List<LayoutPanel>> clonePages(List<List<LayoutPanel>> pages) {
    return pages
        .map((page) => page.map(clonePanel).toList())
        .toList();
  }
}

/// Snapshot of panel edit state for undo/redo.
class PanelEditSnapshot {
  final List<PanelElementModel> elements;
  final Color backgroundColor;

  const PanelEditSnapshot({
    required this.elements,
    required this.backgroundColor,
  });

  factory PanelEditSnapshot.from({
    required List<PanelElementModel> elements,
    required Color backgroundColor,
  }) {
    return PanelEditSnapshot(
      elements: elements.map(ProjectClone.cloneElement).toList(),
      backgroundColor: backgroundColor,
    );
  }
}
