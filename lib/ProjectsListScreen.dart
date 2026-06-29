import 'package:comic_editor/models/comic_template.dart';
import 'package:comic_editor/widgets/template_layout_preview.dart';
import 'package:comic_editor/project_hive_model.dart';
import 'package:comic_editor/project_mapper.dart';
import 'package:comic_editor/screens/help_screen.dart';
import 'package:comic_editor/theme/comic_theme.dart';
import 'package:comic_editor/screens/comic_reader_screen.dart';
import 'package:comic_editor/screens/settings_screen.dart';
import 'package:comic_editor/services/app_settings.dart';
import 'package:comic_editor/utils/project_backup.dart';
import 'package:comic_editor/widgets/export_options_sheet.dart';
import 'package:comic_editor/widgets/app_logo.dart';
import 'package:comic_editor/widgets/panel_content_preview.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

import 'PanelLayoutEditorScreen.dart';
import 'PanelModel/PanelElementModel.dart';
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
  List<Project> _filteredProjects = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    final box = Hive.box<ProjectHiveModel>('drafts');
    final projects = box.values.map(fromHiveModel).toList();
    _sortProjectsList(projects);
    setState(() {
      savedProjects = projects;
      _applySearchFilter();
    });
  }

  void _sortProjectsList(List<Project> projects) {
    switch (AppSettings.projectSortOrder) {
      case 'name':
        projects.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 'created':
        projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default:
        projects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProjects = List.from(savedProjects);
      return;
    }
    final q = _searchQuery.toLowerCase();
    _filteredProjects = savedProjects
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _createNewProject({String? templateId}) async {
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
    _editProject(newProject, templateId: templateId);
  }

  Future<void> _importImageAsProject() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final name = await _showProjectNameDialog(
      title: 'Import Comic',
      hint: 'Imported comic name…',
    );
    if (name == null || name.isEmpty) return;

    const margin = 10.0;
    const pageW = PDFPageFormat.A4_WIDTH * PDFPageFormat.DISPLAY_SCALE;
    const pageH = PDFPageFormat.A4_HEIGHT * PDFPageFormat.DISPLAY_SCALE;
    final panelW = pageW - 2 * margin;
    final panelH = pageH - 2 * margin;

    final panel = LayoutPanel(
      id: 'Imported Image',
      x: margin,
      y: margin,
      width: panelW,
      height: panelH,
      elements: [
        PanelElementModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'image',
          value: picked.path,
          offset: Offset(margin + 20, margin + 20),
          width: panelW - 40,
          height: panelH - 40,
          size: Size(panelW - 40, panelH - 40),
        ),
      ],
    );

    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      pages: [
        [panel]
      ],
    );

    await Hive.box<ProjectHiveModel>('drafts')
        .put(newProject.id, toHiveModel(newProject));
    setState(() => savedProjects.insert(0, newProject));
    _editProject(newProject);
  }

  Future<String?> _showProjectNameDialog({
    String title = 'New Comic Project',
    String hint = 'My awesome comic…',
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Project name',
            hintText: hint,
            border: const OutlineInputBorder(),
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

  Future<void> _editProject(Project project, {String? templateId}) async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(
        builder: (context) => PanelLayoutEditorScreen(
          project: project,
          applyTemplateOnOpen: templateId,
        ),
      ),
    );
    _loadProjects();
    if (result != null) {
      await Hive.box<ProjectHiveModel>('drafts')
          .put(result.id, toHiveModel(result));
      _loadProjects();
    }
  }

  Future<void> _renameProject(Project project) async {
    final controller = TextEditingController(text: project.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Project name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == project.name) return;
    final updated = project.copyWith(name: newName, lastModified: DateTime.now());
    await Hive.box<ProjectHiveModel>('drafts').put(updated.id, toHiveModel(updated));
    _loadProjects();
  }

  Future<void> _openReader(Project project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComicReaderScreen(
          pages: project.pages,
          projectName: project.name,
          pageFormat: AppSettings.defaultPageFormat,
        ),
      ),
    );
  }

  Future<void> _previewProject(Project project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllPagesPreviewScreen(
          pages: project.pages,
          projectName: project.name,
          pageFormat: AppSettings.defaultPageFormat,
        ),
      ),
    );
    _loadProjects();
  }

  Future<void> _exportProject(Project project) async {
    await showComicExportSheet(
      context: context,
      pages: project.pages,
      projectName: project.name,
      pageFormatKey: AppSettings.defaultPageFormat,
    );
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
                const AppLogo(size: 56, showShadow: true),
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
              leading: const Icon(Icons.upload_outlined),
              title: const Text('Import backup'),
              onTap: () {
                Navigator.pop(context);
                importProjectBackup(context).then((_) => _loadProjects());
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export all projects'),
              onTap: () {
                Navigator.pop(context);
                exportAllProjectsBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then((_) => _loadProjects());
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text('${savedProjects.length} local project(s)'),
              subtitle: const Text('Saved automatically — no account needed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _projectThumbnail(Project project) {
    if (project.pages.isEmpty || project.pages.first.isEmpty) return null;
    final panel = project.pages.first.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 52,
        height: 52,
        child: FittedBox(
          fit: BoxFit.cover,
          child: PanelContentPreview(
            panel: panel,
            width: panel.width,
            height: panel.height,
          ),
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
          icon: const AppLogo(size: 34),
          onPressed: _showProfileSheet,
          tooltip: 'About',
        ),
        title: const Text(
          'Comic Creator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => _loadProjects()),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: savedProjects.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildTemplateSection()),
                if (savedProjects.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search projects…',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() {
                          _searchQuery = v;
                          _applySearchFilter();
                        }),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: SliverList.separated(
                    itemCount: _filteredProjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _buildProjectBar(_filteredProjects[i]),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'import',
            onPressed: _importImageAsProject,
            tooltip: 'Import image',
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'new',
            onPressed: () => _createNewProject(),
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'Start with a template',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kComicTemplates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final t = kComicTemplates[i];
              return _TemplateCard(
                template: t,
                onTap: () => _createNewProject(
                  templateId: t.id.isEmpty ? null : t.id,
                ),
              );
            },
          ),
        ),
        if (savedProjects.isNotEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Your projects',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildTemplateSection(),
        Expanded(
          child: Center(
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
                    'Pick a template above or tap New Project.\nEverything saves automatically on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _projectThumbnail(project) ??
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Icon(Icons.image_outlined,
                          color: Colors.grey.shade500),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu_book_outlined, size: 22),
                  tooltip: 'Read',
                  onPressed: () => _openReader(project),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 22),
                  tooltip: 'Preview',
                  onPressed: () => _previewProject(project),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  tooltip: 'Edit',
                  onPressed: () => _editProject(project),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 22),
                  tooltip: 'Export',
                  onPressed: () => _exportProject(project),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 22),
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _renameProject(project);
                      case 'backup':
                        exportProjectBackup(project);
                      case 'duplicate':
                        _duplicateProject(project);
                      case 'delete':
                        _deleteProject(project);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.drive_file_rename_outline),
                        title: Text('Rename'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'backup',
                      child: ListTile(
                        leading: Icon(Icons.save_alt_outlined),
                        title: Text('Export backup'),
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

class _TemplateCard extends StatelessWidget {
  final ComicTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ComicTheme.panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TemplateLayoutPreview(
              templateId: template.id,
              accentColor: template.color,
              width: double.infinity,
              height: 52,
            ),
            const SizedBox(height: 8),
            Text(
              template.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              template.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
