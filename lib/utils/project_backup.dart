import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../PanelModel/PanelElementModel.dart';
import '../PanelModel/Project.dart';
import '../project_hive_model.dart';
import '../project_mapper.dart';

const _backupVersion = 1;

/// Exports a project to a portable JSON backup file and shares it.
Future<void> exportProjectBackup(Project project) async {
  final json = jsonEncode(_projectToJson(project));
  final dir = await getTemporaryDirectory();
  final safeName =
      project.name.replaceAll(RegExp(r'[^\w\-]+'), '_').replaceAll('_+', '_');
  final file = File('${dir.path}/comic_${safeName}_${project.id}.json');
  await file.writeAsString(json);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json', name: file.uri.pathSegments.last)],
    text: 'Comic Creator backup: ${project.name}',
  );
}

/// Exports all local projects as one backup bundle.
Future<void> exportAllProjectsBackup() async {
  final box = Hive.box<ProjectHiveModel>('drafts');
  final projects = box.values.map(fromHiveModel).toList();
  final payload = {
    'version': _backupVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'projects': projects.map(_projectToJson).toList(),
  };
  final json = jsonEncode(payload);
  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/comic_creator_backup_${DateTime.now().millisecondsSinceEpoch}.json');
  await file.writeAsString(json);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json')],
    text: 'Comic Creator — ${projects.length} project(s)',
  );
}

/// Picks a backup file and imports project(s) into Hive.
Future<int> importProjectBackup(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return 0;

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return 0;

  final decoded = jsonDecode(utf8.decode(bytes));
  final box = Hive.box<ProjectHiveModel>('drafts');
  var imported = 0;

  if (decoded is Map && decoded['projects'] is List) {
    for (final item in decoded['projects'] as List) {
      if (item is! Map) continue;
      final project = _projectFromJson(Map<String, dynamic>.from(item));
      final id = '${project.id}_import_${DateTime.now().millisecondsSinceEpoch}';
      final renamed = project.copyWith(
        id: id,
        name: '${project.name} (imported)',
        lastModified: DateTime.now(),
      );
      await box.put(renamed.id, toHiveModel(renamed));
      imported++;
    }
  } else if (decoded is Map) {
    final project =
        _projectFromJson(Map<String, dynamic>.from(decoded));
    final id = '${project.id}_import_${DateTime.now().millisecondsSinceEpoch}';
    final renamed = project.copyWith(
      id: id,
      name: '${project.name} (imported)',
      lastModified: DateTime.now(),
    );
    await box.put(renamed.id, toHiveModel(renamed));
    imported = 1;
  }

  if (context.mounted && imported > 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $imported project(s)')),
    );
  }
  return imported;
}

Map<String, dynamic> _projectToJson(Project project) {
  return {
    'version': _backupVersion,
    'id': project.id,
    'name': project.name,
    'description': project.description,
    'createdAt': project.createdAt.toIso8601String(),
    'lastModified': project.lastModified.toIso8601String(),
    'thumbnail': project.thumbnail?.toList(),
    'pages': project.pages.map((page) => page.map(_panelToJson).toList()).toList(),
  };
}

Map<String, dynamic> _panelToJson(LayoutPanel panel) {
  return {
    'id': panel.id,
    'label': panel.label,
    'width': panel.width,
    'height': panel.height,
    'x': panel.x,
    'y': panel.y,
    'customText': panel.customText,
    'backgroundColorValue': panel.backgroundColor.toARGB32(),
    'previewImage': panel.previewImage?.toList(),
    'elements': panel.elements.map((e) => e.toMap()).toList(),
  };
}

Project _projectFromJson(Map<String, dynamic> json) {
  final pagesRaw = json['pages'] as List? ?? [];
  final pages = pagesRaw.map((pageRaw) {
    final panels = (pageRaw as List).map((panelRaw) {
      final m = Map<String, dynamic>.from(panelRaw as Map);
      final elements = (m['elements'] as List? ?? [])
          .map((e) => PanelElementModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      return LayoutPanel(
        id: m['id'] as String? ?? '',
        label: m['label'] as String?,
        width: (m['width'] as num).toDouble(),
        height: (m['height'] as num).toDouble(),
        x: (m['x'] as num?)?.toDouble() ?? 0,
        y: (m['y'] as num?)?.toDouble() ?? 0,
        customText: m['customText'] as String?,
        backgroundColor: Color(m['backgroundColorValue'] as int? ?? 0xFFFFFFFF),
        previewImage: m['previewImage'] != null
            ? Uint8List.fromList(List<int>.from(m['previewImage'] as List))
            : null,
        elements: elements,
      );
    }).toList();
    return panels;
  }).toList();

  return Project(
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] as String? ?? 'Imported Comic',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.now(),
    lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ??
        DateTime.now(),
    thumbnail: json['thumbnail'] != null
        ? Uint8List.fromList(List<int>.from(json['thumbnail'] as List))
        : null,
    pages: pages,
  );
}
