import 'dart:convert';

import 'package:flutter/material.dart';

import '../PanelModel/PanelElementModel.dart';
import '../PanelModel/Project.dart';
import '../SpeechDrag/DragSpeechBubbleData.dart';
import 'project_clone.dart';
import 'speech_bubble_rasterizer.dart';
import 'story_text_meta.dart';

/// Pointer to a text or speech-bubble element inside a project.
class StoryTextRef {
  final int pageIndex;
  final int panelIndex;
  final String elementId;

  const StoryTextRef({
    required this.pageIndex,
    required this.panelIndex,
    required this.elementId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryTextRef &&
          pageIndex == other.pageIndex &&
          panelIndex == other.panelIndex &&
          elementId == other.elementId;

  @override
  int get hashCode => Object.hash(pageIndex, panelIndex, elementId);
}

/// Row shown in the story editor list.
class StoryListItem {
  final StoryTextRef ref;
  final PanelElementModel element;
  final int sortIndex;

  const StoryListItem({
    required this.ref,
    required this.element,
    required this.sortIndex,
  });
}

/// Style bundle applied to multiple story text boxes at once.
class StoryTextStyle {
  final String? fontFamily;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final StoryTextDirection? direction;
  final double? lineHeight;

  const StoryTextStyle({
    this.fontFamily,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.fontStyle,
    this.direction,
    this.lineHeight,
  });
}

/// Core read/write helpers for the mobile story editor workflow.
class StoryEditorService {
  StoryEditorService._();

  static int _idCounter = 0;

  static String newId() {
    _idCounter += 1;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  static List<StoryListItem> itemsOnPage(
    List<List<LayoutPanel>> pages,
    int pageIndex,
  ) {
    if (pageIndex < 0 || pageIndex >= pages.length) return [];
    final items = <StoryListItem>[];
    final page = pages[pageIndex];
    for (var p = 0; p < page.length; p++) {
      final panel = page[p];
      for (var e = 0; e < panel.elements.length; e++) {
        final element = panel.elements[e];
        if (!StoryTextMeta.isStoryText(element)) continue;
        items.add(
          StoryListItem(
            ref: StoryTextRef(
              pageIndex: pageIndex,
              panelIndex: p,
              elementId: element.id,
            ),
            element: element,
            sortIndex: e,
          ),
        );
      }
    }
    return items;
  }

  static List<StoryListItem> allItems(List<List<LayoutPanel>> pages) {
    final items = <StoryListItem>[];
    for (var page = 0; page < pages.length; page++) {
      items.addAll(itemsOnPage(pages, page));
    }
    return items;
  }

  static PanelElementModel? findElement(
    List<List<LayoutPanel>> pages,
    StoryTextRef ref,
  ) {
    if (ref.pageIndex < 0 || ref.pageIndex >= pages.length) return null;
    final page = pages[ref.pageIndex];
    if (ref.panelIndex < 0 || ref.panelIndex >= page.length) return null;
    for (final element in page[ref.panelIndex].elements) {
      if (element.id == ref.elementId) return element;
    }
    return null;
  }

  static int _panelIndexForStory(List<LayoutPanel> page) {
    if (page.isEmpty) return -1;
    return 0;
  }

  static LayoutPanel _ensureStoryPanel(
    List<LayoutPanel> page,
    double canvasWidth,
    double canvasHeight,
    double margin,
  ) {
    if (page.isNotEmpty) return page.first;
    return LayoutPanel(
      id: newId(),
      width: canvasWidth - margin * 2,
      height: canvasHeight - margin * 2,
      x: margin,
      y: margin,
      customText: 'Storyboard',
      backgroundColor: Colors.white,
    );
  }

  static List<List<LayoutPanel>> _replaceElement(
    List<List<LayoutPanel>> pages,
    StoryTextRef ref,
    PanelElementModel updated,
  ) {
    final cloned = ProjectClone.clonePages(pages);
    final panel = cloned[ref.pageIndex][ref.panelIndex];
    final nextElements = panel.elements
        .map((e) => e.id == ref.elementId ? updated : e)
        .toList();
    cloned[ref.pageIndex][ref.panelIndex] =
        panel.copyWith(elements: nextElements);
    return cloned;
  }

  static List<List<LayoutPanel>> _removeElement(
    List<List<LayoutPanel>> pages,
    StoryTextRef ref,
  ) {
    final cloned = ProjectClone.clonePages(pages);
    final panel = cloned[ref.pageIndex][ref.panelIndex];
    final nextElements =
        panel.elements.where((e) => e.id != ref.elementId).toList();
    cloned[ref.pageIndex][ref.panelIndex] =
        panel.copyWith(elements: nextElements);
    return cloned;
  }

  static String _encodeBubbleMeta(DragSpeechBubbleData data) {
    return jsonEncode({
      'kind': 'speech_bubble_original',
      'data': data.toMap(),
    });
  }

  static PanelElementModel _applyStyleToElement(
    PanelElementModel element,
    StoryTextStyle style,
  ) {
    var next = element;
    if (element.type == 'text') {
      next = next.copyWith(
        fontFamily: style.fontFamily ?? element.fontFamily,
        fontSize: style.fontSize ?? element.fontSize,
        color: style.color ?? element.color,
        fontWeight: style.fontWeight ?? element.fontWeight,
        fontStyle: style.fontStyle ?? element.fontStyle,
      );
    } else if (element.type == 'speech_bubble') {
      final bubble = element.speechBubbleData;
      if (bubble != null) {
        final updated = DragSpeechBubbleData(
          text: bubble.text,
          bubbleColor: bubble.bubbleColor,
          borderColor: bubble.borderColor,
          borderWidth: bubble.borderWidth,
          bubbleShape: bubble.bubbleShape,
          tailOffset: bubble.tailOffset,
          tailNorm: bubble.tailNorm,
          padding: bubble.padding,
          fontSize: style.fontSize ?? bubble.fontSize,
          textColor: style.color ?? bubble.textColor,
          fontFamily: style.fontFamily ?? bubble.fontFamily,
          fontWeight: style.fontWeight ?? bubble.fontWeight,
          fontStyle: style.fontStyle ?? bubble.fontStyle,
          textStrokeWidth: bubble.textStrokeWidth,
          textStrokeColor: bubble.textStrokeColor,
        );
        next = next.copyWith(meta: _encodeBubbleMeta(updated));
      }
    }

    if (style.direction != null) {
      next = StoryTextMeta.withDirection(next, style.direction!);
    }
    if (style.lineHeight != null) {
      next = StoryTextMeta.withLineHeight(next, style.lineHeight!);
    }
    return next;
  }

  static List<List<LayoutPanel>> updateText(
    List<List<LayoutPanel>> pages,
    StoryTextRef ref,
    String newText,
  ) {
    final element = findElement(pages, ref);
    if (element == null) return pages;

    if (element.type == 'text') {
      return _replaceElement(pages, ref, element.copyWith(value: newText));
    }

    final bubble = element.speechBubbleData;
    if (bubble == null) return pages;
    final updatedBubble = DragSpeechBubbleData(
      text: newText,
      bubbleColor: bubble.bubbleColor,
      borderColor: bubble.borderColor,
      borderWidth: bubble.borderWidth,
      bubbleShape: bubble.bubbleShape,
      tailOffset: bubble.tailOffset,
      tailNorm: bubble.tailNorm,
      padding: bubble.padding,
      fontSize: bubble.fontSize,
      textColor: bubble.textColor,
      fontFamily: bubble.fontFamily,
      fontWeight: bubble.fontWeight,
      fontStyle: bubble.fontStyle,
      textStrokeWidth: bubble.textStrokeWidth,
      textStrokeColor: bubble.textStrokeColor,
    );
    return _replaceElement(
      pages,
      ref,
      element.copyWith(meta: _encodeBubbleMeta(updatedBubble)),
    );
  }

  static Future<List<List<LayoutPanel>>> pasteScript({
    required List<List<LayoutPanel>> pages,
    required int pageIndex,
    required String rawText,
    required double canvasWidth,
    required double canvasHeight,
    double margin = 10,
    bool createAsBubble = false,
    StoryTextDirection direction = StoryTextDirection.horizontal,
    String fontFamily = 'Roboto',
    double fontSize = 16,
    Color textColor = Colors.black,
  }) async {
    if (pageIndex < 0) return pages;
    var cloned = ProjectClone.clonePages(pages);
    while (cloned.length <= pageIndex) {
      cloned.add(<LayoutPanel>[]);
    }

    final page = List<LayoutPanel>.from(cloned[pageIndex]);
    final panel = _ensureStoryPanel(page, canvasWidth, canvasHeight, margin);
    if (page.isEmpty) page.add(panel);

    final panelIndex = _panelIndexForStory(page);
    final existing = itemsOnPage(cloned, pageIndex).length;
    final blocks = rawText
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    var elements = List<PanelElementModel>.from(page[panelIndex].elements);
  const colWidth = 120.0;
    const rowHeight = 80.0;
    const startX = 20.0;
    const startY = 20.0;

    for (var i = 0; i < blocks.length; i++) {
      final col = (existing + i) % 4;
      final row = (existing + i) ~/ 4;
      final offset = Offset(startX + col * colWidth, startY + row * rowHeight);
      final id = newId();
      PanelElementModel element;

      if (createAsBubble) {
        element = await SpeechBubbleRasterizer.createElement(
          text: blocks[i],
          offset: offset,
          fontSize: fontSize,
          fontFamily: fontFamily,
          textColor: textColor,
          id: id,
        );
      } else {
        element = PanelElementModel(
          id: id,
          type: 'text',
          value: blocks[i],
          offset: offset,
          width: 110,
          height: 70,
          size: const Size(110, 70),
          fontSize: fontSize,
          color: textColor,
          fontFamily: fontFamily,
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.normal,
        );
        element = StoryTextMeta.withDirection(element, direction);
      }
      elements.add(element);
    }

    page[panelIndex] = page[panelIndex].copyWith(elements: elements);
    cloned[pageIndex] = page;
    return cloned;
  }

  static Future<List<List<LayoutPanel>>> addBlankText({
    required List<List<LayoutPanel>> pages,
    required int pageIndex,
    required double canvasWidth,
    required double canvasHeight,
    double margin = 10,
    bool createAsBubble = false,
    StoryTextDirection direction = StoryTextDirection.horizontal,
    String fontFamily = 'Roboto',
    double fontSize = 16,
    Color textColor = Colors.black,
    String placeholder = 'Enter text here',
  }) async {
    return pasteScript(
      pages: pages,
      pageIndex: pageIndex,
      rawText: placeholder,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      margin: margin,
      createAsBubble: createAsBubble,
      direction: direction,
      fontFamily: fontFamily,
      fontSize: fontSize,
      textColor: textColor,
    );
  }

  static List<List<LayoutPanel>> deleteRefs(
    List<List<LayoutPanel>> pages,
    Set<String> elementIds,
  ) {
    var cloned = ProjectClone.clonePages(pages);
    for (var p = 0; p < cloned.length; p++) {
      final page = cloned[p];
      for (var i = 0; i < page.length; i++) {
        final panel = page[i];
        final next = panel.elements.where((e) => !elementIds.contains(e.id)).toList();
        if (next.length != panel.elements.length) {
          page[i] = panel.copyWith(elements: next);
        }
      }
    }
    return cloned;
  }

  static List<List<LayoutPanel>> moveElementToPage(
    List<List<LayoutPanel>> pages,
    StoryTextRef ref,
    int targetPageIndex,
    double canvasWidth,
    double canvasHeight,
    double margin,
  ) {
    if (ref.pageIndex == targetPageIndex) return pages;
    final element = findElement(pages, ref);
    if (element == null) return pages;

    var cloned = _removeElement(pages, ref);
    while (cloned.length <= targetPageIndex) {
      cloned.add(<LayoutPanel>[]);
    }

    final targetPage = List<LayoutPanel>.from(cloned[targetPageIndex]);
    final panel = _ensureStoryPanel(targetPage, canvasWidth, canvasHeight, margin);
    if (targetPage.isEmpty) targetPage.add(panel);

    final panelIndex = _panelIndexForStory(targetPage);
    final count = itemsOnPage(cloned, targetPageIndex).length;
    const colWidth = 120.0;
    const rowHeight = 80.0;
    final col = count % 4;
    final row = count ~/ 4;
    final moved = element.copyWith(
      offset: Offset(20 + col * colWidth, 20 + row * rowHeight),
    );

    final elements = List<PanelElementModel>.from(targetPage[panelIndex].elements)
      ..add(moved);
    targetPage[panelIndex] =
        targetPage[panelIndex].copyWith(elements: elements);
    cloned[targetPageIndex] = targetPage;
    return cloned;
  }

  static List<List<LayoutPanel>> reorderOnPage(
    List<List<LayoutPanel>> pages,
    int pageIndex,
    int oldIndex,
    int newIndex,
  ) {
    final items = itemsOnPage(pages, pageIndex);
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= items.length ||
        newIndex >= items.length) {
      return pages;
    }

    final reordered = List<StoryListItem>.from(items);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final idOrder = reordered.map((i) => i.ref.elementId).toList();

    final cloned = ProjectClone.clonePages(pages);
    for (var pi = 0; pi < cloned[pageIndex].length; pi++) {
      final panel = cloned[pageIndex][pi];
      final story =
          panel.elements.where(StoryTextMeta.isStoryText).toList();
      if (story.isEmpty) continue;

      final byId = {for (final e in story) e.id: e};
      final panelIds = idOrder.where(byId.containsKey).toList();
      if (panelIds.isEmpty) continue;

      final nonStory = panel.elements
          .where((e) => !StoryTextMeta.isStoryText(e))
          .toList();
      final ordered = [for (final id in panelIds) byId[id]!];
      cloned[pageIndex][pi] =
          panel.copyWith(elements: [...nonStory, ...ordered]);
    }
    return cloned;
  }

  static List<List<LayoutPanel>> applyStyle(
    List<List<LayoutPanel>> pages,
    Set<String> elementIds,
    StoryTextStyle style,
  ) {
    var cloned = ProjectClone.clonePages(pages);
    for (var p = 0; p < cloned.length; p++) {
      for (var i = 0; i < cloned[p].length; i++) {
        final panel = cloned[p][i];
        final nextElements = panel.elements.map((element) {
          if (!elementIds.contains(element.id)) return element;
          return _applyStyleToElement(element, style);
        }).toList();
        cloned[p][i] = panel.copyWith(elements: nextElements);
      }
    }
    return cloned;
  }

  static List<List<LayoutPanel>> addPage(List<List<LayoutPanel>> pages) {
    final cloned = ProjectClone.clonePages(pages);
    cloned.add(<LayoutPanel>[]);
    return cloned;
  }

  static List<StoryListItem> searchFrom(
    List<List<LayoutPanel>> pages,
    String query, {
    int startPage = 0,
    String? startElementId,
    bool forward = true,
  }) {
    if (query.isEmpty) return [];
    final all = allItems(pages);
    if (all.isEmpty) return [];

    var startIdx = 0;
    if (startElementId != null) {
      startIdx = all.indexWhere((i) => i.ref.elementId == startElementId);
      if (startIdx < 0) {
        startIdx = 0;
      } else {
        startIdx = forward ? startIdx + 1 : startIdx - 1;
      }
    } else {
      final firstOnPage =
          all.indexWhere((i) => i.ref.pageIndex >= startPage);
      startIdx = firstOnPage >= 0 ? firstOnPage : 0;
    }

    final matches = <StoryListItem>[];
    if (forward) {
      for (var i = startIdx; i < all.length; i++) {
        if (_matches(all[i], query)) matches.add(all[i]);
      }
      for (var i = 0; i < startIdx && i < all.length; i++) {
        if (_matches(all[i], query)) matches.add(all[i]);
      }
    } else {
      for (var i = startIdx; i >= 0; i--) {
        if (_matches(all[i], query)) matches.add(all[i]);
      }
      for (var i = all.length - 1; i > startIdx; i--) {
        if (_matches(all[i], query)) matches.add(all[i]);
      }
    }
    return matches;
  }

  static bool _matches(StoryListItem item, String query) {
    return StoryTextMeta.textContent(item.element)
        .toLowerCase()
        .contains(query.toLowerCase());
  }

  static List<List<LayoutPanel>> replaceInElement(
    List<List<LayoutPanel>> pages,
    StoryTextRef ref,
    String search,
    String replacement,
  ) {
    final element = findElement(pages, ref);
    if (element == null || search.isEmpty) return pages;
    final content = StoryTextMeta.textContent(element);
    if (!content.contains(search)) return pages;
    return updateText(pages, ref, content.replaceFirst(search, replacement));
  }

  static List<List<LayoutPanel>> replaceAll(
    List<List<LayoutPanel>> pages,
    String search,
    String replacement,
  ) {
    if (search.isEmpty) return pages;
    var cloned = pages;
    for (final item in allItems(pages)) {
      final content = StoryTextMeta.textContent(item.element);
      if (content.contains(search)) {
        cloned = updateText(
          cloned,
          item.ref,
          content.replaceAll(search, replacement),
        );
      }
    }
    return cloned;
  }
}
