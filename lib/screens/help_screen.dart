import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';
import 'privacy_policy_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            'Getting started',
            '1. Tap New Project on the home screen.\n'
                '2. Choose a layout template (or start blank).\n'
                '3. Tap a panel, then Edit Panel to add content.\n'
                '4. Preview your comic, then Export PDF to share.',
          ),
          _section(
            'Pages vs panels',
            'A page is one sheet in your comic. Panels are the boxes on that page where you draw and add text.',
          ),
          _section(
            'Sketching',
            'Tap Draw in the panel editor to enter sketch mode.\n'
                '• Pencil — light sketch lines\n'
                '• Pen — solid ink lines\n'
                '• Marker — bold, soft strokes\n'
                '• Eraser — remove strokes you drew\n'
                'Draw as many strokes as you like, then tap Done.',
          ),
          _section(
            'Saving',
            'Everything saves automatically on your device. No account required.',
          ),
          _section(
            'Tips',
            '• Double-tap a panel to edit it quickly\n'
                '• Swipe from the left edge to open panel size presets\n'
                '• Long-press a project for quick preview',
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: ComicTheme.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 15, height: 1.45, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
