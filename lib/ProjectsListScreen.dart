import 'package:comic_editor/project_hive_model.dart';
import 'package:comic_editor/project_mapper.dart';
import 'package:comic_editor/theme/comic_theme.dart';
import 'package:comic_editor/utils/pdf_page_export.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:printing/printing.dart';

import 'PanelLayoutEditorScreen.dart';
import 'PanelModel/Project.dart';
import 'PreviewPdf/AllPagesPreviewScreen.dart';
import 'PreviewPdf/PDFPageFormat.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  List<Project> savedProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    final box = Hive.box<ProjectHiveModel>('drafts');
    final projects = box.values.map(fromHiveModel).toList();
    projects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    setState(() => savedProjects = projects);
  }

  Future<void> _createNewProject() async {
    final name = await _showProjectNameDialog();
    if (name == null || name.isEmpty) return;

    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      pages: [[]],
    );

    final box = Hive.box<ProjectHiveModel>('drafts');
    await box.put(newProject.id, toHiveModel(newProject));

    setState(() => savedProjects.insert(0, newProject));
    _editProject(newProject);
  }

  Future<String?> _showProjectNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Comic Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Project name',
            hintText: 'My awesome comic…',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProject(Project project) async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (context) => PanelLayoutEditorScreen(project: project),
      ),
    );
    _loadProjects();
    if (result != null) {
      final box = Hive.box<ProjectHiveModel>('drafts');
      await box.put(result.id, toHiveModel(result));
      _loadProjects();
    }
  }

  Future<void> _previewProject(Project project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllPagesPreviewScreen(
          pages: project.pages,
          projectName: project.name,
          pageFormat: 'A4',
        ),
      ),
    );
    _loadProjects();
  }

  Future<void> _exportProject(Project project) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => exportPagesToPdf(
          context: context,
          pages: project.pages,
          canvasWidth: PDFPageFormat.A4_WIDTH,
          canvasHeight: PDFPageFormat.A4_HEIGHT,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('“${project.name}” will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Hive.box<ProjectHiveModel>('drafts').delete(project.id);
      setState(() => savedProjects.remove(project));
    }
  }

  void _duplicateProject(Project project) {
    final duplicated = fromHiveModel(toHiveModel(project)).copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${project.name} (Copy)',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    Hive.box<ProjectHiveModel>('drafts')
        .put(duplicated.id, toHiveModel(duplicated));
    _loadProjects();
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ComicTheme.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: ComicTheme.primary),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comic Creator',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Projects saved on this device',
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text('${savedProjects.length} local project(s)'),
              subtitle: const Text('Stored with Hive on device'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: ComicTheme.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person, size: 20, color: ComicTheme.primary),
          ),
          onPressed: _showProfileSheet,
          tooltip: 'Profile',
        ),
        title: const Text(
          'Comic Creator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: savedProjects.isEmpty ? _buildEmptyState() : _buildProjectList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewProject,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'No projects yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap New Project to start your first comic.\nEverything saves automatically on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: savedProjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final project = savedProjects[index];
        return _buildProjectBar(project);
      },
    );
  }

  Widget _buildProjectBar(Project project) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _editProject(project),
        onLongPress: () => _previewProject(project),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black87, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 24),
                  tooltip: 'Edit',
                  onPressed: () => _editProject(project),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 24),
                  tooltip: 'Export PDF',
                  onPressed: () => _exportProject(project),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 22),
                  onSelected: (value) {
                    switch (value) {
                      case 'preview':
                        _previewProject(project);
                      case 'duplicate':
                        _duplicateProject(project);
                      case 'delete':
                        _deleteProject(project);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'preview',
                      child: ListTile(
                        leading: Icon(Icons.visibility_outlined),
                        title: Text('Preview'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy_outlined),
                        title: Text('Duplicate'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
