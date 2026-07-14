import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/inkwell_character.dart';
import '../services/inkwell_profile_service.dart';
import '../theme/comic_theme.dart';
import '../utils/project_metadata.dart';
import '../widgets/plot_assistant_step.dart';
import 'character_studio_screen.dart';

/// Four-step New Project flow: Foundations → Plot → Cast → Launch.
class NewProjectWizardScreen extends StatefulWidget {
  final String? initialTemplateId;
  final String? initialFormat;

  const NewProjectWizardScreen({
    super.key,
    this.initialTemplateId,
    this.initialFormat,
  });

  @override
  State<NewProjectWizardScreen> createState() => _NewProjectWizardScreenState();
}

class _NewProjectWizardScreenState extends State<NewProjectWizardScreen> {
  static const _stepLabels = ['Foundations', 'Plot', 'Cast', 'Launch'];

  int _step = 0;
  final _nameCtrl = TextEditingController(text: 'Untitled Adventure');
  String _genre = 'action';
  String _format = 'comic_book';
  final Set<String> _selectedCast = {};
  final _plotKey = GlobalKey<PlotAssistantStepState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialFormat != null) {
      _format = widget.initialFormat!;
    } else if (widget.initialTemplateId != null) {
      _format = _formatFromTemplate(widget.initialTemplateId!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _formatFromTemplate(String templateId) {
    switch (templateId) {
      case 'single_splash':
        return 'single_page';
      case 'webtoon':
        return 'webtoon';
      default:
        return 'comic_book';
    }
  }

  List<InkwellCharacter> get _castOptions {
    final saved = InkwellProfileService.characters;
    if (saved.isNotEmpty) return saved;
    return _sampleCast;
  }

  List<InkwellCharacter> get _filteredCast {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _castOptions;
    return _castOptions
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.role.toLowerCase().contains(q))
        .toList();
  }

  static List<InkwellCharacter> get _sampleCast => [
        InkwellCharacter(
          id: 'sample_lia',
          name: 'Lia K.',
          role: 'Protagonist',
          imageAsset: 'assets/characters/ic_women.png',
          updatedAt: DateTime.now(),
        ),
        InkwellCharacter(
          id: 'sample_v7',
          name: 'V-7',
          role: 'Sidekick',
          imageAsset: 'assets/characters/ic_engineer.png',
          updatedAt: DateTime.now(),
        ),
        InkwellCharacter(
          id: 'sample_kaito',
          name: 'Kaito',
          role: 'Rival',
          imageAsset: 'assets/characters/ic_boy.png',
          updatedAt: DateTime.now(),
        ),
      ];

  void _next() {
    if (_step == 0) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a project name')),
        );
        return;
      }
    }
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    _finish();
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  void _finish() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final plotScript = _plotKey.currentState?.script;
    final script =
        (plotScript != null && plotScript.trim().isNotEmpty) ? plotScript : null;

    Navigator.pop(
      context,
      NewProjectWizardResult(
        name: name,
        genre: _genre,
        format: _format,
        plotScript: script,
        castCharacterIds: _selectedCast.toList(),
        templateId: widget.initialTemplateId ??
            ProjectMetadata.templateIdForFormat(_format),
      ),
    );
  }

  Future<void> _openNewCharacter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CharacterStudioScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ComicTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ComicTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Project',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: ComicTheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _stepper(),
          Expanded(child: _stepBody()),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _stepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: List.generate(4, (i) {
          final active = i == _step;
          final done = i < _step;
          final color = active || done ? ComicTheme.primary : Colors.grey.shade300;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= _step
                          ? ComicTheme.primary.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                    ),
                  ),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: active || done ? Colors.white : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(height: 4),
                      Text(
                        _stepLabels[i],
                        style: const TextStyle(
                          color: ComicTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < _step
                          ? ComicTheme.primary.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _foundationsStep();
      case 1:
        return PlotAssistantStep(key: _plotKey);
      case 2:
        return _castStep();
      case 3:
        return _launchStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _foundationsStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Begin your story',
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Define the foundations of your next masterpiece.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.35),
        ),
        const SizedBox(height: 24),
        const Text('Project Name',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            hintText: 'Untitled Adventure',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Genre', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _genreChip('action', Icons.bolt, 'Action'),
            _genreChip('slice_of_life', Icons.coffee, 'Slice of Life'),
            _genreChip('sci_fi', Icons.rocket_launch, 'Sci-Fi'),
            _genreChip('fantasy', Icons.auto_awesome, 'Fantasy'),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Format', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _formatTile(
          'single_page',
          Icons.article_outlined,
          'Single Page',
          'Posters, covers, or one-shots',
        ),
        _formatTile(
          'webtoon',
          Icons.smartphone_outlined,
          'Webtoon',
          'Vertical scroll optimized layout',
        ),
        _formatTile(
          'comic_book',
          Icons.menu_book_outlined,
          'Comic Book',
          'Traditional 24-page spread format',
        ),
      ],
    );
  }

  Widget _genreChip(String id, IconData icon, String label) {
    final selected = _genre == id;
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _genre = id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: ComicTheme.primary, width: 2)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: ComicTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatTile(String id, IconData icon, String title, String subtitle) {
    final selected = _format == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _format = id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: ComicTheme.primary, width: 2)
                  : null,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ComicTheme.inkwellLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: ComicTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _castStep() {
    final cast = _filteredCast;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Populate Your Story',
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Select existing characters from your Studio to cast them in this new project. You can always add more later.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.35),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search your characters...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: cast.length + 1,
          itemBuilder: (context, i) {
            if (i == cast.length) return _newCharacterCard();
            return _characterCard(cast[i]);
          },
        ),
      ],
    );
  }

  Widget _characterCard(InkwellCharacter character) {
    final selected = _selectedCast.contains(character.id);
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _selectedCast.remove(character.id);
            } else {
              _selectedCast.add(character.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? ComicTheme.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: selected
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: ComicTheme.primary,
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      )
                    : const SizedBox(height: 24),
              ),
              CircleAvatar(
                radius: 36,
                backgroundColor: ComicTheme.inkwellLight,
                backgroundImage: AssetImage(character.imageAsset),
              ),
              const SizedBox(height: 10),
              Text(character.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  character.role,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newCharacterCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openNewCharacter,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade400,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ComicTheme.inkwellLight,
                child: Icon(Icons.person_add, color: ComicTheme.primary),
              ),
              const SizedBox(height: 10),
              Text(
                'New Character',
                style: TextStyle(
                  color: ComicTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Create in Studio',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _launchStep() {
    final beatCount = _plotKey.currentState?.beats.length ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(
          "You're all set",
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your choices, then open the editor to start drawing.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.35),
        ),
        const SizedBox(height: 24),
        _summaryTile('Project', _nameCtrl.text.trim()),
        _summaryTile('Genre', _genreLabel(_genre)),
        _summaryTile('Format', _formatLabel(_format)),
        _summaryTile('Story beats', beatCount > 0 ? '$beatCount beats' : 'None yet'),
        _summaryTile(
          'Cast',
          _selectedCast.isEmpty
              ? 'No characters selected'
              : '${_selectedCast.length} selected',
        ),
      ],
    );
  }

  String _genreLabel(String id) {
    switch (id) {
      case 'slice_of_life':
        return 'Slice of Life';
      case 'sci_fi':
        return 'Sci-Fi';
      case 'fantasy':
        return 'Fantasy';
      default:
        return 'Action';
    }
  }

  String _formatLabel(String id) {
    switch (id) {
      case 'single_page':
        return 'Single Page';
      case 'webtoon':
        return 'Webtoon';
      default:
        return 'Comic Book';
    }
  }

  Widget _summaryTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final isLast = _step == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0)
            TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back, color: ComicTheme.primary),
              label: const Text('Back', style: TextStyle(color: ComicTheme.primary)),
            )
          else
            const SizedBox(width: 8),
          const Spacer(),
          FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              backgroundColor: ComicTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isLast ? 'Create Project' : 'Next'),
                const SizedBox(width: 6),
                Icon(isLast ? Icons.check : Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
