import 'package:flutter/material.dart';

import '../PanelModel/PanelElementModel.dart';
import '../models/comic_fonts.dart';
import '../utils/story_text_meta.dart';

/// Renders dialogue text horizontally or vertically (mobile-friendly story editor).
class StoryTextWidget extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final String fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final StoryTextDirection direction;
  final double lineHeight;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const StoryTextWidget({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = Colors.black,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.direction = StoryTextDirection.horizontal,
    this.lineHeight = 1.2,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  factory StoryTextWidget.fromElement(
    PanelElementModel element, {
    TextAlign textAlign = TextAlign.center,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
    StoryTextDirection? directionOverride,
  }) {
    return StoryTextWidget(
      text: StoryTextMeta.textContent(element),
      fontSize: element.fontSize ?? element.speechBubbleData?.fontSize ?? 16,
      color: element.color ?? element.speechBubbleData?.textColor ?? Colors.black,
      fontFamily:
          element.fontFamily ?? element.speechBubbleData?.fontFamily ?? 'Roboto',
      fontWeight: element.fontWeight ??
          element.speechBubbleData?.fontWeight ??
          FontWeight.normal,
      fontStyle:
          element.fontStyle ?? element.speechBubbleData?.fontStyle ?? FontStyle.normal,
      direction: directionOverride ?? StoryTextMeta.directionOf(element),
      lineHeight: StoryTextMeta.lineHeightOf(element),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle get _style => ComicFonts.style(
        family: fontFamily,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      ).copyWith(height: lineHeight);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return Text('…', style: _style.copyWith(color: Colors.grey));
    }

    if (direction == StoryTextDirection.vertical) {
      return _VerticalStoryText(
        text: text,
        style: _style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: _style,
    );
  }
}

class _VerticalStoryText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const _VerticalStoryText({
    required this.text,
    required this.style,
    required this.textAlign,
    this.maxLines,
    required this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final limited = maxLines != null ? lines.take(maxLines!).toList() : lines;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _rowAlignment,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in limited)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final char in line.characters)
                  Text(char, style: style),
              ],
            ),
          ),
      ],
    );
  }

  MainAxisAlignment get _rowAlignment {
    switch (textAlign) {
      case TextAlign.right:
      case TextAlign.end:
        return MainAxisAlignment.end;
      case TextAlign.center:
        return MainAxisAlignment.center;
      default:
        return MainAxisAlignment.start;
    }
  }
}
