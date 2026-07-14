import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_info.dart';
import '../config/privacy_policy_content.dart';
import '../theme/comic_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            AppInfo.appName,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ComicTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Privacy Policy',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${PrivacyPolicyContent.lastUpdated}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          for (final section in PrivacyPolicyContent.sections) ...[
            _SectionBlock(section: section),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final PrivacySection section;

  const _SectionBlock({required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ComicTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: const TextStyle(fontSize: 15, height: 1.55),
        ),
        if (section.bullets.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 15, height: 1.55)),
                  Expanded(
                    child: Text(
                      bullet.replaceAll('**', ''),
                      style: const TextStyle(fontSize: 15, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (section.footer != null) ...[
          const SizedBox(height: 10),
          Text(
            section.footer!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}
