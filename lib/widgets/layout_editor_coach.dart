import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../theme/comic_theme.dart';

/// First-run tips for the layout editor (4 steps).
class LayoutEditorCoach extends StatefulWidget {
  final VoidCallback onOpenLayouts;

  const LayoutEditorCoach({super.key, required this.onOpenLayouts});

  @override
  State<LayoutEditorCoach> createState() => _LayoutEditorCoachState();
}

class _LayoutEditorCoachState extends State<LayoutEditorCoach> {
  int _step = 0;

  static const _steps = [
    (
      Icons.dashboard_customize_outlined,
      'Choose a layout',
      'Tap Layouts in the toolbar to pick a page template — great for your first page.',
    ),
    (
      Icons.touch_app_outlined,
      'Select a panel',
      'Tap any panel on the page to select it. Double-tap to edit content inside.',
    ),
    (
      Icons.edit_outlined,
      'Edit panel content',
      'With a panel selected, tap Edit Panel to add text, bubbles, images, or drawing.',
    ),
    (
      Icons.picture_as_pdf_outlined,
      'Preview & export',
      'Use Preview to review all pages, then Export PDF to share your comic.',
    ),
  ];

  void _next() {
    if (_step >= _steps.length - 1) {
      AppSettings.setLayoutCoachComplete();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _step++);
  }

  void _skip() {
    AppSettings.setLayoutCoachComplete();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _steps[_step];
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(onPressed: _skip, child: const Text('Skip')),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ComicTheme.panelBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.$1, size: 48, color: ComicTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      s.$2,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.$3,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (i) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _step
                                ? ComicTheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_step == 0)
                      OutlinedButton.icon(
                        onPressed: () {
                          widget.onOpenLayouts();
                          _next();
                        },
                        icon: const Icon(Icons.dashboard_customize_outlined),
                        label: const Text('Open Layouts'),
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _next,
                      child: Text(_step >= _steps.length - 1 ? 'Got it' : 'Next'),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
