import 'package:flutter/material.dart';

import '../models/comic_fonts.dart';
import '../utils/story_text_meta.dart';

/// Result from the apply-style sheet.
class StoryApplyStyleResult {
  final String? fontFamily;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final StoryTextDirection? direction;
  final double? lineHeight;

  const StoryApplyStyleResult({
    this.fontFamily,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.fontStyle,
    this.direction,
    this.lineHeight,
  });

  bool get hasChanges =>
      fontFamily != null ||
      fontSize != null ||
      color != null ||
      fontWeight != null ||
      fontStyle != null ||
      direction != null ||
      lineHeight != null;
}

/// Bottom sheet to bulk-apply text properties (Clip Studio "Apply tool property").
class StoryApplyStyleSheet extends StatefulWidget {
  final int selectionCount;

  const StoryApplyStyleSheet({super.key, required this.selectionCount});

  static Future<StoryApplyStyleResult?> show(
    BuildContext context, {
    required int selectionCount,
  }) {
    return showModalBottomSheet<StoryApplyStyleResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StoryApplyStyleSheet(selectionCount: selectionCount),
    );
  }

  @override
  State<StoryApplyStyleSheet> createState() => _StoryApplyStyleSheetState();
}

class _StoryApplyStyleSheetState extends State<StoryApplyStyleSheet> {
  String? _fontFamily;
  double? _fontSize;
  Color? _color;
  FontWeight? _fontWeight;
  FontStyle? _fontStyle;
  StoryTextDirection? _direction;
  double? _lineHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Apply style to ${widget.selectionCount} text box(es)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Font family',
                border: OutlineInputBorder(),
              ),
              value: _fontFamily,
              hint: const Text('Keep current'),
              items: ComicFonts.families
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _fontFamily = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_fontSize == null
                  ? 'Font size (keep current)'
                  : 'Font size: ${_fontSize!.round()}'),
              subtitle: Slider(
                value: _fontSize ?? 16,
                min: 8,
                max: 72,
                divisions: 64,
                label: (_fontSize ?? 16).round().toString(),
                onChanged: (v) => setState(() => _fontSize = v),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_lineHeight == null
                  ? 'Line spacing (keep current)'
                  : 'Line spacing: ${_lineHeight!.toStringAsFixed(1)}'),
              subtitle: Slider(
                value: _lineHeight ?? 1.2,
                min: 0.8,
                max: 2.5,
                divisions: 17,
                onChanged: (v) => setState(() => _lineHeight = v),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<StoryTextDirection>(
              decoration: const InputDecoration(
                labelText: 'Text direction',
                border: OutlineInputBorder(),
              ),
              value: _direction,
              hint: const Text('Keep current'),
              items: const [
                DropdownMenuItem(
                  value: StoryTextDirection.horizontal,
                  child: Text('Horizontal'),
                ),
                DropdownMenuItem(
                  value: StoryTextDirection.vertical,
                  child: Text('Vertical'),
                ),
              ],
              onChanged: (v) => setState(() => _direction = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<FontWeight>(
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(),
                    ),
                    value: _fontWeight,
                    hint: const Text('Keep'),
                    items: const [
                      DropdownMenuItem(
                        value: FontWeight.normal,
                        child: Text('Normal'),
                      ),
                      DropdownMenuItem(
                        value: FontWeight.bold,
                        child: Text('Bold'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _fontWeight = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<FontStyle>(
                    decoration: const InputDecoration(
                      labelText: 'Style',
                      border: OutlineInputBorder(),
                    ),
                    value: _fontStyle,
                    hint: const Text('Keep'),
                    items: const [
                      DropdownMenuItem(
                        value: FontStyle.normal,
                        child: Text('Normal'),
                      ),
                      DropdownMenuItem(
                        value: FontStyle.italic,
                        child: Text('Italic'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _fontStyle = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Text color'),
              trailing: _ColorChip(
                color: _color,
                onPick: (c) => setState(() => _color = c),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  StoryApplyStyleResult(
                    fontFamily: _fontFamily,
                    fontSize: _fontSize,
                    color: _color,
                    fontWeight: _fontWeight,
                    fontStyle: _fontStyle,
                    direction: _direction,
                    lineHeight: _lineHeight,
                  ),
                );
              },
              child: const Text('Apply to selected'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final Color? color;
  final ValueChanged<Color> onPick;

  const _ColorChip({required this.color, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<Color>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pick color'),
            content: BlockPicker(
              availableColors: const [
                Colors.black,
                Colors.white,
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
              ],
              pickerColor: color ?? Colors.black,
              onColorChanged: (c) => Navigator.pop(ctx, c),
            ),
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade300,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(6),
        ),
        child: color == null
            ? const Icon(Icons.color_lens_outlined, size: 20)
            : null,
      ),
    );
  }
}

/// Minimal color picker block (no extra dependency).
class BlockPicker extends StatelessWidget {
  final List<Color> availableColors;
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    super.key,
    required this.availableColors,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableColors.map((c) {
        return GestureDetector(
          onTap: () => onColorChanged(c),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c,
              border: Border.all(
                color: c == pickerColor ? Colors.blue : Colors.grey,
                width: c == pickerColor ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }).toList(),
    );
  }
}
