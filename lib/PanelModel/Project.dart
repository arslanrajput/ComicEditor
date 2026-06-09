import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'PanelElementModel.dart';

class Project {
  final String id;
  final String name;
  final String description; // Add this if missing
  final DateTime createdAt;
  final DateTime lastModified;
  final List<List<LayoutPanel>> pages;
  final Uint8List? thumbnail;

  Project({
    required this.id,
    required this.name,
    this.description = '', // Add this if missing
    required this.createdAt,
    required this.lastModified,
    required this.pages,
    this.thumbnail,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? lastModified,
    List<List<LayoutPanel>>? pages,
    Uint8List? thumbnail,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      pages: pages ?? this.pages,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }
}

class LayoutPanel {
  final String id;
  final String? label;
  double width;
  double height;
  double x;
  double y;
  String? customText;
  List<PanelElementModel> elements;
  Color backgroundColor;
  Uint8List? previewImage;

  LayoutPanel({
    required this.id,
    this.label = null,
    required this.width,
    required this.height,
    this.x = 0,
    this.y = 0,
    this.customText,
    List<PanelElementModel>? elements, // Make nullable
    this.backgroundColor = Colors.white,
    this.previewImage,
  }) : elements = elements ?? []; // Ensure it's never null

  LayoutPanel copyWith({
    String? id,
    String? label,
    double? width,
    double? height,
    double? x,
    double? y,
    String? customText,
    List<PanelElementModel>? elements,
    Color? backgroundColor,
    Uint8List? previewImage,
  }) {
    return LayoutPanel(
      id: id ?? this.id,
      label: label ?? this.label,
      width: width ?? this.width,
      height: height ?? this.height,
      x: x ?? this.x,
      y: y ?? this.y,
      customText: customText ?? this.customText,
      elements: elements ?? List<PanelElementModel>.from(this.elements),
      // Deep copy
      backgroundColor: backgroundColor ?? this.backgroundColor,
      previewImage: previewImage ?? this.previewImage,
    );
  }

  ComicPanel toComicPanel() {
    final elementsCopy = elements.map((element) {
      return PanelElementModel(
        id: element.id,
        type: element.type,
        value: element.value,
        width: element.width,
        height: element.height,
        offset: element.offset,
        size: element.size,
        color: element.color,
        fontSize: element.fontSize,
        fontFamily: element.fontFamily,
        locked: element.locked,
        fontWeight: element.fontWeight,
        fontStyle: element.fontStyle,
        meta: element.meta,
        groupId: element.groupId,
        hidden: element.hidden,
      );
    }).toList();

    return ComicPanel(
      id: id,
      elements: elementsCopy,
      backgroundColor: backgroundColor,
      previewImage: previewImage,
    );
  }

  LayoutPanel updateFromComicPanel(ComicPanel panel) {
    return copyWith(
      elements: List<PanelElementModel>.from(panel.elements),
      backgroundColor: panel.backgroundColor,
      previewImage: panel.previewImage,
    );
  }


}
