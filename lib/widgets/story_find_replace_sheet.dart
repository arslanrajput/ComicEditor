import 'package:flutter/material.dart';

import '../utils/story_editor_service.dart';

enum StoryReplaceMode { searchOnly, replaceOne, replaceAll }

/// Find / replace dialog for story text (mobile equivalent of Clip Studio search).
class StoryFindReplaceSheet extends StatefulWidget {
  final StoryListItem? startFrom;

  const StoryFindReplaceSheet({super.key, this.startFrom});

  static Future<StoryFindReplaceAction?> show(
    BuildContext context, {
    StoryListItem? startFrom,
  }) {
    return showModalBottomSheet<StoryFindReplaceAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StoryFindReplaceSheet(startFrom: startFrom),
    );
  }

  @override
  State<StoryFindReplaceSheet> createState() => _StoryFindReplaceSheetState();
}

class StoryFindReplaceAction {
  final StoryReplaceMode mode;
  final String search;
  final String replacement;
  final bool forward;

  const StoryFindReplaceAction({
    required this.mode,
    required this.search,
    required this.replacement,
    this.forward = true,
  });
}

class _StoryFindReplaceSheetState extends State<StoryFindReplaceSheet> {
  final _searchCtrl = TextEditingController();
  final _replaceCtrl = TextEditingController();
  bool _forward = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  void _submit(StoryReplaceMode mode) {
    final search = _searchCtrl.text;
    if (search.isEmpty) return;
    Navigator.pop(
      context,
      StoryFindReplaceAction(
        mode: mode,
        search: search,
        replacement: _replaceCtrl.text,
        forward: _forward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Search & replace',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search string',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _replaceCtrl,
            decoration: const InputDecoration(
              labelText: 'Replacement string',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Forward')),
              ButtonSegment(value: false, label: Text('Backward')),
            ],
            selected: {_forward},
            onSelectionChanged: (s) => setState(() => _forward = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submit(StoryReplaceMode.searchOnly),
                  child: const Text('Search'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submit(StoryReplaceMode.replaceOne),
                  child: const Text('Replace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _submit(StoryReplaceMode.replaceAll),
            child: const Text('Replace all'),
          ),
          const SizedBox(height: 4),
          Text(
            'Replace all updates every text box that contains the search string.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
