import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../PanelModel/Project.dart';
import '../PreviewPdf/PDFPageFormat.dart';
import '../TextEditorDialog/TextEditDialog.dart';
import '../services/app_settings.dart';
import '../utils/edit_history.dart';
import '../utils/project_clone.dart';
import '../utils/story_editor_service.dart';
import '../utils/story_text_meta.dart';
import '../widgets/story_apply_style_sheet.dart';
import '../widgets/story_find_replace_sheet.dart';
import '../widgets/story_text_widget.dart';

/// Mobile story editor — script-first storyboarding (Clip Studio workflow).
class StoryEditorScreen extends StatefulWidget {
  final Project project;
  final String pageFormat;
  final String? initialScript;

  const StoryEditorScreen({
    super.key,
    required this.project,
    this.pageFormat = 'A4',
    this.initialScript,
  });

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  late Project _project;
  late List<List<LayoutPanel>> _pages;
  final _history = EditHistory<List<List<LayoutPanel>>>();

  int _currentPage = 0;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  String? _rangeAnchorId;
  bool _rangeSelectActive = false;
  StoryListItem? _searchHighlight;

  bool get _createAsBubble => AppSettings.storyCreateAsBubble;
  StoryTextDirection get _textDirection => AppSettings.storyTextDirection;
  StoryTextDirection get _displayDirection => AppSettings.storyDisplayDirection;

  Size get _pageSize =>
      PDFPageFormat.formats[widget.pageFormat] ?? PDFPageFormat.formats['A4']!;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _pages = ProjectClone.clonePages(widget.project.pages);
    if (_pages.isEmpty) _pages = [[]];
    _history.push(ProjectClone.clonePages(_pages));
    if (widget.initialScript != null && widget.initialScript!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pasteInitialScript());
    }
  }

  Future<void> _pasteInitialScript() async {
    final next = await StoryEditorService.pasteScript(
      pages: _pages,
      pageIndex: _currentPage,
      rawText: widget.initialScript!,
      canvasWidth: _pageSize.width,
      canvasHeight: _pageSize.height,
      createAsBubble: _createAsBubble,
      direction: _textDirection,
      fontFamily: AppSettings.storyDefaultFont,
      fontSize: AppSettings.storyDefaultFontSize,
    );
    _commit(next);
  }

  void _commit(List<List<LayoutPanel>> next) {
    _history.push(ProjectClone.clonePages(_pages));
    setState(() {
      _pages = next;
      _project = _project.copyWith(
        pages: ProjectClone.clonePages(next),
        lastModified: DateTime.now(),
      );
    });
  }

  void _undo() {
    final prev = _history.undo(ProjectClone.clonePages(_pages));
    if (prev == null) return;
    setState(() {
      _pages = prev;
      _currentPage = _currentPage.clamp(0, _pages.length - 1);
      _project = _project.copyWith(pages: ProjectClone.clonePages(prev));
    });
  }

  List<StoryListItem> get _pageItems =>
      StoryEditorService.itemsOnPage(_pages, _currentPage);

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
      return;
    }
    final next = await StoryEditorService.pasteScript(
      pages: _pages,
      pageIndex: _currentPage,
      rawText: text,
      canvasWidth: _pageSize.width,
      canvasHeight: _pageSize.height,
      createAsBubble: _createAsBubble,
      direction: _textDirection,
      fontFamily: AppSettings.storyDefaultFont,
      fontSize: AppSettings.storyDefaultFontSize,
    );
    _commit(next);
  }

  Future<void> _addNewText() async {
    final next = await StoryEditorService.addBlankText(
      pages: _pages,
      pageIndex: _currentPage,
      canvasWidth: _pageSize.width,
      canvasHeight: _pageSize.height,
      createAsBubble: _createAsBubble,
      direction: _textDirection,
      fontFamily: AppSettings.storyDefaultFont,
      fontSize: AppSettings.storyDefaultFontSize,
    );
    _commit(next);
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIds.clear();
        _rangeSelectActive = false;
        _rangeAnchorId = null;
      }
    });
  }

  void _selectAllOnPage() {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..addAll(_pageItems.map((i) => i.ref.elementId));
    });
  }

  void _onItemTap(StoryListItem item) {
    if (_rangeSelectActive && _rangeAnchorId != null) {
      final ids = _pageItems.map((i) => i.ref.elementId).toList();
      final a = ids.indexOf(_rangeAnchorId!);
      final b = ids.indexOf(item.ref.elementId);
      if (a >= 0 && b >= 0) {
        final lo = a < b ? a : b;
        final hi = a < b ? b : a;
        setState(() {
          _selectionMode = true;
          _selectedIds.addAll(ids.sublist(lo, hi + 1));
          _rangeSelectActive = false;
        });
      }
      return;
    }

    if (_selectionMode) {
      setState(() {
        if (_selectedIds.contains(item.ref.elementId)) {
          _selectedIds.remove(item.ref.elementId);
        } else {
          _selectedIds.add(item.ref.elementId);
        }
      });
      return;
    }

    _editItem(item);
  }

  void _onItemLongPress(StoryListItem item) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(item.ref.elementId);
    });
  }

  Future<void> _editItem(StoryListItem item) async {
    final element = item.element;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TextEditDialog(
        initialText: StoryTextMeta.textContent(element),
        initialFontSize: element.fontSize ??
            element.speechBubbleData?.fontSize ??
            AppSettings.storyDefaultFontSize,
        initialColor: element.color ??
            element.speechBubbleData?.textColor ??
            Colors.black,
        initialFontFamily: element.fontFamily ??
            element.speechBubbleData?.fontFamily ??
            AppSettings.storyDefaultFont,
        initialFontWeight: element.fontWeight ??
            element.speechBubbleData?.fontWeight ??
            FontWeight.normal,
        initialFontStyle: element.fontStyle ??
            element.speechBubbleData?.fontStyle ??
            FontStyle.normal,
      ),
    );
    if (result == null) return;

    var next = StoryEditorService.updateText(
      _pages,
      item.ref,
      result['text'] as String,
    );
    next = StoryEditorService.applyStyle(
      next,
      {item.ref.elementId},
      StoryTextStyle(
        fontFamily: result['fontFamily'] as String?,
        fontSize: result['fontSize'] as double?,
        color: result['color'] as Color?,
        fontWeight: result['fontWeight'] as FontWeight?,
        fontStyle: result['fontStyle'] as FontStyle?,
      ),
    );
    _commit(next);
  }

  void _deleteSelected() {
    if (_selectedIds.isEmpty) return;
    _commit(StoryEditorService.deleteRefs(_pages, _selectedIds));
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  Future<void> _applyStyleToSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select text boxes first')),
      );
      return;
    }
    final result = await StoryApplyStyleSheet.show(
      context,
      selectionCount: _selectedIds.length,
    );
    if (result == null || !result.hasChanges) return;
    _commit(
      StoryEditorService.applyStyle(
        _pages,
        _selectedIds,
        StoryTextStyle(
          fontFamily: result.fontFamily,
          fontSize: result.fontSize,
          color: result.color,
          fontWeight: result.fontWeight,
          fontStyle: result.fontStyle,
          direction: result.direction,
          lineHeight: result.lineHeight,
        ),
      ),
    );
  }

  Future<void> _openFindReplace() async {
    final action = await StoryFindReplaceSheet.show(
      context,
      startFrom: _searchHighlight,
    );
    if (action == null || action.search.isEmpty) return;

    if (action.mode == StoryReplaceMode.replaceAll) {
      _commit(StoryEditorService.replaceAll(
        _pages,
        action.search,
        action.replacement,
      ));
      setState(() => _searchHighlight = null);
      return;
    }

    final matches = StoryEditorService.searchFrom(
      _pages,
      action.search,
      startPage: _currentPage,
      startElementId: _searchHighlight?.ref.elementId,
      forward: action.forward,
    );

    if (matches.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matches found')),
      );
      return;
    }

    final match = matches.first;
    if (action.mode == StoryReplaceMode.searchOnly) {
      setState(() {
        _searchHighlight = match;
        _currentPage = match.ref.pageIndex;
      });
      return;
    }

    var next = StoryEditorService.replaceInElement(
      _pages,
      match.ref,
      action.search,
      action.replacement,
    );
    _commit(next);
    setState(() => _searchHighlight = match);
  }

  Future<void> _moveItemToPage(StoryListItem item) async {
    final target = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Move to page')),
              for (var i = 0; i < _pages.length; i++)
                ListTile(
                  leading: Text('${i + 1}'),
                  title: Text('Page ${i + 1}'),
                  onTap: () => Navigator.pop(ctx, i),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New page'),
                onTap: () => Navigator.pop(ctx, _pages.length),
              ),
            ],
          ),
        );
      },
    );
    if (target == null) return;

    var pages = _pages;
    if (target >= pages.length) {
      pages = StoryEditorService.addPage(pages);
    }
    final next = StoryEditorService.moveElementToPage(
      pages,
      item.ref,
      target,
      _pageSize.width,
      _pageSize.height,
      10,
    );
    _commit(next);
    setState(() => _currentPage = target);
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _StoryEditorSettingsSheet(
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _finish() {
    Navigator.pop(
      context,
      _project.copyWith(
        pages: ProjectClone.clonePages(_pages),
        lastModified: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _pageItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _history.canUndo ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettings,
            tooltip: 'Story settings',
          ),
          TextButton(onPressed: _finish, child: const Text('Done')),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          if (_selectionMode)
            Material(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Text('${_selectedIds.length} selected'),
                    const Spacer(),
                    TextButton(
                      onPressed: _selectAllOnPage,
                      child: const Text('All on page'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _rangeSelectActive = true;
                        _rangeAnchorId = _selectedIds.isNotEmpty
                            ? _selectedIds.first
                            : null;
                      }),
                      child: const Text('Range'),
                    ),
                    if (_selectedIds.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _deleteSelected,
                        tooltip: 'Delete',
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No text on this page.\nPaste your script or tap New text.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      _commit(StoryEditorService.reorderOnPage(
                        _pages,
                        _currentPage,
                        oldIndex,
                        newIndex,
                      ));
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = _selectedIds.contains(item.ref.elementId);
                      final highlighted =
                          _searchHighlight?.ref.elementId == item.ref.elementId;
                      return _StoryTextTile(
                        key: ValueKey(item.ref.elementId),
                        listIndex: index,
                        item: item,
                        selected: selected,
                        highlighted: highlighted,
                        displayDirection: _displayDirection,
                        onTap: () => _onItemTap(item),
                        onLongPress: () => _onItemLongPress(item),
                        onMovePage: () => _moveItemToPage(item),
                        onDelete: () {
                          _commit(StoryEditorService.deleteRefs(
                            _pages,
                            {item.ref.elementId},
                          ));
                        },
                      );
                    },
                  ),
          ),
          _buildPageStrip(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Material(
      elevation: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _toolChip(Icons.content_paste, 'Paste', _pasteFromClipboard),
            _toolChip(Icons.post_add_outlined, 'New', _addNewText),
            _toolChip(Icons.search, 'Find', _openFindReplace),
            _toolChip(
              Icons.checklist,
              _selectionMode ? 'Selecting' : 'Select',
              _toggleSelectionMode,
              active: _selectionMode,
            ),
            _toolChip(Icons.format_paint_outlined, 'Style', _applyStyleToSelected),
            _toolChip(Icons.note_add_outlined, 'Page', () {
              _commit(StoryEditorService.addPage(_pages));
              setState(() => _currentPage = _pages.length - 1);
            }),
          ],
        ),
      ),
    );
  }

  Widget _toolChip(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: active,
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildPageStrip() {
    return Material(
      elevation: 4,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final selected = index == _currentPage;
              final count = StoryEditorService.itemsOnPage(_pages, index).length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('P${index + 1}${count > 0 ? ' ($count)' : ''}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _currentPage = index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StoryTextTile extends StatelessWidget {
  final int listIndex;
  final StoryListItem item;
  final bool selected;
  final bool highlighted;
  final StoryTextDirection displayDirection;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMovePage;
  final VoidCallback onDelete;

  const _StoryTextTile({
    super.key,
    required this.listIndex,
    required this.item,
    required this.selected,
    required this.highlighted,
    required this.displayDirection,
    required this.onTap,
    required this.onLongPress,
    required this.onMovePage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Colors.blue
        : highlighted
            ? Colors.orange
            : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: listIndex,
                child: const Padding(
                  padding: EdgeInsets.only(top: 8, right: 8),
                  child: Icon(Icons.drag_handle, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.element.type == 'speech_bubble')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Speech bubble',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    StoryTextWidget.fromElement(
                      item.element,
                      maxLines: 4,
                      textAlign: TextAlign.start,
                      directionOverride: displayDirection,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'move') onMovePage();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'move', child: Text('Move to page…')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryEditorSettingsSheet extends StatefulWidget {
  final VoidCallback onChanged;

  const _StoryEditorSettingsSheet({required this.onChanged});

  @override
  State<_StoryEditorSettingsSheet> createState() =>
      _StoryEditorSettingsSheetState();
}

class _StoryEditorSettingsSheetState extends State<_StoryEditorSettingsSheet> {
  late StoryTextDirection _display;
  late StoryTextDirection _defaultText;
  late bool _asBubble;
  late String _font;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _display = AppSettings.storyDisplayDirection;
    _defaultText = AppSettings.storyTextDirection;
    _asBubble = AppSettings.storyCreateAsBubble;
    _font = AppSettings.storyDefaultFont;
    _fontSize = AppSettings.storyDefaultFontSize;
  }

  Future<void> _save() async {
    await AppSettings.setStoryDisplayDirection(_display);
    await AppSettings.setStoryTextDirection(_defaultText);
    await AppSettings.setStoryCreateAsBubble(_asBubble);
    await AppSettings.setStoryDefaultFont(_font);
    await AppSettings.setStoryDefaultFontSize(_fontSize);
    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Story editor settings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('List display direction'),
              subtitle: SegmentedButton<StoryTextDirection>(
                segments: const [
                  ButtonSegment(
                    value: StoryTextDirection.horizontal,
                    label: Text('Horizontal'),
                  ),
                  ButtonSegment(
                    value: StoryTextDirection.vertical,
                    label: Text('Vertical'),
                  ),
                ],
                selected: {_display},
                onSelectionChanged: (s) =>
                    setState(() => _display = s.first),
              ),
            ),
            ListTile(
              title: const Text('New text direction'),
              subtitle: SegmentedButton<StoryTextDirection>(
                segments: const [
                  ButtonSegment(
                    value: StoryTextDirection.horizontal,
                    label: Text('Horizontal'),
                  ),
                  ButtonSegment(
                    value: StoryTextDirection.vertical,
                    label: Text('Vertical'),
                  ),
                ],
                selected: {_defaultText},
                onSelectionChanged: (s) =>
                    setState(() => _defaultText = s.first),
              ),
            ),
            SwitchListTile(
              title: const Text('Create as speech bubble'),
              subtitle: const Text('New lines become bubbles instead of plain text'),
              value: _asBubble,
              onChanged: (v) => setState(() => _asBubble = v),
            ),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
