import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inkwell_character.dart';
import '../services/inkwell_profile_service.dart';
import '../theme/comic_theme.dart';
import '../widgets/inkwell_chrome.dart';

/// Character Studio — Create tab design with Details / traits / palette.
class CharacterStudioScreen extends StatefulWidget {
  final InkwellCharacter? existing;
  final bool embedded;

  const CharacterStudioScreen({
    super.key,
    this.existing,
    this.embedded = false,
  });

  @override
  State<CharacterStudioScreen> createState() => CharacterStudioScreenState();
}

class CharacterStudioScreenState extends State<CharacterStudioScreen> {
  static const _roles = [
    'Protagonist',
    'Antagonist',
    'Supporting',
    'Mentor',
  ];

  static const _assetOptions = [
    'assets/characters/ic_super_hero.png',
    'assets/characters/ic_super_hero_1.png',
    'assets/characters/ic_super_hero_3.png',
    'assets/characters/ic_women.png',
    'assets/characters/ic_boy.png',
    'assets/characters/ic_engineer.png',
  ];

  late TextEditingController _nameCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _bioCtrl;
  late String _role;
  late String _imageAsset;
  late List<String> _traits;
  int _tabIndex = 0;

  final _palette = const [
    Color(0xFF005696),
    Color(0xFFE91E63),
    Color(0xFF263238),
    Color(0xFFC9A227),
    Color(0xFFECEFF1),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? 'Kaelen Vox');
    _subtitleCtrl =
        TextEditingController(text: c?.subtitle ?? 'The Glitch Runner');
    _bioCtrl = TextEditingController(
      text: c?.bio ??
          'A street-smart runner who trades in stolen shadows and neon secrets.',
    );
    _role = c?.role ?? 'Protagonist';
    _imageAsset = c?.imageAsset ?? _assetOptions.first;
    _traits = List.from(c?.traits ??
        ['Agile', 'Tech-savvy', 'Sarcastic', 'Neural Link', 'Night Vision']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  /// Saves the current character. Callable from embedded app bar actions.
  Future<void> saveCharacter() => _save();

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a character name')),
      );
      return;
    }

    final id = widget.existing?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final character = InkwellCharacter(
      id: id,
      name: name,
      subtitle: _subtitleCtrl.text.trim(),
      role: _role,
      bio: _bioCtrl.text.trim(),
      traits: _traits,
      imageAsset: _imageAsset,
      paletteColors: _palette.map((c) => c.toARGB32()).toList(),
      updatedAt: DateTime.now(),
    );
    await InkwellProfileService.saveCharacter(character);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Character saved')),
    );
    if (!widget.embedded) {
      Navigator.pop(context, character);
    }
  }

  Future<void> _pickPortrait() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _imageAsset = picked.path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom portrait selected for this session'),
      ),
    );
  }

  void _showPortraitFullscreen() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: InteractiveViewer(
          child: _portraitImage(fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _portraitImage({BoxFit fit = BoxFit.cover}) {
    if (_imageAsset.startsWith('assets/')) {
      return Image.asset(
        _imageAsset,
        fit: fit,
        errorBuilder: (_, __, ___) => _portraitPlaceholder(),
      );
    }
    return Image.file(
      File(_imageAsset),
      fit: fit,
      errorBuilder: (_, __, ___) => _portraitPlaceholder(),
    );
  }

  Widget _portraitPlaceholder() {
    return Container(
      color: ComicTheme.inkwellLight,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 80),
    );
  }

  Future<void> _addTrait() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add trait'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      setState(() => _traits.add(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, widget.embedded ? 88 : 100),
            children: [
              _heroPreview(),
              const SizedBox(height: 16),
              _tabRow(),
              const SizedBox(height: 16),
              if (_tabIndex == 0) _detailsTab(),
              if (_tabIndex == 1) _galleryTab('Outfits'),
              if (_tabIndex == 2) _galleryTab('Faces'),
              if (_tabIndex == 3) _galleryTab('Gallery'),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _save,
              backgroundColor: ComicTheme.primary,
              icon: const Icon(Icons.save),
              label: const Text('Save Character'),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: ComicTheme.scaffoldBg,
      appBar: InkwellStudioAppBar(
        title: 'Character Studio',
        onBack: () => Navigator.maybePop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: ComicTheme.primary),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        backgroundColor: ComicTheme.primary,
        icon: const Icon(Icons.save),
        label: const Text('Save Character'),
      ),
    );
  }

  Widget _heroPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: _portraitImage(),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              _roundIcon(Icons.fullscreen, onTap: _showPortraitFullscreen),
              const SizedBox(width: 8),
              _roundIcon(Icons.photo_camera_outlined, onTap: _pickPortrait),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white.withValues(alpha: 0.88),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          _subtitleCtrl.text,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: _palette
                        .take(3)
                        .map(
                          (c) => Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundIcon(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: ComicTheme.primary),
        ),
      ),
    );
  }

  Widget _tabRow() {
    const tabs = ['Details', 'Outfits', 'Faces', 'Gallery'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? ComicTheme.inkwellLight : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => setState(() => _tabIndex = i),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? ComicTheme.primary : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _detailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('Character Name', _nameCtrl),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _role,
          decoration: _inputDeco('Primary Role'),
          items: _roles
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _role = v ?? _role),
        ),
        const SizedBox(height: 12),
        _field('Character Bio', _bioCtrl, maxLines: 4),
        const SizedBox(height: 16),
        _traitsCard(),
        const SizedBox(height: 16),
        _paletteCard(),
      ],
    );
  }

  Widget _galleryTab(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _assetOptions.length,
          itemBuilder: (context, i) {
            final asset = _assetOptions[i];
            final selected = asset == _imageAsset;
            return InkWell(
              onTap: () => setState(() => _imageAsset = asset),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? ComicTheme.primary : Colors.grey.shade300,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _traitsCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Traits & Powers',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, color: ComicTheme.primary)),
                IconButton(
                  icon: const Icon(Icons.add, color: ComicTheme.primary),
                  onPressed: _addTrait,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _traits
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: ComicTheme.inkwellLight,
                      labelStyle: const TextStyle(
                        color: ComicTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      onDeleted: () => setState(() => _traits.remove(t)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paletteCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Design Palette',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, color: ComicTheme.primary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _swatch(_palette[0], 'BLUE'),
                _swatch(_palette[1], 'ACCENT'),
                _swatch(_palette[2], 'DARK'),
                _swatch(_palette[3], 'GOLD'),
                _swatch(_palette[4], 'BASE'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: ComicTheme.inkwellLight.withValues(alpha: 0.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: _inputDeco(label),
    );
  }
}
