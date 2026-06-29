import 'package:comic_editor/theme/comic_theme.dart';
import 'package:flutter/material.dart';

import 'DrawingToolsPanel.dart';

/// Compact docked toolbar for natural hand-sketching on the panel canvas.
class SketchToolbar extends StatelessWidget {
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentBrushSize;
  final ValueChanged<DrawingTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onBrushSizeChanged;
  final VoidCallback onUndo;
  final VoidCallback onDone;

  const SketchToolbar({
    super.key,
    required this.currentTool,
    required this.currentColor,
    required this.currentBrushSize,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onBrushSizeChanged,
    required this.onUndo,
    required this.onDone,
  });

  static const _quickColors = [
    Colors.black,
    Color(0xFF37474F),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF6D4C41),
  ];

  static double defaultSizeForTool(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pencil:
        return 2.0;
      case DrawingTool.pen:
        return 3.0;
      case DrawingTool.marker:
        return 8.0;
      case DrawingTool.eraser:
        return 18.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ComicTheme.panelBorder.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Done'),
                  style: TextButton.styleFrom(
                    foregroundColor: ComicTheme.primaryDark,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Undo stroke',
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _toolChip(
                    tool: DrawingTool.pencil,
                    icon: Icons.create_outlined,
                    label: 'Pencil',
                  ),
                  _toolChip(
                    tool: DrawingTool.pen,
                    icon: Icons.edit_outlined,
                    label: 'Pen',
                  ),
                  _toolChip(
                    tool: DrawingTool.marker,
                    icon: Icons.brush_outlined,
                    label: 'Marker',
                  ),
                  _toolChip(
                    tool: DrawingTool.eraser,
                    icon: Icons.auto_fix_off_outlined,
                    label: 'Eraser',
                  ),
                  const SizedBox(width: 8),
                  ..._quickColors.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _colorDot(c),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  currentTool == DrawingTool.eraser
                      ? Icons.auto_fix_off_outlined
                      : Icons.line_weight,
                  size: 18,
                  color: Colors.black54,
                ),
                Expanded(
                  child: Slider(
                    value: currentBrushSize.clamp(1, 28),
                    min: 1,
                    max: 28,
                    divisions: 27,
                    label: currentBrushSize.round().toString(),
                    onChanged: onBrushSizeChanged,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: ComicTheme.panelBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Container(
                    width: currentBrushSize.clamp(4, 22),
                    height: currentBrushSize.clamp(4, 22),
                    decoration: BoxDecoration(
                      color: currentTool == DrawingTool.eraser
                          ? Colors.grey.shade300
                          : currentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Draw freely — strokes stay until you tap Done',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolChip({
    required DrawingTool tool,
    required IconData icon,
    required String label,
  }) {
    final selected = currentTool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onToolChanged(tool),
        selectedColor: ComicTheme.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? ComicTheme.primaryDark : Colors.black87,
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    final selected = currentColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ComicTheme.primary : Colors.grey.shade400,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}
