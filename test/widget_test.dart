import 'dart:io';

import 'package:comic_editor/main.dart';
import 'package:comic_editor/project_hive_model.dart';
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
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('shows Comic Creator home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Comic Creator'), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
  });
}
