import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CharacterClipartPickerDialog extends StatefulWidget {
  const CharacterClipartPickerDialog({super.key});

  @override
  State<CharacterClipartPickerDialog> createState() =>
      _CharacterClipartPickerDialogState();
}

class _CharacterClipartPickerDialogState
    extends State<CharacterClipartPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  List<String> _characterAssets = [];
  List<String> _clipartAssets = [];
  bool _loading = true;

  static const _allCharacterAssets = [
    'assets/characters/ic_super_hero_1.png',
    'assets/characters/ic_engineer.png',
    'assets/characters/ic_super_hero.png',
    'assets/characters/ic_women.png',
    'assets/characters/ic_boy.png',
    'assets/characters/ic_super_hero_3.png',
  ];

  static const _allClipartAssets = [
    'assets/clipart/ic_strength.png',
    'assets/clipart/ic_thank_you.png',
    'assets/clipart/ic_super_power.png',
    'assets/clipart/ic_comic_book.png',
    'assets/clipart/ic_dog.png',
    'assets/clipart/ic_mr_blobby.png',
    'assets/clipart/ic_happy_face.png',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim().toLowerCase());
    });
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final chars = await _filterExisting(_allCharacterAssets);
    final clips = await _filterExisting(_allClipartAssets);
    if (mounted) {
      setState(() {
        _characterAssets = chars;
        _clipartAssets = clips;
        _loading = false;
      });
    }
  }

  Future<List<String>> _filterExisting(List<String> paths) async {
    final found = <String>[];
    for (final path in paths) {
      try {
        await rootBundle.load(path);
        found.add(path);
      } catch (_) {}
    }
    return found;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSvg(String path) => path.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Element'),
            const SizedBox(height: 10),
            _buildSearchField(),
            const SizedBox(height: 10),
            const TabBar(tabs: [
              Tab(text: 'Characters'),
              Tab(text: 'Clip-Art'),
            ]),
          ],
        ),
        content: SizedBox(
          width: 340,
          height: 440,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildAssetsGrid(
                      context,
                      _characterAssets.where(_filterBySearch).toList(),
                      type: 'character',
                      emptyHint:
                          'Character packs coming soon.\nUse Upload to add your own images.',
                    ),
                    _buildAssetsGrid(
                      context,
                      _clipartAssets.where(_filterBySearch).toList(),
                      type: 'clipart',
                      emptyHint:
                          'Clip-art packs coming soon.\nUse Upload to add stickers.',
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search…',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _filterBySearch(String path) {
    if (_searchText.isEmpty) return true;
    final fileName = path.split('/').last.toLowerCase();
    return fileName.contains(_searchText);
  }

  Widget _buildAssetsGrid(
    BuildContext context,
    List<String> assets, {
    required String type,
    required String emptyHint,
  }) {
    if (assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            emptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.4),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: assets.length,
      itemBuilder: (_, i) {
        final assetPath = assets[i];
        return GestureDetector(
          onTap: () =>
              Navigator.pop(context, {'type': type, 'value': assetPath}),
          child: _stickerContainer(_assetThumb(assetPath)),
        );
      },
    );
  }

  Widget _assetThumb(String assetPath) {
    if (_isSvg(assetPath)) {
      return SvgPicture.asset(assetPath, width: 36, height: 36);
    }
    return Image.asset(assetPath, width: 36, height: 36, fit: BoxFit.contain);
  }

  Widget _stickerContainer(Widget child) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: child,
    );
  }
}
