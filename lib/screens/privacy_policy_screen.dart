import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Privacy Policy — Comic Creator',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Last updated: June 2026\n\n'
            'Comic Creator stores your comic projects on your device only. '
            'We do not collect, transmit, or sell your personal data.\n\n'
            'Data stored locally:\n'
            '• Project names and comic pages\n'
            '• Panel layouts and artwork you create\n'
            '• Images you choose to import from your gallery\n\n'
            'Permissions:\n'
            '• Camera / Photos — only when you tap Upload to add images to a panel\n'
            '• Internet — used by the PDF share sheet on some devices\n\n'
            'You can delete all data by uninstalling the app or deleting projects in the app.\n\n'
            'Contact: support@example.com (replace with your support email before publishing).',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
