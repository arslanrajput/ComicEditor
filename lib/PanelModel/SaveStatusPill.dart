import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SaveStatusPill extends StatelessWidget {
  final String status;        // e.g. "Saving..." or "Saved"
  final double? progress;     // null when idle, 0..1 when saving

  const SaveStatusPill({
    super.key,
    required this.status,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSaving = progress != null && progress! < 1.0;
    final bool isSaved  = (progress == null && status.toLowerCase() == 'saved') || progress == 1.0;

    final Color bg = isSaved
        ? Colors.green.shade600
        : Colors.amber.shade600; // yellow when not saved / saving

    final Color fg = Colors.white;

    final String percentStr =
    isSaving ? '${(progress!.clamp(0, 1) * 100).round()}%' : '';

    final IconData icon = isSaved ? Icons.check_circle : Icons.autorenew;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999), // full pill
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, key: ValueKey(icon), size: 16, color: fg),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isSaving) ...[
            const SizedBox(width: 6),
            Text(
              percentStr,
              style: TextStyle(
                color: fg.withOpacity(0.95),
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
