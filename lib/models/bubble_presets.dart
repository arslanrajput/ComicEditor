import 'package:flutter/material.dart';

import '../SpeechDrag/DragSpeechBubbleComponents.dart';
import '../SpeechDrag/DragSpeechBubbleData.dart';

/// One-tap speech bubble style presets (Comic Life-style).
class BubblePreset {
  final String id;
  final String label;
  final IconData icon;
  final DragSpeechBubbleData data;

  const BubblePreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.data,
  });
}

const _defaultTail = Offset(150, 180);

List<BubblePreset> get kBubblePresets => [
      BubblePreset(
        id: 'speech',
        label: 'Speech',
        icon: Icons.chat_bubble_outline,
        data: DragSpeechBubbleData(
          text: 'Hello!',
          bubbleColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2,
          bubbleShape: DragBubbleShape.rectangle,
          tailOffset: _defaultTail,
          padding: 12,
          fontSize: 16,
          textColor: Colors.black,
          fontFamily: 'Comic Neue',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.normal,
        ),
      ),
      BubblePreset(
        id: 'thought',
        label: 'Thought',
        icon: Icons.cloud_outlined,
        data: DragSpeechBubbleData(
          text: 'Hmm…',
          bubbleColor: Colors.white,
          borderColor: Colors.black87,
          borderWidth: 2,
          bubbleShape: DragBubbleShape.thought,
          tailOffset: _defaultTail,
          padding: 14,
          fontSize: 15,
          textColor: Colors.black87,
          fontFamily: 'Comic Neue',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
        ),
      ),
      BubblePreset(
        id: 'shout',
        label: 'Shout',
        icon: Icons.campaign_outlined,
        data: DragSpeechBubbleData(
          text: 'WOW!',
          bubbleColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 3,
          bubbleShape: DragBubbleShape.shout,
          tailOffset: _defaultTail,
          padding: 10,
          fontSize: 22,
          textColor: Colors.black,
          fontFamily: 'Bangers',
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.normal,
          textStrokeWidth: 1,
          textStrokeColor: Colors.white,
        ),
      ),
      BubblePreset(
        id: 'whisper',
        label: 'Whisper',
        icon: Icons.volume_down_outlined,
        data: DragSpeechBubbleData(
          text: 'psst…',
          bubbleColor: Colors.white,
          borderColor: Colors.grey,
          borderWidth: 1.5,
          bubbleShape: DragBubbleShape.whisper,
          tailOffset: _defaultTail,
          padding: 12,
          fontSize: 14,
          textColor: Colors.grey.shade700,
          fontFamily: 'Comic Neue',
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
        ),
      ),
      BubblePreset(
        id: 'caption',
        label: 'Caption',
        icon: Icons.notes_outlined,
        data: DragSpeechBubbleData(
          text: 'Meanwhile…',
          bubbleColor: const Color(0xFFFFF9C4),
          borderColor: Colors.black54,
          borderWidth: 1.5,
          bubbleShape: DragBubbleShape.caption,
          tailOffset: _defaultTail,
          padding: 10,
          fontSize: 14,
          textColor: Colors.black87,
          fontFamily: 'Courier New',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.normal,
        ),
      ),
      BubblePreset(
        id: 'oval',
        label: 'Oval',
        icon: Icons.circle_outlined,
        data: DragSpeechBubbleData(
          text: 'Hey!',
          bubbleColor: Colors.white,
          borderColor: Colors.black,
          borderWidth: 2,
          bubbleShape: DragBubbleShape.oval,
          tailOffset: _defaultTail,
          padding: 14,
          fontSize: 16,
          textColor: Colors.black,
          fontFamily: 'Bubblegum Sans',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.normal,
        ),
      ),
    ];
