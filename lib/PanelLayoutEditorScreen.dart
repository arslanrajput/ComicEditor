import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:comic_editor/project_hive_model.dart';
import 'package:comic_editor/project_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'PreviewPdf/PDFPageFormat.dart';
import 'PreviewPdf/PageMarginsPainter.dart';
import 'Resizeable/GridPainter.dart';
import 'PanelEditScreen.dart';
import 'PanelModel/PanelElementModel.dart';
import 'PanelModel/Project.dart';
import 'PreviewPdf/AllPagesPreviewScreen.dart';
import 'models/comic_template.dart';
import 'theme/comic_theme.dart';
import 'services/app_settings.dart';
import 'widgets/layout_editor_coach.dart';
import 'widgets/template_layout_preview.dart';
import 'utils/edit_history.dart';
import 'utils/project_clone.dart';
import 'utils/pdf_page_export.dart';
import 'screens/comic_reader_screen.dart';
import 'widgets/export_options_sheet.dart';
import 'widgets/panel_content_preview.dart';

enum AlignAlignment { topLeft, topRight, bottomLeft, bottomRight }

enum _SaveState { saving, saved, error }

class PanelLayoutEditorScreen extends StatefulWidget {
  final Project project;
  final String? applyTemplateOnOpen;

  const PanelLayoutEditorScreen({
    super.key,
    required this.project,
    this.applyTemplateOnOpen,
  });

  @override
  State<PanelLayoutEditorScreen> createState() =>
      _PanelLayoutEditorScreenState();
}

class _PanelLayoutEditorScreenState extends State<PanelLayoutEditorScreen>
    with WidgetsBindingObserver {
  late Project currentProject;
  int currentPageIndex = 0;
  bool isDrawerOpen = false;
  List<List<LayoutPanel>> pages = [[]];
  int _currentPage = 0;
  LayoutPanel? selectedPanel;
  final GlobalKey _canvasKey = GlobalKey();
  bool _showGrid = false;
  bool _snapToGrid = false;
  String _selectedPageFormat = 'A4';
  final _pageHistory = EditHistory<List<List<LayoutPanel>>>();
  bool _showPageMargins = true;
  final double _pageMargin = 10.0;

  double _drawerTopOffset = 100.0; // initial vertical position

  Size get _currentPageSize => PDFPageFormat.formats[_selectedPageFormat]!;

  double get _canvasWidth => _currentPageSize.width;

  double get _canvasHeight => _currentPageSize.height;

  List<LayoutPanel> get currentPagePanels => currentProject.pages.isNotEmpty
      ? currentProject.pages[currentPageIndex]
      : [];

  final double _minPanelSize = 40.0; // smaller min size

  // 👉 Floating inspector bar state
  bool _inspectorCollapsed = false;
  double _inspectorTop = 140.0;
  bool _lockAspect = false;

  // --- Autosave state ---

  Timer? _autosaveTimer;
  bool _dirty = false;
  final ValueNotifier<_SaveState> _saveState =
      ValueNotifier<_SaveState>(_SaveState.saved);

  // Wraps setState and marks project dirty
  void _mutate(VoidCallback changes) {
    _pageHistory.push(ProjectClone.clonePages(pages));
    setState(changes);
    _markDirty();
  }

  void _undoLayout() {
    final prev = _pageHistory.undo(ProjectClone.clonePages(pages));
    if (prev == null) return;
    setState(() {
      pages = prev;
      _currentPage = _currentPage.clamp(0, pages.length - 1);
      currentPageIndex = _currentPage;
      currentProject = currentProject.copyWith(
        pages: ProjectClone.clonePages(pages),
        lastModified: DateTime.now(),
      );
    });
    _markDirty();
  }

  void _redoLayout() {
    final next = _pageHistory.redo(ProjectClone.clonePages(pages));
    if (next == null) return;
    setState(() {
      pages = next;
      _currentPage = _currentPage.clamp(0, pages.length - 1);
      currentPageIndex = _currentPage;
      currentProject = currentProject.copyWith(
        pages: ProjectClone.clonePages(pages),
        lastModified: DateTime.now(),
      );
    });
    _markDirty();
  }

  // --- Page reordering state ---
  int? _hoveredPageIndex;
  bool _showReorderStrip = false;




  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    currentProject = widget.project;
    pages = List.from(widget.project.pages);
    _selectedPageFormat = AppSettings.defaultPageFormat;
    _showGrid = AppSettings.defaultShowGrid;
    _snapToGrid = AppSettings.defaultSnapToGrid;

    if (kDebugMode) {
      print('=== PanelLayoutEditorScreen INIT ===');
      print('Project: ${currentProject.name}');
      print('Pages count: ${pages.length}');
    }
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      if (kDebugMode) {
        print('Page $pageIndex: ${page.length} panels');
      }

      for (int panelIndex = 0; panelIndex < page.length; panelIndex++) {
        final panel = page[panelIndex];
        if (kDebugMode) {
          print(
              '  Panel $panelIndex (${panel.id}): ${panel.elements.length} elements');
        }

        for (int elementIndex = 0;
            elementIndex < panel.elements.length;
            elementIndex++) {
          final element = panel.elements[elementIndex];
          if (kDebugMode) {
            print(
                '    Element $elementIndex: ${element.type} - "${element.value}"');
          }
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.applyTemplateOnOpen != null &&
          widget.applyTemplateOnOpen!.isNotEmpty) {
        _applyTemplateById(widget.applyTemplateOnOpen!);
      }
      _showCoachIfNeeded();
    });
  }

  void _showCoachIfNeeded() {
    if (!mounted || AppSettings.layoutCoachComplete) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => LayoutEditorCoach(
          onOpenLayouts: _showLayoutTemplates,
        ),
      ),
    );
  }

  void _applyTemplateById(String id) {
    switch (id) {
      case 'grid_2x2':
        _applyGrid2x2Layout();
      case 'single_column':
        _applySingleColumnLayout();
      case 'two_column':
        _applyTwoColumnLayout();
      case 'three_column':
        _applyThreeColumnLayout();
      case 'two_row':
        _applyTwoRowLayout();
      case 'comic_strip':
        _applyComicStripLayout();
      case 'webtoon':
        _applyWebtoonLayout();
      case 'header_content':
        _applyHeaderContentLayout();
      case 'magazine':
        _applyMagazineLayout();
      case 'single_splash':
        _applySingleSplashLayout();
      case 'grid_3x2':
        _applyGrid3x2Layout();
      case 'grid_2x3':
        _applyGrid2x3Layout();
      case 'manga_page':
        _applyMangaPageLayout();
      case 'five_panel':
        _applyFivePanelLayout();
      case 'four_strip':
        _applyFourStripLayout();
      case 'splash_three':
        _applySplashThreeLayout();
      case 'story_l':
        _applyStoryLLayout();
    }
  }

  void _applyWebtoonLayout() {
    final contentWidth = _canvasWidth - (2 * _pageMargin);
    final gap = _pageMargin;
    final panelHeight =
        (_canvasHeight - (5 * _pageMargin)) / 4; // 4 vertical panels

    _mutate(() {
      pages[_currentPage] = List.generate(4, (i) {
        return LayoutPanel(
          id: 'Webtoon ${i + 1}',
          x: _pageMargin,
          y: _pageMargin + i * (panelHeight + gap),
          width: contentWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        );
      });
      selectedPanel = null;
    });
  }

  void _showPageFormatPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: PDFPageFormat.formats.keys.map((format) {
            final selected = _selectedPageFormat == format;
            return ListTile(
              leading: Icon(
                Icons.description_outlined,
                color: selected ? ComicTheme.primary : null,
              ),
              title: Text(format),
              trailing: selected ? const Icon(Icons.check, color: ComicTheme.primary) : null,
              onTap: () {
                setState(() => _selectedPageFormat = format);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _deleteCurrentPage() {
    if (pages.length <= 1) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this page?'),
        content: const Text('This page and its panels will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _mutate(() {
                pages.removeAt(_currentPage);
                if (_currentPage > 0) _currentPage--;
                currentPageIndex = _currentPage;
                selectedPanel = null;
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openResizePanel() {
    if (selectedPanel == null) return;
    final panel = selectedPanel!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildInspectorContent(panel, inSheet: true),
      ),
    );
  }

  bool get _useMobileResize =>
      MediaQuery.sizeOf(context).width < 720;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save when app backgrounds or is about to detach
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _flushAutosaveNow(); // fire & forget
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _flushAutosaveNow();
        if (context.mounted) {
          Navigator.of(context).pop(currentProject);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          currentProject.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSaveStatusPill(),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) _toggleDrawer(true);
            if (details.primaryVelocity! < 0) _toggleDrawer(false);
          }
        },
        onTap: () {
          if (isDrawerOpen) _toggleDrawer(false);
          setState(() => selectedPanel = null);
        },
        child: Stack(
          children: [
            Column(
              children: [
                _buildLayoutToolbar(),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _canvasWidth / _canvasHeight,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final scaleX = constraints.maxWidth / _canvasWidth;
                          final scaleY = constraints.maxHeight / _canvasHeight;
                          return RepaintBoundary(
                            key: _canvasKey,
                            child: Container(
                              color: Colors.grey[100],
                              child: DragTarget<LayoutPanel>(
                                onAcceptWithDetails: (details) {
                                  final box = _canvasKey.currentContext
                                      ?.findRenderObject() as RenderBox?;
                                  if (box != null) {
                                    final offset =
                                        box.globalToLocal(details.offset);
                                    final incoming = details.data;
                                    final newPanel = LayoutPanel(
                                      id: incoming.id,
                                      width: incoming.width,
                                      height: incoming.height,
                                      x: (offset.dx - incoming.width / 2).clamp(
                                          _pageMargin,
                                          _canvasWidth -
                                              incoming.width -
                                              _pageMargin),
                                      y: (offset.dy - incoming.height / 2)
                                          .clamp(
                                              _pageMargin,
                                              _canvasHeight -
                                                  incoming.height -
                                                  _pageMargin),
                                      backgroundColor: Colors.white,
                                    );
                                    if (!_isOverlapping(newPanel)) {
                                      _mutate(() {
                                        pages[_currentPage].add(newPanel);
                                      });
                                    }
                                  }
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                  return Stack(
                                    children: [
                                      if (_showGrid)
                                        Transform.scale(
                                          scale: min(scaleX, scaleY),
                                          alignment: Alignment.topLeft,
                                          child: _buildGridOverlay(),
                                        ),
                                      Transform.scale(
                                        scale: min(scaleX, scaleY),
                                        alignment: Alignment.topLeft,
                                        child: _buildPageMarginsOverlay(),
                                      ),
                                      if (pages[_currentPage].isEmpty)
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.description_outlined,
                                                  size: 64,
                                                  color: Colors.grey[400]),
                                              const SizedBox(height: 16),
                                              Text('Empty Page',
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Text(
                                                  'Tap Layouts for a template, or Add Panel below',
                                                  style: TextStyle(
                                                      color: Colors.grey[500])),
                                              const SizedBox(height: 4),
                                              Text(
                                                  'Double-tap a panel to edit content',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[400])),
                                            ],
                                          ),
                                        ),
                                      ...pages[_currentPage].map((panel) {
                                        return Positioned(
                                          left: panel.x * scaleX,
                                          top: panel.y * scaleY,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedPanel =
                                                    selectedPanel?.id == panel.id
                                                        ? null
                                                        : panel;
                                              });
                                            },
                                            onDoubleTap: () {
                                              setState(() => selectedPanel = panel);
                                              _editSelectedPanel();
                                            },
                                            onPanUpdate: (details) {
                                              double newX = panel.x +
                                                  details.delta.dx / scaleX;
                                              double newY = panel.y +
                                                  details.delta.dy / scaleY;
                                              if (_snapToGrid) {
                                                newX =
                                                    (newX / 20).round() * 20.0;
                                                newY =
                                                    (newY / 20).round() * 20.0;
                                              }
                                              newX = newX.clamp(
                                                  _pageMargin,
                                                  _canvasWidth -
                                                      panel.width -
                                                      _pageMargin);
                                              newY = newY.clamp(
                                                  _pageMargin,
                                                  _canvasHeight -
                                                      panel.height -
                                                      _pageMargin);
                                              final movedPanel = panel.copyWith(
                                                  x: newX, y: newY);
                                              if (!_isOverlapping(movedPanel,
                                                  excludePanel: panel)) {
                                                _mutate(() {
                                                  panel.x = newX;
                                                  panel.y = newY;
                                                });
                                              }
                                            },
                                            child: Transform.scale(
                                              scale: min(scaleX, scaleY),
                                              alignment: Alignment.topLeft,
                                              child: _buildPanelContent(panel),
                                            ),
                                          ),
                                        );
                                      }).toList(),

                                      /*...pages[_currentPage]
                                          .map((panel) => _buildPanelWithResize(
                                              panel, scaleX, scaleY))
                                          .toList(),*/
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // 4) Footer – ONLY pages section (make sure your _buildFooter now shows pages strip)
                _buildFooter(),
              ],
            ),

            // Right floating inspector (tablet+)
            if (selectedPanel != null && !_useMobileResize)
              _buildRightFloatingInspector(selectedPanel!),

            _buildFloatingDrawerWithToggle(
                screenHeight, 150, screenHeight * 0.4),

            // Floating Toggle Icon
            Positioned(
              left: isDrawerOpen ? 150 : 0,
              top: _drawerTopOffset + (screenHeight * 0.4 / 2) - 20,
              child: GestureDetector(
                onTap: () => setState(() => isDrawerOpen = !isDrawerOpen),
                onPanUpdate: (details) {
                  setState(() {
                    _drawerTopOffset += details.delta.dy;
                    _drawerTopOffset = _drawerTopOffset.clamp(
                        0.0, screenHeight - (screenHeight * 0.4));
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: Icon(
                    isDrawerOpen
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
/*
            if (selectedPanel != null) _buildFloatingEditButton(),
*/
          ],
        ),
      ),
    ),
    );
  }

  // ---------- Autosave ----------
  void _markDirty() {
    _dirty = true;
    _scheduleAutosave(); // debounce
  }

  void _scheduleAutosave(
      [Duration delay = const Duration(milliseconds: 1200)]) {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(delay, _flushAutosaveNow);
  }

  Future<void> _flushAutosaveNow() async {
    _autosaveTimer?.cancel();
    if (!_dirty) return;
    _saveState.value = _SaveState.saving;
    try {
      await _saveCurrentProjectToHive(); // writes to Hive
      _dirty = false;
      _saveState.value = _SaveState.saved;
    } catch (e) {
      debugPrint('Autosave failed: $e');
      _saveState.value = _SaveState.error;
    }
  }

  Future<void> _saveCurrentProjectToHive() async {
    final box = Hive.box<ProjectHiveModel>('drafts');
    final updated = currentProject.copyWith(
      pages: pages,
      lastModified: DateTime.now(),
    );
    final hiveModel = toHiveModel(updated);
    await box.put(updated.id, hiveModel);
    currentProject = updated; // keep local in sync
  }

  // Optional: a small “Saved / Saving…” pill for AppBar
  Widget _buildSaveStatusPill() {
    return ValueListenableBuilder<_SaveState>(
      valueListenable: _saveState,
      builder: (_, state, __) {
        Widget icon;
        String text;
        switch (state) {
          case _SaveState.saving:
            icon = const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
            text = 'Saving…';
            break;
          case _SaveState.saved:
            icon = const Icon(Icons.check, size: 16);
            text = 'Saved';
            break;
          case _SaveState.error:
            icon = const Icon(Icons.error_outline, size: 16);
            text = 'Save failed';
            break;
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: state == _SaveState.error
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  state == _SaveState.error ? Colors.redAccent : Colors.green,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 6),
              Text(text, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  // end of save

  /// Top icon toolbar — matches wireframe (export, preview, margins, grid, layouts, add page).
  Widget _buildLayoutToolbar() {
    return Container(
      decoration: ComicTheme.editorToolbarDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.aspect_ratio_outlined,
              label: _selectedPageFormat,
              onPressed: _showPageFormatPicker,
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.remove_red_eye_outlined,
              label: 'Preview',
              onPressed: _showAllPagesPreview,
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.margin_outlined,
              label: 'Margins',
              active: _showPageMargins,
              onPressed: () =>
                  _mutate(() => _showPageMargins = !_showPageMargins),
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.grid_on_outlined,
              label: 'Grid',
              active: _showGrid,
              onPressed: () => _mutate(() => _showGrid = !_showGrid),
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.dashboard_customize_outlined,
              label: 'Layouts',
              onPressed: _showLayoutTemplates,
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.auto_stories_outlined,
              label: 'Read',
              onPressed: _openReader,
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.download_outlined,
              label: 'Export',
              onPressed: _showExportOptions,
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.undo,
              label: 'Undo',
              onPressed: _pageHistory.canUndo ? _undoLayout : () {},
            ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.redo,
              label: 'Redo',
              onPressed: _pageHistory.canRedo ? _redoLayout : () {},
            ),
            if (pages.isNotEmpty)
              ComicTheme.toolbarIconButton(
                context: context,
                icon: Icons.copy_all_outlined,
                label: 'Dup Page',
                onPressed: _duplicateCurrentPage,
              ),
            if (pages.length > 1)
              ComicTheme.toolbarIconButton(
                context: context,
                icon: Icons.delete_sweep_outlined,
                label: 'Del Page',
                onPressed: _deleteCurrentPage,
              ),
            ComicTheme.toolbarIconButton(
              context: context,
              icon: Icons.note_add_outlined,
              label: 'Add Page',
              onPressed: _addPage,
            ),
            if (pages.length > 1)
              ComicTheme.toolbarIconButton(
                context: context,
                icon: Icons.swap_vert,
                label: _showReorderStrip ? 'Done' : 'Reorder',
                active: _showReorderStrip,
                onPressed: () => setState(() {
                  _showReorderStrip = !_showReorderStrip;
                  _hoveredPageIndex = null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Menu Drawer ----------

  //---------- AutoSave functionality ----------

  // ---------- Page Ra_arrangement ----------

  Widget _buildReorderablePageThumb(int index) {
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.9, child: _buildPageThumbnail(index)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildPageThumbnail(index),
      ),
      onDragStarted: () {},
      onDraggableCanceled: (_, __) => setState(() {
        _hoveredPageIndex = null;
      }),
      onDragEnd: (_) => setState(() {
        _hoveredPageIndex = null;
      }),
      child: DragTarget<int>(
        onWillAccept: (from) {
          setState(() => _hoveredPageIndex = index);
          return from != index;
        },
        onLeave: (_) => setState(() => _hoveredPageIndex = null),
        onAccept: (from) {
          _reorderPages(from, index); // insert BEFORE this index
          setState(() {
            _hoveredPageIndex = null;
          });
        },
        builder: (context, _, __) {
          return GestureDetector(
            onTap: () => _switchPage(index),
            child: _buildPageThumbnail(index),
          );
        },
      ),
    );
  }

  Widget _buildEndDropTarget() {
    final isHoverEnd = _hoveredPageIndex == pages.length;
    return DragTarget<int>(
      onWillAccept: (_) {
        setState(() => _hoveredPageIndex = pages.length);
        return true;
      },
      onLeave: (_) => setState(() => _hoveredPageIndex = null),
      onAccept: (from) {
        _reorderPages(from, pages.length); // append to end
        setState(() => _hoveredPageIndex = null);
      },
      builder: (context, _, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          width: 64,
          height: 112,
          decoration: BoxDecoration(
            color: isHoverEnd ? Colors.orange.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHoverEnd ? Colors.orange : Colors.black12,
              style: BorderStyle.solid,
              width: isHoverEnd ? 2 : 1,
            ),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 20),
          ),
        );
      },
    );
  }

  void _reorderPages(int from, int to) {
    if (from == to) return;

    setState(() {
      // If user drops onto the final "add to end" zone, `to` can equal pages.length
      final removed = pages.removeAt(from);
      final insertIndex = (to > from) ? to - 1 : to;
      final safeIndex = insertIndex.clamp(0, pages.length);
      pages.insert(safeIndex, removed);

      // Keep current page selection reasonable after move
      var cur = _currentPage;
      if (cur == from) {
        cur = safeIndex;
      } else if (from < cur && to - 1 >= cur) {
        cur -= 1; // dragged a page up past the current page
      } else if (from > cur && to <= cur) {
        cur += 1; // dragged a page down before the current page
      }
      _currentPage = cur.clamp(0, pages.length - 1);
      currentPageIndex = _currentPage;

      currentProject = currentProject.copyWith(
        pages: pages,
        lastModified: DateTime.now(),
      );
    });
    _markDirty();
  }

  Widget _buildPageThumbnail(int pageIndex) {
    // small portrait preview
    const double thumbW = 70;
    const double thumbH = 80;

    final wScale = thumbW / _canvasWidth;
    final hScale = thumbH / _canvasHeight;

    final isActive = _currentPage == pageIndex;
    final isHover = _hoveredPageIndex == pageIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.blue
              : (isHover ? Colors.orange : Colors.black12),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: thumbW,
            height: thumbH,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // draw light panel boxes as a hint of layout
                ...pages[pageIndex].map((p) {
                  final l = p.x * wScale;
                  final t = p.y * hScale;
                  final w = (p.width * wScale).clamp(1.0, thumbW);
                  final h = (p.height * hScale).clamp(1.0, thumbH);
                  return Positioned(
                    left: l,
                    top: t,
                    width: w,
                    height: h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        border:
                            Border.all(color: Colors.grey.shade600, width: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pageIndex + 1}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------- Page Ra_arrangement ----------

  Widget _buildInspectorContent(LayoutPanel panel, {bool inSheet = false}) {
    final double maxW = _canvasWidth - 2 * _pageMargin;
    final double maxH = _canvasHeight - 2 * _pageMargin;
    final theme = Theme.of(context);
    final double aspect = panel.width > 0 ? (panel.height / panel.width) : 1.0;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: inSheet
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: inSheet
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : const BorderRadius.vertical(top: Radius.circular(14)),
              color: Colors.blue.shade50,
              border: const Border(bottom: BorderSide(color: Color(0x11000000))),
            ),
            child: Row(
              children: [
                Icon(Icons.open_with,
                    color: Colors.blue.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    panel.id.isNotEmpty ? panel.id : 'Panel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (inSheet)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                else
                  IconButton(
                    tooltip: _inspectorCollapsed ? 'Expand' : 'Collapse',
                    icon: Icon(_inspectorCollapsed
                        ? Icons.unfold_more
                        : Icons.unfold_less),
                    onPressed: () => setState(
                        () => _inspectorCollapsed = !_inspectorCollapsed),
                  ),
              ],
            ),
          ),
          if (inSheet || !_inspectorCollapsed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Text('W: ${panel.width.toInt()}  H: ${panel.height.toInt()}',
                      style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _lockAspect = !_lockAspect),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _lockAspect
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _lockAspect ? Colors.blue : Colors.black12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_lockAspect ? Icons.lock : Icons.lock_open,
                              size: 16,
                              color: _lockAspect ? Colors.blue : Colors.black54),
                          const SizedBox(width: 6),
                          Text('Lock',
                              style: TextStyle(
                                color: _lockAspect
                                    ? Colors.blue
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: const [
                  Icon(Icons.swap_horiz, size: 18),
                  SizedBox(width: 8),
                  Text('Width', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Slider(
                min: _minPanelSize,
                max: maxW,
                value: panel.width.clamp(_minPanelSize, maxW),
                onChanged: (v) {
                  double newW = v;
                  double newH = _lockAspect ? (newW * aspect) : panel.height;
                  newH = newH.clamp(_minPanelSize, maxH);
                  double newX = panel.x.clamp(
                      _pageMargin, _canvasWidth - newW - _pageMargin);
                  double newY = panel.y.clamp(
                      _pageMargin, _canvasHeight - newH - _pageMargin);
                  _applyResize(panel,
                      x: newX, y: newY, width: newW, height: newH);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                children: const [
                  Icon(Icons.swap_vert, size: 18),
                  SizedBox(width: 8),
                  Text('Height', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Slider(
                min: _minPanelSize,
                max: maxH,
                value: panel.height.clamp(_minPanelSize, maxH),
                onChanged: (v) {
                  double newH = v;
                  double newW = _lockAspect ? (newH / aspect) : panel.width;
                  newW = newW.clamp(_minPanelSize, maxW);
                  double newY = panel.y.clamp(
                      _pageMargin, _canvasHeight - newH - _pageMargin);
                  double newX = panel.x.clamp(
                      _pageMargin, _canvasWidth - newW - _pageMargin);
                  _applyResize(panel,
                      x: newX, y: newY, width: newW, height: newH);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip('½ width', () {
                    final targetW = ((_canvasWidth - 3 * _pageMargin) / 2)
                        .clamp(_minPanelSize, maxW);
                    _applyResize(panel, width: targetW);
                  }),
                  _presetChip('Square', () {
                    final side =
                        min(maxW, maxH).clamp(_minPanelSize, double.infinity);
                    _applyResize(panel, width: side, height: side);
                  }),
                  _presetChip('Fit width', () {
                    final targetW = (_canvasWidth - 2 * _pageMargin)
                        .clamp(_minPanelSize, maxW);
                    _applyResize(panel, width: targetW);
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Floating Inspector (RIGHT) ----------
  Widget _buildRightFloatingInspector(LayoutPanel panel) {
    return Positioned(
      right: 16,
      top: _inspectorTop,
      child: GestureDetector(
        onPanUpdate: (d) {
          final screenH = MediaQuery.of(context).size.height;
          setState(() {
            _inspectorTop += d.delta.dy;
            _inspectorTop = _inspectorTop.clamp(80.0, screenH - 260.0);
          });
        },
        child: SizedBox(
          width: 280,
          child: _buildInspectorContent(panel),
        ),
      ),
    );
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// Centralized resize apply with clamp + overlap check
  void _applyResize(
    LayoutPanel panel, {
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    final double maxW = _canvasWidth - 2 * _pageMargin;
    final double maxH = _canvasHeight - 2 * _pageMargin;

    double newW = (width ?? panel.width).clamp(_minPanelSize, maxW);
    double newH = (height ?? panel.height).clamp(_minPanelSize, maxH);

    double newX =
        (x ?? panel.x).clamp(_pageMargin, _canvasWidth - newW - _pageMargin);
    double newY =
        (y ?? panel.y).clamp(_pageMargin, _canvasHeight - newH - _pageMargin);

    final resized = panel.copyWith(x: newX, y: newY, width: newW, height: newH);
    if (!_isOverlapping(resized, excludePanel: panel)) {
      _mutate(() {
        final idx = pages[_currentPage].indexWhere((p) => p.id == panel.id);
        if (idx != -1) {
          pages[_currentPage][idx] = resized;
          if (selectedPanel?.id == panel.id) selectedPanel = resized;
        }
      });
    }
  }

  void _addPage() {
    _mutate(() {
      /*final newPage = [
        LayoutPanel(
          id: DateTime
              .now()
              .millisecondsSinceEpoch
              .toString(),
          width: _canvasWidth * 0.3,
          height: _canvasHeight * 0.2,
          x: _pageMargin,
          y: _pageMargin,
          customText: 'Page ${currentProject.pages.length + 1} Panel',
          backgroundColor: Colors.white,
        ),
      ];*/
      final newPage = <LayoutPanel>[];

      currentProject = currentProject.copyWith(
        pages: [...currentProject.pages, newPage],
        lastModified: DateTime.now(),
      );
      pages = List.from(currentProject.pages);
      currentPageIndex = pages.length - 1;
      _currentPage = currentPageIndex;
    });
  }

  void _toggleDrawer(bool open) {
    setState(() => isDrawerOpen = open);
  }

  void _editSelectedPanel() async {
    if (selectedPanel == null) return;
    final actualPanel =
    pages[_currentPage].firstWhere((p) => p.id == selectedPanel!.id);

    final panelForEditing = actualPanel.toComicPanel();

    final updatedPanel = await Navigator.push<ComicPanel>(
      context,
      MaterialPageRoute(
        builder: (context) => PanelEditScreen(
          panel: panelForEditing,
          panelOffset: Offset(actualPanel.x, actualPanel.y),
          panelSize: Size(actualPanel.width, actualPanel.height),
          onAutosave: (p) {
            // 🔴 IMPORTANT: write-through to your project model on every autosave
            _mutate(() {
              final index = pages[_currentPage]
                  .indexWhere((pl) => pl.id == actualPanel.id);
              if (index != -1) {
                pages[_currentPage][index] =
                    actualPanel.updateFromComicPanel(p);
                selectedPanel = pages[_currentPage][index];

                final updatedPages =
                List<List<LayoutPanel>>.from(currentProject.pages);
                updatedPages[_currentPage] =
                List<LayoutPanel>.from(pages[_currentPage]);

                currentProject = currentProject.copyWith(
                  pages: updatedPages,
                  lastModified: DateTime.now(),
                );
              }
            });
          },
        ),
      ),
    );

    // User tapped Save: also apply final returned panel
    if (updatedPanel != null) {
      _mutate(() {
        final index = pages[_currentPage]
            .indexWhere((p) => p.id == selectedPanel!.id);
        if (index != -1) {
          pages[_currentPage][index] =
              actualPanel.updateFromComicPanel(updatedPanel);
          selectedPanel = pages[_currentPage][index];

          final updatedPages =
          List<List<LayoutPanel>>.from(currentProject.pages);
          updatedPages[_currentPage] =
          List<LayoutPanel>.from(pages[_currentPage]);

          currentProject = currentProject.copyWith(
            pages: updatedPages,
            lastModified: DateTime.now(),
          );
        }
      });
    }
  }


/*
  void _editSelectedPanel() async {
    if (selectedPanel == null) return;
    final actualPanel =
        pages[_currentPage].firstWhere((p) => p.id == selectedPanel!.id);
    for (int i = 0; i < actualPanel.elements.length; i++) {
      final element = actualPanel.elements[i];
    }
    var panelForEditing = actualPanel.toComicPanel();

    final updatedPanel = await Navigator.push<ComicPanel>(
      context,
      MaterialPageRoute(
        builder: (context) => PanelEditScreen(
          panel: panelForEditing,
          panelOffset: Offset(actualPanel.x, actualPanel.y),
          panelSize: Size(actualPanel.width, actualPanel.height),
          onAutosave: (p) {
            setState(() => panelForEditing = p);          // keep parent model in sync
            // also persist to your DB if you have one
            // await repo.save(p);
          },
        ),
      ),
    );

    if (updatedPanel != null) {
      _mutate(() {
        final index = pages[_currentPage].indexWhere(
          (p) => p.id == selectedPanel!.id,
        );
        if (index != -1) {
          pages[_currentPage][index] =
              actualPanel.updateFromComicPanel(updatedPanel);
          selectedPanel = pages[_currentPage][index];
          final updatedPages =
              List<List<LayoutPanel>>.from(currentProject.pages);
          updatedPages[_currentPage] =
              List<LayoutPanel>.from(pages[_currentPage]);
          currentProject = currentProject.copyWith(
            pages: updatedPages,
            lastModified: DateTime.now(),
          );
        }
      });
    }
  }
*/

  void _deleteSelectedPanel() {
    if (selectedPanel != null) {
      _mutate(() {
        pages[_currentPage].remove(selectedPanel);
        selectedPanel = null;
      });
    }
  }

  void _addSinglePanel() {
    final panelWidth =
        (_canvasWidth - (_pageMargin * 2)) / 2; // Two panels per row
    final panelHeight = _canvasHeight * 0.25;

    final newPanel = LayoutPanel(
      // id: "Panel_${DateTime.now().microsecondsSinceEpoch}", // Unique ID always
      id: "Panel ${pages[_currentPage].length + 1}",
      width: panelWidth,
      height: panelHeight,
      x: _pageMargin,
      y: _pageMargin,
      backgroundColor: Colors.white,
    );

    Offset? freePosition = _findFreePosition(newPanel);

    if (freePosition == null) {
      // No space available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No more space on this page. Add a new page."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    newPanel.x = freePosition.dx;
    newPanel.y = freePosition.dy;

    _mutate(() {
      pages[_currentPage].add(newPanel);
    });
  }

  bool get _canAddMorePanels {
    final panelWidth = (_canvasWidth - (_pageMargin * 2)) / 2;
    final panelHeight = _canvasHeight * 0.25;
    final testPanel = LayoutPanel(
      id: 'test',
      width: panelWidth,
      height: panelHeight,
      x: 0,
      y: 0,
      backgroundColor: Colors.white,
    );
    return _findFreePosition(testPanel) != null;
  }

  Offset? _findFreePosition(LayoutPanel panel) {
    const double rowSpacing = 20.0; // space between rows
    const int panelsPerRow = 2;

    final double horizontalSpacing = 0;
    final double panelWidth = panel.width;
    final double panelHeight = panel.height;

    final double maxX = _canvasWidth - _pageMargin - panelWidth;
    final double maxY = _canvasHeight - _pageMargin - panelHeight;

    for (double y = _pageMargin; y <= maxY; y += panelHeight + rowSpacing) {
      for (int i = 0; i < panelsPerRow; i++) {
        double x = _pageMargin + i * (panelWidth + horizontalSpacing);
        if (x > maxX) break;

        final testPanel = panel.copyWith(x: x, y: y);
        if (!_isOverlapping(testPanel)) {
          return Offset(x, y);
        }
      }
    }

    return null;
  }

/*  void _switchPage(int index) {
    setState(() {
      _currentPage = index;
      selectedPanel = null;
    });
  }*/

  // ---------- change this for Page Ra_arrangement ----------
  void _switchPage(int index) {
    setState(() {
      _currentPage = index;
      currentPageIndex = index; // keep this synced
      selectedPanel = null;
    });
  }

  // ---------- Page Ra_arrangement ----------

  void _showAllPagesPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllPagesPreviewScreen(
          pages: pages,
          projectName: currentProject.name,
          pageFormat: _selectedPageFormat,
        ),
      ),
    );
  }

  void _showLayoutTemplates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Layout Templates',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // remove the text showing the  page format',
                        'Optimized for format',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    ...kComicTemplates.where((t) => !t.isBlank).map(
                          (t) => _buildLayoutTemplate(
                            template: t,
                            onTap: () => _applyTemplateById(t.id),
                          ),
                        ),
                    _buildLayoutTemplate(
                      title: 'Clear All',
                      description: 'Remove all panels',
                      color: Colors.grey,
                      icon: Icons.clear_all,
                      onTap: () {
                        _mutate(() {
                          pages[_currentPage].clear();
                          selectedPanel = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayoutTemplate({
    ComicTemplate? template,
    String? title,
    String? description,
    Color? color,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final displayTitle = template?.title ?? title!;
    final displayDescription = template?.description ?? description!;
    final displayColor = template?.color ?? color!;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          onTap();
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (template != null)
                TemplateLayoutPreview(
                  templateId: template.id,
                  accentColor: template.color,
                  width: double.infinity,
                  height: 56,
                )
              else
                Icon(icon, size: 40, color: displayColor),
              const SizedBox(height: 8),
              Text(
                displayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                displayDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applySingleColumnLayout() {
    final contentWidth = _canvasWidth - (2 * _pageMargin);
    final panelHeight = (_canvasHeight - (4 * _pageMargin)) / 3;

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Header Panel",
          x: _pageMargin,
          y: _pageMargin,
          width: contentWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Content Panel",
          x: _pageMargin,
          y: _pageMargin * 2 + panelHeight,
          width: contentWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Footer Panel",
          x: _pageMargin,
          y: _pageMargin * 3 + panelHeight * 2,
          width: contentWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyTwoColumnLayout() {
    final contentWidth = _canvasWidth - (3 * _pageMargin);
    final panelWidth = contentWidth / 2;
    final panelHeight = _canvasHeight - (2 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Left Column",
          x: _pageMargin,
          y: _pageMargin,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Right Column",
          x: _pageMargin * 2 + panelWidth,
          y: _pageMargin,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyThreeColumnLayout() {
    final contentWidth = _canvasWidth - (4 * _pageMargin);
    final panelWidth = contentWidth / 3;
    final panelHeight = _canvasHeight - (2 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Column 1",
          x: _pageMargin,
          y: _pageMargin,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Column 2",
          x: _pageMargin * 2 + panelWidth,
          y: _pageMargin,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Column 3",
          x: _pageMargin * 3 + panelWidth * 2,
          y: _pageMargin,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyGrid2x2Layout() {
    final contentWidth = _canvasWidth - (3 * _pageMargin);
    final contentHeight = _canvasHeight - (3 * _pageMargin);
    final panelWidth = contentWidth / 2;
    final panelHeight = contentHeight / 2;

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Top Left",
          x: _pageMargin,
          y: _pageMargin,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Top Right",
          x: _pageMargin * 2 + panelWidth,
          y: _pageMargin,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Bottom Left",
          x: _pageMargin,
          y: _pageMargin * 2 + panelHeight,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Bottom Right",
          x: _pageMargin * 2 + panelWidth,
          y: _pageMargin * 2 + panelHeight,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyHeaderContentLayout() {
    final contentWidth = _canvasWidth - (2 * _pageMargin);
    final headerHeight = _canvasHeight * 0.2;
    final contentHeight = _canvasHeight - headerHeight - (3 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Header",
          x: _pageMargin,
          y: _pageMargin,
          width: contentWidth,
          height: headerHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Main Content",
          x: _pageMargin,
          y: _pageMargin * 2 + headerHeight,
          width: contentWidth,
          height: contentHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyComicStripLayout() {
    final contentWidth = _canvasWidth - (4 * _pageMargin);
    final panelWidth = contentWidth / 3;
    final panelHeight = _canvasHeight * 0.6;
    final startY = (_canvasHeight - panelHeight) / 2;

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Panel 1",
          x: _pageMargin,
          y: startY,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Panel 2",
          x: _pageMargin * 2 + panelWidth,
          y: startY,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Panel 3",
          x: _pageMargin * 3 + panelWidth * 2,
          y: startY,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyTwoRowLayout() {
    final contentWidth = _canvasWidth - (3 * _pageMargin);
    final topPanelHeight = _canvasHeight * 0.4;
    final bottomPanelHeight =
        _canvasHeight - topPanelHeight - (3 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Top Panel",
          x: _pageMargin,
          y: _pageMargin,
          width: contentWidth,
          height: topPanelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Bottom Panel",
          x: _pageMargin,
          y: topPanelHeight + (2 * _pageMargin),
          width: contentWidth,
          height: bottomPanelHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyMagazineLayout() {
    final contentWidth = _canvasWidth - (3 * _pageMargin);
    final leftPanelWidth = contentWidth * 0.6;
    final rightPanelWidth = contentWidth * 0.4;
    final topRightHeight = _canvasHeight * 0.3;
    final bottomRightHeight =
        _canvasHeight - topRightHeight - (3 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: "Main Article",
          x: _pageMargin,
          y: _pageMargin,
          width: leftPanelWidth,
          height: _canvasHeight - (2 * _pageMargin),
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Sidebar Top",
          x: _pageMargin + leftPanelWidth + _pageMargin,
          // corrected here
          y: _pageMargin,
          width: rightPanelWidth,
          height: topRightHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: "Sidebar Bottom",
          x: _pageMargin + leftPanelWidth + _pageMargin,
          // same fix
          y: _pageMargin + topRightHeight + _pageMargin,
          width: rightPanelWidth,
          height: bottomRightHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applySingleSplashLayout() {
    final contentWidth = _canvasWidth - (2 * _pageMargin);
    final contentHeight = _canvasHeight - (2 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: 'Splash',
          x: _pageMargin,
          y: _pageMargin,
          width: contentWidth,
          height: contentHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyGrid3x2Layout() {
    final contentWidth = _canvasWidth - (4 * _pageMargin);
    final contentHeight = _canvasHeight - (3 * _pageMargin);
    final panelWidth = contentWidth / 3;
    final panelHeight = contentHeight / 2;

    _mutate(() {
      pages[_currentPage] = List.generate(6, (i) {
        final col = i % 3;
        final row = i ~/ 3;
        return LayoutPanel(
          id: 'Panel ${i + 1}',
          x: _pageMargin + col * (panelWidth + _pageMargin),
          y: _pageMargin + row * (panelHeight + _pageMargin),
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        );
      });
      selectedPanel = null;
    });
  }

  void _applyGrid2x3Layout() {
    final contentWidth = _canvasWidth - (3 * _pageMargin);
    final contentHeight = _canvasHeight - (4 * _pageMargin);
    final panelWidth = contentWidth / 2;
    final panelHeight = contentHeight / 3;

    _mutate(() {
      pages[_currentPage] = List.generate(6, (i) {
        final col = i % 2;
        final row = i ~/ 2;
        return LayoutPanel(
          id: 'Panel ${i + 1}',
          x: _pageMargin + col * (panelWidth + _pageMargin),
          y: _pageMargin + row * (panelHeight + _pageMargin),
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        );
      });
      selectedPanel = null;
    });
  }

  void _applyMangaPageLayout() {
    final contentWidth = _canvasWidth - (3 * _pageMargin);
    final leftWidth = contentWidth * 0.58;
    final rightWidth = contentWidth - leftWidth;
    final rightPanelHeight = (_canvasHeight - (3 * _pageMargin)) / 2;
    final fullHeight = _canvasHeight - (2 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: 'Main Scene',
          x: _pageMargin,
          y: _pageMargin,
          width: leftWidth,
          height: fullHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Detail Top',
          x: _pageMargin * 2 + leftWidth,
          y: _pageMargin,
          width: rightWidth,
          height: rightPanelHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Detail Bottom',
          x: _pageMargin * 2 + leftWidth,
          y: _pageMargin * 2 + rightPanelHeight,
          width: rightWidth,
          height: rightPanelHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyFivePanelLayout() {
    final contentWidth = _canvasWidth - (2 * _pageMargin);
    final innerWidth = contentWidth - _pageMargin;
    final availableHeight = _canvasHeight - (4 * _pageMargin);
    final topHeight = availableHeight * 0.38;
    final bottomHeight = availableHeight - topHeight - _pageMargin;
    final bottomPanelWidth = innerWidth / 2;
    final bottomY = _pageMargin * 2 + topHeight;

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: 'Wide Top',
          x: _pageMargin,
          y: _pageMargin,
          width: contentWidth,
          height: topHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Bottom 1',
          x: _pageMargin,
          y: bottomY,
          width: bottomPanelWidth,
          height: bottomHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Bottom 2',
          x: _pageMargin * 2 + bottomPanelWidth,
          y: bottomY,
          width: bottomPanelWidth,
          height: bottomHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Bottom 3',
          x: _pageMargin,
          y: bottomY + bottomHeight + _pageMargin,
          width: bottomPanelWidth,
          height: bottomHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Bottom 4',
          x: _pageMargin * 2 + bottomPanelWidth,
          y: bottomY + bottomHeight + _pageMargin,
          width: bottomPanelWidth,
          height: bottomHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  void _applyFourStripLayout() {
    final contentWidth = _canvasWidth - (5 * _pageMargin);
    final panelWidth = contentWidth / 4;
    final panelHeight = _canvasHeight * 0.55;
    final startY = (_canvasHeight - panelHeight) / 2;

    _mutate(() {
      pages[_currentPage] = List.generate(4, (i) {
        return LayoutPanel(
          id: 'Frame ${i + 1}',
          x: _pageMargin + i * (panelWidth + _pageMargin),
          y: startY,
          width: panelWidth,
          height: panelHeight,
          backgroundColor: Colors.white,
        );
      });
      selectedPanel = null;
    });
  }

  void _applySplashThreeLayout() {
    final contentWidth = _canvasWidth - (2 * _pageMargin);
    final innerWidth = contentWidth - (2 * _pageMargin);
    final splashHeight = (_canvasHeight - (4 * _pageMargin)) * 0.52;
    final rowHeight = _canvasHeight - splashHeight - (4 * _pageMargin);
    final rowPanelWidth = innerWidth / 3;
    final rowY = _pageMargin * 2 + splashHeight;

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: 'Hero Splash',
          x: _pageMargin,
          y: _pageMargin,
          width: contentWidth,
          height: splashHeight,
          backgroundColor: Colors.white,
        ),
        ...List.generate(3, (i) {
          return LayoutPanel(
            id: 'Row ${i + 1}',
            x: _pageMargin + i * (rowPanelWidth + _pageMargin),
            y: rowY,
            width: rowPanelWidth,
            height: rowHeight,
            backgroundColor: Colors.white,
          );
        }),
      ];
      selectedPanel = null;
    });
  }

  void _applyStoryLLayout() {
    final contentWidth = _canvasWidth - (3 * _pageMargin);
    final mainWidth = contentWidth * 0.62;
    final sideWidth = contentWidth - mainWidth;
    final mainHeight = (_canvasHeight - (3 * _pageMargin)) * 0.58;
    final bottomHeight =
        _canvasHeight - mainHeight - (3 * _pageMargin);
    final sideHeight = _canvasHeight - (2 * _pageMargin);

    _mutate(() {
      pages[_currentPage] = [
        LayoutPanel(
          id: 'Main Beat',
          x: _pageMargin,
          y: _pageMargin,
          width: mainWidth,
          height: mainHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Bottom Beat',
          x: _pageMargin,
          y: _pageMargin * 2 + mainHeight,
          width: mainWidth,
          height: bottomHeight,
          backgroundColor: Colors.white,
        ),
        LayoutPanel(
          id: 'Side Strip',
          x: _pageMargin * 2 + mainWidth,
          y: _pageMargin,
          width: sideWidth,
          height: sideHeight,
          backgroundColor: Colors.white,
        ),
      ];
      selectedPanel = null;
    });
  }

  Widget _buildPanelContent(LayoutPanel panel) {
    final isSelected = selectedPanel?.id == panel.id;
    return Container(
      width: panel.width,
      height: panel.height,
      decoration: ComicTheme.comicPanelFrame(selected: isSelected),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: panel.previewImage != null
            ? Image.memory(
                panel.previewImage!,
                fit: BoxFit.cover,
                width: panel.width,
                height: panel.height,
              )
            : _buildLivePanelContent(panel),
      ),
    );
  }

  Widget _buildLivePanelContent(LayoutPanel panel) {
    return PanelContentPreview(panel: panel);
  }

  Widget _buildPageMarginsOverlay() {
    if (!_showPageMargins) return Container();

    return CustomPaint(
      size: Size(_canvasWidth, _canvasHeight),
      painter: PageMarginsPainter(
        marginSize: _pageMargin,
        pageWidth: _canvasWidth,
        pageHeight: _canvasHeight,
      ),
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(
      size: Size(_canvasWidth, _canvasHeight),
      painter: GridPainter(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _flushAutosaveNow();
    super.dispose();
  }

  bool _isOverlapping(LayoutPanel newPanel, {LayoutPanel? excludePanel}) {
    return pages[_currentPage].any((panel) {
      if (panel == excludePanel) return false;
      return !(newPanel.x + newPanel.width <= panel.x ||
          newPanel.x >= panel.x + panel.width ||
          newPanel.y + newPanel.height <= panel.y ||
          newPanel.y >= panel.y + panel.height);
    });
  }

  _buildDraggablePanel(
      {required MaterialColor color,
      required String label,
      required double width,
      required double height}) {
    final layoutPanel = LayoutPanel(
      id: '$label ${pages[_currentPage].length + 1}',
      label: label,
      width: width,
      height: height,
      x: 0,
      y: 0,
      backgroundColor: Colors.white,
      customText: label,
    );
    return Draggable<LayoutPanel>(
      onDragStarted: () {
        if (isDrawerOpen) {
          setState(() {
            isDrawerOpen = false;
          });
        }
      },
      data: layoutPanel,
      feedback: Material(
        color: Colors.transparent,
        child: _buildPanelPreview(label, color, width, height, scale: 0.2),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildPanelPreview(label, color, width, height, scale: 0.25),
      ),
      child: _buildPanelPreview(label, color, width, height, scale: 0.25),
    );
  }

  Widget _buildPanelPreview(
    String label,
    Color color,
    double width,
    double height, {
    double scale = 1.0,
  }) {
    final visualWidth = width * scale;
    final visualHeight = height * scale;

    return Container(
      width: visualWidth.clamp(60.0, 140.0),
      height: visualHeight.clamp(40.0, 120.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPages() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              _currentPage > 0 ? () => _switchPage(_currentPage - 1) : null,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final selected = i == _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: selected ? ComicTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () => _switchPage(i),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected
                                ? ComicTheme.primaryDark
                                : ComicTheme.panelBorder,
                          ),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < pages.length - 1
              ? () => _switchPage(_currentPage + 1)
              : null,
        ),
      ],
    );
  }

  // ---------- change this for Page Ra_arrangement ----------
/*
  Widget _buildFooter() {
    return Container(
      color: Colors.grey.shade200,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _canAddMorePanels ? _addSinglePanel : null,
                  icon: Icon(Icons.add, size: 18),
                  label: Text("Add Panel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _canAddMorePanels ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: selectedPanel != null ? _editSelectedPanel : null,
                  icon: Icon(Icons.edit, size: 18),
                  label: Text("Edit Panel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedPanel != null ? Colors.orange : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      selectedPanel != null ? _deleteSelectedPanel : null,
                  icon: Icon(Icons.delete, size: 18),
                  label: Text("Delete Panel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedPanel != null ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showLayoutTemplates,
                  icon: Icon(Icons.dashboard_customize, size: 18),
                  label: Text("Layout Templates"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _saveAsDraft();
                  },
                  icon: Icon(Icons.save),
                  label: Text("Save"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: pages.length > 1
                      ? () {
                    _mutate(() {
                            pages.removeAt(_currentPage);
                            if (_currentPage > 0) _currentPage--;
                            currentProject = currentProject.copyWith(
                              pages: pages,
                              lastModified: DateTime.now(),
                            );
                          });
                        }
                      : null,
                  icon: Icon(Icons.delete_forever),
                  label: Text("Delete Page"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        pages.length > 1 ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
*/

  Widget _buildFooter() {
    return Container(
      color: ComicTheme.toolbarBg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPages(),
          const SizedBox(height: 8),
          _buildPanelActionButtons(),
          const SizedBox(height: 6),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _showReorderStrip
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pages.length + 1, // include the end drop target
                itemBuilder: (context, i) {
                  if (i == pages.length) return _buildEndDropTarget();
                  return _buildReorderablePageThumb(i);
                },
              ),
            ),
            secondChild: const SizedBox.shrink(), // hidden state
          ),

          // (Optional) small hint when visible
          if (_showReorderStrip) ...[
            const SizedBox(height: 4),
            const Text(
              'Drag thumbnails to reorder pages',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanelActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _canAddMorePanels ? _addSinglePanel : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Panel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: selectedPanel != null ? _editSelectedPanel : null,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Panel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: selectedPanel != null ? _deleteSelectedPanel : null,
                style: FilledButton.styleFrom(
                  backgroundColor: selectedPanel != null
                      ? Colors.red.shade50
                      : null,
                  foregroundColor:
                      selectedPanel != null ? Colors.red.shade700 : null,
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
        if (selectedPanel != null && _useMobileResize) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openResizePanel,
              icon: const Icon(Icons.open_with, size: 18),
              label: const Text('Resize Panel'),
            ),
          ),
        ],
      ],
    );
  }

  // ---------- change this for Page Ra_arrangement ----------

  void _duplicateCurrentPage() {
    if (pages.isEmpty) return;
    _mutate(() {
      final duplicated = ProjectClone.clonePages([pages[_currentPage]])[0];
      final newPages = ProjectClone.clonePages(pages);
      newPages.insert(_currentPage + 1, duplicated);
      pages = newPages;
      _currentPage += 1;
      currentPageIndex = _currentPage;
      currentProject = currentProject.copyWith(
        pages: newPages,
        lastModified: DateTime.now(),
      );
    });
  }

  void _openReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComicReaderScreen(
          pages: pages,
          projectName: currentProject.name,
          pageFormat: _selectedPageFormat,
        ),
      ),
    );
  }

  void _showExportOptions() {
    showComicExportSheet(
      context: context,
      pages: pages,
      projectName: currentProject.name,
      pageFormatKey: _selectedPageFormat,
    );
  }

  Widget _buildFloatingDrawerWithToggle(
    double screenHeight,
    double drawerWidth,
    double drawerHeight,
  ) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      left: isDrawerOpen ? 0 : -drawerWidth,
      top: _drawerTopOffset.clamp(0.0, screenHeight - drawerHeight),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _drawerTopOffset += details.delta.dy;
            _drawerTopOffset =
                _drawerTopOffset.clamp(0.0, screenHeight - drawerHeight);
          });
        },
        child: Stack(
          children: [
            Material(
              elevation: 6,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: drawerWidth,
                height: drawerHeight,
                decoration: BoxDecoration(
                  color: ComicTheme.drawerBg,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Created Panels',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Drag onto the page',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDraggablePanel(
                        color: Colors.red,
                        label: 'Wide',
                        width: _canvasWidth - 2 * _pageMargin,
                        height: _canvasHeight * 0.2,
                      ),
                      SizedBox(height: 12),
                      _buildDraggablePanel(
                        color: Colors.teal,
                        label: 'Two Half',
                        width: (_canvasWidth - 2 * _pageMargin) / 2,
                        height: _canvasHeight * 0.2,
                      ),
                      SizedBox(height: 12),
                      _buildDraggablePanel(
                        color: Colors.green,
                        label: 'Tall',
                        width: _canvasWidth * 0.35,
                        height: _canvasHeight * 0.5,
                      ),
                      SizedBox(height: 12),
                      _buildDraggablePanel(
                        color: Colors.orange,
                        label: 'Square',
                        width: _canvasWidth * 0.4,
                        height: _canvasWidth * 0.4,
                      ),
                      SizedBox(height: 12),
                      _buildDraggablePanel(
                        color: Colors.purple,
                        label: 'Small',
                        width: _canvasWidth * 0.25,
                        height: _canvasHeight * 0.12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
