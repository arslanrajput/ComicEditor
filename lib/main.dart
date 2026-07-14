import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'ProjectsListScreen.dart';
import 'app_bootstrap.dart';
import 'config/app_info.dart';
import 'theme/comic_theme.dart';
import 'widgets/bootstrap_error_app.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  installGlobalErrorHandlers();

  try {
    await bootstrapApp();
    FlutterNativeSplash.remove();
    runApp(const MyApp());
  } catch (error) {
    FlutterNativeSplash.remove();
    runApp(BootstrapErrorApp(error: error));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      theme: ComicTheme.light(),
      home: const ProjectsListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
