import 'dart:typed_data';
import 'package:comic_editor/project_hive_model.dart';
import 'package:flutter/material.dart';
import 'PanelModel/Project.dart';
import 'PanelModel/PanelElementModel.dart';

ProjectHiveModel toHiveModel(Project project) {
  final hivePages = <List<LayoutPanelHiveModel>>[];

  for (final page in project.pages) {
    final hivePanels = <LayoutPanelHiveModel>[];

    for (final panel in page) {
      final hiveElements = panel.elements
          .map(
            (element) => PanelElementModelHiveModel(
              id: element.id,
              type: element.type,
              value: element.value,
              width: element.width,
              height: element.height,
              offsetDx: element.offset.dx,
              offsetDy: element.offset.dy,
              sizeWidth: element.size?.width,
              sizeHeight: element.size?.height,
              colorValue: element.color?.toARGB32(),
              fontSize: element.fontSize,
              fontFamily: element.fontFamily,
              locked: element.locked,
              fontWeightIndex: element.fontWeight?.index,
              fontStyleIndex: element.fontStyle?.index,
              meta: element.meta,
              groupId: element.groupId,
              hidden: element.hidden,
            ),
          )
          .toList();

      hivePanels.add(
        LayoutPanelHiveModel(
          id: panel.id,
          width: panel.width,
          height: panel.height,
          x: panel.x,
          y: panel.y,
          customText: panel.customText,
          backgroundColorValue: panel.backgroundColor.toARGB32(),
          previewImage: panel.previewImage?.toList(),
          elements: hiveElements,
        ),
      );
    }

    hivePages.add(hivePanels);
  }

  return ProjectHiveModel(
    id: project.id,
    name: project.name,
    description: project.description,
    createdAt: project.createdAt,
    lastModified: project.lastModified,
    thumbnail: project.thumbnail?.toList(),
    pages: hivePages,
  );
}

Project fromHiveModel(ProjectHiveModel model) {
  final projectPages = <List<LayoutPanel>>[];

  for (final hivePage in model.pages) {
    final panels = <LayoutPanel>[];

    for (final hivePanel in hivePage) {
      final elements = hivePanel.elements
          .map(
            (hiveElement) => PanelElementModel(
              id: hiveElement.id,
              type: hiveElement.type,
              value: hiveElement.value,
              width: hiveElement.width,
              height: hiveElement.height,
              offset: Offset(hiveElement.offsetDx, hiveElement.offsetDy),
              size: hiveElement.sizeWidth != null &&
                      hiveElement.sizeHeight != null
                  ? Size(hiveElement.sizeWidth!, hiveElement.sizeHeight!)
                  : null,
              color: hiveElement.colorValue != null
                  ? Color(hiveElement.colorValue!)
                  : null,
              fontSize: hiveElement.fontSize,
              fontFamily: hiveElement.fontFamily,
              locked: hiveElement.locked,
              fontWeight: hiveElement.fontWeightIndex != null
                  ? FontWeight.values[hiveElement.fontWeightIndex!]
                  : null,
              fontStyle: hiveElement.fontStyleIndex != null
                  ? FontStyle.values[hiveElement.fontStyleIndex!]
                  : null,
              meta: hiveElement.meta,
              groupId: hiveElement.groupId,
              hidden: hiveElement.hidden,
            ),
          )
          .toList();

      panels.add(
        LayoutPanel(
          id: hivePanel.id,
          width: hivePanel.width,
          height: hivePanel.height,
          x: hivePanel.x,
          y: hivePanel.y,
          customText: hivePanel.customText,
          backgroundColor: Color(hivePanel.backgroundColorValue),
          previewImage: hivePanel.previewImage != null
              ? Uint8List.fromList(hivePanel.previewImage!)
              : null,
          elements: elements,
        ),
      );
    }

    projectPages.add(panels);
  }

  return Project(
    id: model.id,
    name: model.name,
    description: model.description,
    createdAt: model.createdAt,
    lastModified: model.lastModified,
    thumbnail:
        model.thumbnail != null ? Uint8List.fromList(model.thumbnail!) : null,
    pages: projectPages,
  );
}
