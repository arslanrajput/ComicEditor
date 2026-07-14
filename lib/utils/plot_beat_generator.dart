import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared plot-beat model and local generation helpers.
class PlotBeat {
  final String act;
  final String title;
  final String description;

  const PlotBeat({
    required this.act,
    required this.title,
    required this.description,
  });
}

class PlotBeatGenerator {
  PlotBeatGenerator._();

  static List<PlotBeat> fromStory(String story) {
    final text = story.trim();
    if (text.isEmpty) return [];

    final chunks = text
        .split(RegExp(r'[.!?]\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (chunks.isEmpty) {
      return [
        PlotBeat(act: 'ACT 1', title: 'Opening', description: text),
      ];
    }

    final third = (chunks.length / 3).ceil().clamp(1, chunks.length);
    final act1 = chunks.take(third).join('. ');
    final act2 = chunks.skip(third).take(third).join('. ');
    final act3 = chunks.skip(third * 2).join('. ');

    return [
      PlotBeat(
        act: 'ACT 1',
        title: "The Hero's Call",
        description: act1.isEmpty ? chunks.first : act1,
      ),
      if (act2.isNotEmpty)
        PlotBeat(act: 'ACT 2', title: 'Unexpected Ally', description: act2),
      if (act3.isNotEmpty)
        PlotBeat(act: 'ACT 3', title: 'The Market Raid', description: act3),
    ];
  }

  static String buildScript(List<PlotBeat> beats) {
    return beats.map((b) => '${b.title}\n${b.description}').join('\n\n');
  }
}
