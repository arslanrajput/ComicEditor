import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_info.dart';
import '../PanelModel/Project.dart';
import '../models/inkwell_character.dart';
import '../screens/character_studio_screen.dart';
import '../screens/settings_screen.dart';
import '../services/inkwell_profile_service.dart';
import '../theme/comic_theme.dart';
import '../utils/project_display_utils.dart';
import '../utils/project_backup.dart';

/// Profile tab — avatar, stats, characters, published works, settings.
class InkwellProfileTab extends StatefulWidget {
  final List<Project> projects;
  final void Function(Project) onOpenProject;
  final VoidCallback onRefresh;

  const InkwellProfileTab({
    super.key,
    required this.projects,
    required this.onOpenProject,
    required this.onRefresh,
  });

  @override
  State<InkwellProfileTab> createState() => _InkwellProfileTabState();
}

class _InkwellProfileTabState extends State<InkwellProfileTab> {
  late String _name;
  late String _bio;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _name = InkwellProfileService.displayName;
    _bio = InkwellProfileService.bio;
  }

  Future<void> _pickAvatar() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await InkwellProfileService.setAvatarPath(picked.path);
    setState(() {});
    widget.onRefresh();
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await InkwellProfileService.setDisplayName(nameCtrl.text.trim());
    await InkwellProfileService.setBio(bioCtrl.text.trim());
    setState(_load);
    widget.onRefresh();
  }

  void _showWorksStats() {
    final pages = widget.projects.fold<int>(
      0,
      (sum, project) => sum + project.pages.length,
    );
    final panels = widget.projects.fold<int>(
      0,
      (sum, project) =>
          sum + project.pages.fold<int>(0, (pSum, page) => pSum + page.length),
    );
    final characters = InkwellProfileService.characters.length;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            _statsRow('Projects', '${widget.projects.length}'),
            _statsRow('Pages', '$pages'),
            _statsRow('Panels', '$panels'),
            _statsRow('Characters', '$characters'),
            const SizedBox(height: 8),
            Text(
              'All data is stored locally on this device.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final characters = InkwellProfileService.characters;
    final avatarPath = InkwellProfileService.avatarPath;
    final works = widget.projects.length;
    final creations = works + characters.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF005696)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      avatarPath != null ? FileImage(File(avatarPath)) : null,
                  child: avatarPath == null
                      ? Icon(Icons.person, size: 48, color: ComicTheme.primary)
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: ComicTheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _pickAvatar,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _bio.isEmpty
              ? 'Digital artist & storyteller. Tap edit to add your bio.'
              : _bio,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, height: 1.4),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatColumn(value: '$works', label: 'WORKS'),
            _divider(),
            _StatColumn(value: '$creations', label: 'CREATIONS'),
          ],
        ),
        const SizedBox(height: 28),
        _sectionHeader('My Characters', 'View All', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CharacterStudioScreen()),
          ).then((_) => setState(_load));
        }),
        const SizedBox(height: 12),
        if (characters.isEmpty)
          _emptyCharactersCard()
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: characters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _CharacterCard(character: characters[i]),
            ),
          ),
        const SizedBox(height: 28),
        _sectionHeader('Published Works', 'See Stats', _showWorksStats),
        const SizedBox(height: 12),
        if (widget.projects.isEmpty)
          Text('No published works yet.',
              style: TextStyle(color: Colors.grey.shade600))
        else
          ...widget.projects.take(4).map(_publishedTile),
        const SizedBox(height: 28),
        Text('Settings',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _settingsTile(Icons.person_outline, 'Account Information', _editProfile),
              _settingsTile(Icons.palette_outlined, 'Canvas Customization', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }),
              _settingsTile(
                Icons.info_outline,
                'Local storage',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '${AppInfo.appName} has no cloud account. Projects stay on this device.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Import backup'),
          onTap: () =>
              importProjectBackup(context).then((_) => widget.onRefresh()),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Export all projects'),
          onTap: exportAllProjectsBackup,
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.grey.shade300,
      );

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }

  Widget _emptyCharactersCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CharacterStudioScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          height: 160,
          child: Center(child: Text('Tap to create your first character')),
        ),
      ),
    );
  }

  Widget _publishedTile(Project project) {
    final genre = ProjectDisplayUtils.genreHint(project);
    final pages = ProjectDisplayUtils.pageCount(project);
    final completed = pages > 15;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: () => widget.onOpenProject(project),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: CircleAvatar(
            backgroundColor: ComicTheme.inkwellLight,
            child: Text(project.name.isNotEmpty ? project.name[0] : '?'),
          ),
          title: Text(project.name,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '$genre • $pages Chapters • ${completed ? 'Completed' : 'Updated ${ProjectDisplayUtils.timeAgo(project.lastModified).replaceFirst('Edited ', '')}'}',
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _settingsTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : ComicTheme.primary),
      title: Text(
        label,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ComicTheme.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final InkwellCharacter character;

  const _CharacterCard({required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.asset(
              character.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: ComicTheme.inkwellLight,
                child: const Icon(Icons.person, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              character.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
