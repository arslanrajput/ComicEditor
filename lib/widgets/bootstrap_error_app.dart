import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_info.dart';
import '../theme/comic_theme.dart';

/// Shown when local storage fails to initialize on launch.
class BootstrapErrorApp extends StatelessWidget {
  final Object error;

  const BootstrapErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      theme: ComicTheme.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppInfo.appName} could not start',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Local storage failed to initialize. Try restarting the app. '
                  'If the problem continues, free up device storage or reinstall.',
                  style: TextStyle(height: 1.45),
                ),
                const SizedBox(height: 16),
                if (kDebugMode)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        error.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
