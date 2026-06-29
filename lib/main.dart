import 'package:comic_editor/project_hive_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'ProjectsListScreen.dart';
import 'services/app_settings.dart';
import 'theme/comic_theme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Hive with the correct method for your version
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  // Register adapters with correct type IDs
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProjectHiveModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(LayoutPanelHiveModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(PanelElementModelHiveModelAdapter());
  }

  // Open the box
  await Hive.openBox<ProjectHiveModel>('drafts');
  await AppSettings.init();

  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comic Creator',
      theme: ComicTheme.light(),
      home: const ProjectsListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


