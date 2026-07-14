import '../config/app_info.dart';

/// Full privacy policy text shown in-app and mirrored in docs/PRIVACY_POLICY.md.
class PrivacyPolicyContent {
  PrivacyPolicyContent._();

  static const lastUpdated = 'June 2026';

  static List<PrivacySection> get sections => [
        PrivacySection(
          title: 'Introduction',
          body:
              '${AppInfo.appName} ("we," "our," or "the app") is a ${AppInfo.appTagline.toLowerCase()} '
              'published by the developer of ${AppInfo.appName}. '
              'This Privacy Policy explains how information is handled when you use '
              'the mobile application on Android and iOS.\n\n'
              'By using ${AppInfo.appName}, you agree to this policy. If you do not '
              'agree, please do not use the app.',
        ),
        PrivacySection(
          title: 'Summary',
          body:
              '• ${AppInfo.appName} is designed to work **without a user account**.\n'
              '• Your comics, characters, and settings are stored **on your device only**.\n'
              '• We do **not** sell your data or upload your comic artwork to our servers.\n'
              '• Limited network access may occur for fonts and system share/print features.',
        ),
        PrivacySection(
          title: 'Information We Collect',
          body:
              'We do **not** collect personal information through ${AppInfo.appName} '
              'servers because the app does not require sign-in and does not send your '
              'projects to a cloud backend operated by us.\n\n'
              'The following information may exist **only on your device** because you '
              'created or imported it while using the app:',
          bullets: [
            'Comic project names, page layouts, and panel content (drawings, text, speech bubbles)',
            'Imported photos and images you add to panels',
            'Character names, roles, bios, traits, and portrait selections',
            'Profile display name, bio, and optional profile photo',
            'App preferences (page size, grid, export quality, reader mode, story editor defaults)',
            'Onboarding state (e.g. layout tutorial completed)',
            'Bookmarked template IDs and project sort order',
          ],
        ),
        PrivacySection(
          title: 'Information We Do Not Collect',
          body: 'We do not intentionally collect:',
          bullets: [
            'Email addresses or passwords (no account system)',
            'Precise location data',
            'Contacts, call logs, or SMS messages',
            'Advertising identifiers for targeted ads (the app does not show ads)',
            'Analytics tied to your identity on our servers',
          ],
        ),
        PrivacySection(
          title: 'Device Permissions',
          body:
              '${AppInfo.appName} requests permissions only when needed for features you use:',
          bullets: [
            '**Camera** — when you choose to take a photo for a panel or character portrait',
            '**Photos / Gallery** — when you import images into panels, projects, or your profile',
            '**Storage** — to save projects locally and export PDF, PNG, or backup files',
            '**Internet** — see Network Use below',
          ],
          footer:
              'You can deny permissions in your device settings; related features will be unavailable.',
        ),
        PrivacySection(
          title: 'Network Use & Third-Party Services',
          body:
              'Most of ${AppInfo.appName} works offline. Limited network access may occur in these cases:',
          bullets: [
            '**Google Fonts** — when you select certain fonts in the editor or story tools, '
                'the app may download font files from Google\'s servers. Google\'s privacy '
                'policy applies to that service: https://policies.google.com/privacy',
            '**Share & Print** — when you export a PDF or image, your device\'s share sheet '
                'or print dialog may use the network depending on the app you choose (e.g. email, cloud drive)',
            '**App stores** — downloading or updating the app is handled by Google Play or the Apple App Store',
          ],
          footer:
              'We do not upload your comic pages, panels, or project files to our servers.',
        ),
        PrivacySection(
          title: 'Local Storage & Backups',
          body:
              'Projects are saved locally using on-device storage (Hive database and app files). '
              'You may export a JSON backup from Profile and import it later on the same or '
              'another device. Backups you create are under your control — store them securely.',
        ),
        PrivacySection(
          title: 'Data Retention',
          body:
              'Data remains on your device until you delete it. You can remove individual '
              'projects, characters, or profile details in the app, or uninstall ${AppInfo.appName} '
              'to delete all app data from that device.',
        ),
        PrivacySection(
          title: 'Children\'s Privacy',
          body:
              '${AppInfo.appName} is not directed at children under 13 (or the minimum age '
              'required in your country). We do not knowingly collect personal information from '
              'children. All creative content is produced by the user on their own device. '
              'Parents and guardians should supervise minors using the app.',
        ),
        PrivacySection(
          title: 'Security',
          body:
              'We take reasonable steps to design the app so data stays on your device. '
              'However, no method of electronic storage is 100% secure. You are responsible '
              'for securing your device (screen lock, backups) and any export files you share.',
        ),
        PrivacySection(
          title: 'Your Choices & Rights',
          body: 'You can:',
          bullets: [
            'Access your data directly inside the app (projects, characters, profile)',
            'Delete projects or characters at any time',
            'Export or import project backups from Profile',
            'Revoke camera/photo permissions in device Settings',
            'Uninstall the app to remove local data',
          ],
          footer:
              'Depending on your region (e.g. EU/UK GDPR, California CCPA), you may have '
              'additional rights regarding personal data. Because we do not hold your data on '
              'our servers, most requests can be fulfilled by you directly on your device.',
        ),
        PrivacySection(
          title: 'International Users',
          body:
              '${AppInfo.appName} is available internationally. Data you create is processed '
              'and stored locally on your device in the country where you use the app.',
        ),
        PrivacySection(
          title: 'Changes to This Policy',
          body:
              'We may update this Privacy Policy from time to time. The "Last updated" date '
              'at the top will change when we do. Continued use of the app after changes '
              'means you accept the updated policy. The latest version is always available '
              'in the app under Settings → Privacy Policy.',
        ),
        PrivacySection(
          title: 'Contact Us',
          body:
              'If you have questions about this Privacy Policy or ${AppInfo.appName}, contact us at:\n\n'
              'Email: ${AppInfo.supportEmail}\n\n'
              'Online policy: ${AppInfo.privacyPolicyUrl}',
        ),
      ];
}

class PrivacySection {
  final String title;
  final String body;
  final List<String> bullets;
  final String? footer;

  const PrivacySection({
    required this.title,
    required this.body,
    this.bullets = const [],
    this.footer,
  });
}
