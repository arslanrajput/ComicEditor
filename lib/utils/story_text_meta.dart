import 'dart:convert';

import 'package:flutter/material.dart';

import '../PanelModel/PanelElementModel.dart';

/// Horizontal or vertical layout for story / dialogue text.
enum StoryTextDirection {
  horizontal,
  vertical;

  String get storageKey => name;

  static StoryTextDirection fromKey(String? key) {
    if (key == 'vertical') return StoryTextDirection.vertical;
    return StoryTextDirection.horizontal;
  }
}

/// JSON helpers stored on [PanelElementModel.meta] for story-managed text.
class StoryTextMeta {
  StoryTextMeta._();

  static const _directionKey = 'storyTextDirection';
  static const _lineHeightKey = 'storyLineHeight';

  static Map<String, dynamic> _decode(String? meta) {
    if (meta == null || meta.isEmpty) return {};
    try {
      final decoded = jsonDecode(meta);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static String _encode(Map<String, dynamic> map) {
    if (map.isEmpty) return '';
    return jsonEncode(map);
  }

  static StoryTextDirection directionOf(PanelElementModel element) {
    return StoryTextDirection.fromKey(_decode(element.meta)[_directionKey] as String?);
  }

  static double lineHeightOf(PanelElementModel element) {
    final v = _decode(element.meta)[_lineHeightKey];
    if (v is num) return v.toDouble();
    return 1.2;
  }

  static PanelElementModel withDirection(
    PanelElementModel element,
    StoryTextDirection direction,
  ) {
    final map = _decode(element.meta);
    map[_directionKey] = direction.storageKey;
    return element.copyWith(meta: _encode(map));
  }

  static PanelElementModel withLineHeight(
    PanelElementModel element,
    double lineHeight,
  ) {
    final map = _decode(element.meta);
    map[_lineHeightKey] = lineHeight;
    return element.copyWith(meta: _encode(map));
  }

  static String textContent(PanelElementModel element) {
    if (element.type == 'text') return element.value;
    if (element.type == 'speech_bubble') {
      return element.speechBubbleData?.text ?? '';
    }
    return '';
  }

  static bool isStoryText(PanelElementModel element) {
    return element.type == 'text' || element.type == 'speech_bubble';
  }
}
