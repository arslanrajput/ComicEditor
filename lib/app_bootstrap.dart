import 'dart:ui';

import 'package:comic_editor/project_hive_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'services/app_settings.dart';
import 'services/inkwell_profile_service.dart';

/// Initializes Hive, settings, and profile storage.
Future<void> bootstrapApp() async {
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProjectHiveModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(LayoutPanelHiveModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(PanelElementModelHiveModelAdapter());
  }

  await Hive.openBox<ProjectHiveModel>('drafts');
  await AppSettings.init();
  await InkwellProfileService.init();
}

void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught error: $error\n$stack');
    }
    return true;
  };
}
