import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:comic_editor/config/app_info.dart';
import 'package:comic_editor/widgets/app_logo.dart';
import 'package:comic_editor/widgets/inkwell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:comic_editor/project_hive_model.dart';
import 'package:comic_editor/project_mapper.dart';
import 'package:comic_editor/screens/comic_reader_screen.dart';
import 'package:comic_editor/screens/help_screen.dart';
import 'package:comic_editor/screens/settings_screen.dart';
import 'package:comic_editor/screens/character_studio_screen.dart';
import 'package:comic_editor/screens/inkwell_home_tab.dart';
import 'package:comic_editor/screens/inkwell_profile_tab.dart';
import 'package:comic_editor/screens/inkwell_projects_tab.dart';
import 'package:comic_editor/screens/new_project_wizard_screen.dart';
import 'package:comic_editor/utils/project_metadata.dart';
import 'package:comic_editor/screens/story_editor_screen.dart';
import 'package:comic_editor/screens/templates_canvas_screen.dart';
import 'package:comic_editor/services/app_settings.dart';
import 'package:comic_editor/theme/comic_theme.dart';
import 'package:comic_editor/widgets/export_options_sheet.dart';
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
  int _navIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _characterStudioKey = GlobalKey<CharacterStudioScreenState>();
  late final NotchBottomBarController _bottomBarController =
      NotchBottomBarController(index: 0);
  bool _projectsSearchVisible = false;

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

  void _goToTab(int index) {
    if (_navIndex == index && _bottomBarController.index == index) return;
    setState(() => _navIndex = index);
    _bottomBarController.jumpTo(index);
  }

  Future<void> _openNewProjectWizard({String? templateId}) async {
    String? initialFormat;
    if (templateId != null) {
      switch (templateId) {
        case 'single_splash':
          initialFormat = 'single_page';
          break;
        case 'webtoon':
          initialFormat = 'webtoon';
          break;
        default:
          initialFormat = 'comic_book';
      }
    }

    final result = await Navigator.push<NewProjectWizardResult>(
      context,
      MaterialPageRoute(
        builder: (_) => NewProjectWizardScreen(
          initialTemplateId: templateId,
          initialFormat: initialFormat,
        ),
      ),
    );
    if (result == null) return;
    await _createProjectFromWizard(result);
  }

  Future<void> _createProjectFromWizard(NewProjectWizardResult result) async {
    final meta = ProjectMetadata(
      genre: result.genre,
      format: result.format,
      castCharacterIds: result.castCharacterIds,
    );

    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: result.name,
      description: ProjectMetadata.encode(meta),
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      pages: [[]],
    );

    await Hive.box<ProjectHiveModel>('drafts')
        .put(newProject.id, toHiveModel(newProject));
    setState(() => savedProjects.insert(0, newProject));
    _loadProjects();

    final templateId =
        result.templateId ?? ProjectMetadata.templateIdForFormat(result.format);

    if (!mounted) return;

    if (result.plotScript != null && result.plotScript!.trim().isNotEmpty) {
      final updated = await Navigator.push<Project>(
        context,
        MaterialPageRoute(
          builder: (_) => StoryEditorScreen(
            project: newProject,
            pageFormat: AppSettings.defaultPageFormat,
            initialScript: result.plotScript,
          ),
        ),
      );
      if (updated != null) {
        await Hive.box<ProjectHiveModel>('drafts')
            .put(updated.id, toHiveModel(updated));
        _loadProjects();
        if (mounted) _editProject(updated, templateId: templateId);
      } else if (mounted) {
        _editProject(newProject, templateId: templateId);
      }
    } else {
      _editProject(newProject, templateId: templateId);
    }
  }

  Future<void> _quickSketch() async {
    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Quick Sketch',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      pages: [[]],
    );

    await Hive.box<ProjectHiveModel>('drafts')
        .put(newProject.id, toHiveModel(newProject));
    setState(() => savedProjects.insert(0, newProject));
    _loadProjects();
    _editProject(newProject);
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

  void _showDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showProjectMenu(Project project) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _editProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Read'),
              onTap: () {
                Navigator.pop(ctx);
                _openReader(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Preview'),
              onTap: () {
                Navigator.pop(ctx);
                _previewProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(ctx);
                _exportProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _renameProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(ctx);
                _duplicateProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteProject(project);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return InkwellHomeTab(
          projects: savedProjects,
          onOpenTemplates: () => _goToTab(2),
          onNewProject: () => _openNewProjectWizard(),
          onViewAllProjects: () => _goToTab(3),
          onOpenCharacterStudio: () => _goToTab(1),
          onOpenAssets: () => _goToTab(2),
          onManageStudio: () => _goToTab(1),
          onTemplateQuickStart: (id) => _openNewProjectWizard(templateId: id),
          onImport: _importImageAsProject,
          onOpenProject: _editProject,
        );
      case 1:
        return CharacterStudioScreen(
          key: _characterStudioKey,
          embedded: true,
        );
      case 2:
        return TemplatesCanvasScreen(
          onTemplateSelected: (id) => _openNewProjectWizard(templateId: id),
        );
      case 3:
        return InkwellProjectsTab(
          projects: _filteredProjects,
          searchQuery: _projectsSearchVisible ? _searchQuery : '',
          onSearchChanged: (v) => setState(() {
            _searchQuery = v;
            _applySearchFilter();
          }),
          onNewProject: () => _openNewProjectWizard(),
          onOpen: _editProject,
          onMenu: _showProjectMenu,
        );
      case 4:
        return InkwellProfileTab(
          projects: savedProjects,
          onOpenProject: _editProject,
          onRefresh: () => setState(_loadProjects),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    if (_navIndex == 1) {
      return InkwellStudioAppBar(
        title: 'Character Studio',
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined,
                color: ComicTheme.primary),
            onPressed: () => _characterStudioKey.currentState?.saveCharacter(),
            tooltip: 'Save character',
          ),
        ],
      );
    }
    return InkwellAppBar(
      onMenu: _showDrawer,
      onProfile: () => _goToTab(4),
      showCloudSync: _navIndex == 0,
      showSearch: _navIndex == 3,
      onSearchTap: () => setState(() {
        _projectsSearchVisible = !_projectsSearchVisible;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ComicTheme.scaffoldBg,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: ComicTheme.inkwellLight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLogo(size: 56, showShadow: true),
                    SizedBox(height: 12),
                    Text(AppInfo.appName,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Comic editor on your device',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Import image as project'),
                onTap: () {
                  Navigator.pop(context);
                  _importImageAsProject();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Character Studio'),
                onTap: () {
                  Navigator.pop(context);
                  _goToTab(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  _goToTab(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Templates'),
                onTap: () {
                  Navigator.pop(context);
                  _goToTab(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Projects'),
                onTap: () {
                  Navigator.pop(context);
                  _goToTab(3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
      extendBody: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _navIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                onPressed: _quickSketch,
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Quick Sketch'),
              ),
            )
          : null,
      bottomNavigationBar: InkwellBottomNav(
        controller: _bottomBarController,
        onTap: _goToTab,
      ),
    );
  }
}
