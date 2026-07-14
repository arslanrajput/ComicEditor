import 'dart:io';

import 'package:comic_editor/config/app_info.dart';
import 'package:comic_editor/main.dart';
import 'package:comic_editor/project_hive_model.dart';
import 'package:comic_editor/services/app_settings.dart';
import 'package:comic_editor/services/inkwell_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('comic_editor_test');
    Hive.init(tempDir.path);

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
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('shows Inkwell home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text(AppInfo.appName), findsWidgets);
    expect(find.text('Continue Creating'), findsOneWidget);
    expect(find.text('New Comic'), findsOneWidget);
  });
}
