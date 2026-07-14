import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/comic_theme.dart';
import '../utils/plot_beat_generator.dart';

/// Plot Assistant body — used inside the New Project wizard (step 2).
class PlotAssistantStep extends StatefulWidget {
  final String? initialStory;
  final ValueChanged<List<PlotBeat>>? onBeatsChanged;

  const PlotAssistantStep({
    super.key,
    this.initialStory,
    this.onBeatsChanged,
  });

  @override
  State<PlotAssistantStep> createState() => PlotAssistantStepState();
}

class PlotAssistantStepState extends State<PlotAssistantStep> {
  late final TextEditingController _storyCtrl;
  List<PlotBeat> beats = [];

  @override
  void initState() {
    super.initState();
    _storyCtrl = TextEditingController(
      text: widget.initialStory ??
          'In a world where shadows can be traded as currency, a young pickpocket accidentally steals the shadow of a legendary warrior...',
    );
  }

  @override
  void dispose() {
    _storyCtrl.dispose();
    super.dispose();
  }

  String get script => PlotBeatGenerator.buildScript(beats);

  void generateBeats() {
    setState(() {
      beats = PlotBeatGenerator.fromStory(_storyCtrl.text);
      widget.onBeatsChanged?.call(beats);
    });
  }

  Future<void> addCustomBeat() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Beat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      beats.add(
        PlotBeat(
          act: 'CUSTOM',
          title: titleCtrl.text.trim().isEmpty
              ? 'Custom Beat'
              : titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
        ),
      );
      widget.onBeatsChanged?.call(beats);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ComicTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Map the Narrative',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: ComicTheme.primary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Describe your core idea, and we'll help you break it down into dynamic comic beats.",
                    style: TextStyle(color: Colors.grey.shade600, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tell your story...',
                    style: TextStyle(color: Colors.grey.shade500)),
                TextField(
                  controller: _storyCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: generateBeats,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate Beats'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ComicTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Suggested Beats',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Draft',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF9A825),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...beats.map(_beatCard),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: addCustomBeat,
          icon: const Icon(Icons.add),
          label: const Text('Custom Beat'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Visual Context',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _visualThumb(ComicTheme.primary, 'Neon City'),
              _visualThumb(const Color(0xFF7E57C2), 'Hero'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _beatCard(PlotBeat beat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                beat.act,
                style: const TextStyle(
                  color: ComicTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Icon(Icons.drag_indicator, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(beat.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(beat.description,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35)),
        ],
      ),
    );
  }

  Widget _visualThumb(Color color, String label) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(10),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
