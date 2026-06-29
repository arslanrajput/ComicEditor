import 'package:flutter/material.dart';

import '../PreviewPdf/PDFPageFormat.dart';
import '../services/app_settings.dart';

/// App-wide settings for Comic Creator.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _pageFormat;
  late bool _showGrid;
  late bool _snapToGrid;
  late double _exportQuality;
  late String _readingDirection;
  late bool _webtoonMode;
  late String _sortOrder;

  @override
  void initState() {
    super.initState();
    _pageFormat = AppSettings.defaultPageFormat;
    _showGrid = AppSettings.defaultShowGrid;
    _snapToGrid = AppSettings.defaultSnapToGrid;
    _exportQuality = AppSettings.exportPixelRatio;
    _readingDirection = AppSettings.readingDirection;
    _webtoonMode = AppSettings.webtoonReaderMode;
    _sortOrder = AppSettings.projectSortOrder;
  }

  Future<void> _save() async {
    await AppSettings.setDefaultPageFormat(_pageFormat);
    await AppSettings.setDefaultShowGrid(_showGrid);
    await AppSettings.setDefaultSnapToGrid(_snapToGrid);
    await AppSettings.setExportPixelRatio(_exportQuality);
    await AppSettings.setReadingDirection(_readingDirection);
    await AppSettings.setWebtoonReaderMode(_webtoonMode);
    await AppSettings.setProjectSortOrder(_sortOrder);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        children: [
          const _SectionHeader('New projects'),
          ListTile(
            title: const Text('Default page size'),
            subtitle: Text(_pageFormat),
            trailing: DropdownButton<String>(
              value: _pageFormat,
              underline: const SizedBox.shrink(),
              items: PDFPageFormat.formats.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _pageFormat = v ?? 'A4'),
            ),
          ),
          SwitchListTile(
            title: const Text('Show grid by default'),
            value: _showGrid,
            onChanged: (v) => setState(() => _showGrid = v),
          ),
          SwitchListTile(
            title: const Text('Snap to grid'),
            subtitle: const Text('Align panels to grid in layout editor'),
            value: _snapToGrid,
            onChanged: (v) => setState(() => _snapToGrid = v),
          ),
          const _SectionHeader('Export'),
          ListTile(
            title: const Text('Export quality'),
            subtitle: Text('${_exportQuality.toStringAsFixed(1)}× pixel ratio'),
            trailing: SizedBox(
              width: 140,
              child: Slider(
                value: _exportQuality,
                min: 1.5,
                max: 4.0,
                divisions: 5,
                label: '${_exportQuality.toStringAsFixed(1)}×',
                onChanged: (v) => setState(() => _exportQuality = v),
              ),
            ),
          ),
          const _SectionHeader('Reader'),
          SwitchListTile(
            title: const Text('Webtoon scroll mode'),
            subtitle: const Text('Vertical scroll instead of page turns'),
            value: _webtoonMode,
            onChanged: (v) => setState(() => _webtoonMode = v),
          ),
          ListTile(
            title: const Text('Reading direction'),
            subtitle: Text(_readingDirection == 'rtl' ? 'Right to left (manga)' : 'Left to right'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ltr', label: Text('LTR')),
                ButtonSegment(value: 'rtl', label: Text('RTL')),
              ],
              selected: {_readingDirection},
              onSelectionChanged: (s) =>
                  setState(() => _readingDirection = s.first),
            ),
          ),
          const _SectionHeader('Projects list'),
          ListTile(
            title: const Text('Sort projects by'),
            trailing: DropdownButton<String>(
              value: _sortOrder,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'modified', child: Text('Last modified')),
                DropdownMenuItem(value: 'name', child: Text('Name A–Z')),
                DropdownMenuItem(value: 'created', child: Text('Date created')),
              ],
              onChanged: (v) => setState(() => _sortOrder = v ?? 'modified'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
