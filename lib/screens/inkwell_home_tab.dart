import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../PanelModel/Project.dart';
import '../models/comic_template.dart';
import '../models/inkwell_character.dart';
import '../services/inkwell_profile_service.dart';
import '../services/app_settings.dart';
import '../theme/comic_theme.dart';
import '../utils/project_display_utils.dart';
import '../widgets/panel_content_preview.dart';
import '../widgets/template_canvas_preview.dart';

/// Inkwell Home — Continue Creating, action grid, cast, trending templates.
class InkwellHomeTab extends StatefulWidget {
  final List<Project> projects;
  final VoidCallback onOpenTemplates;
  final VoidCallback onNewProject;
  final VoidCallback onViewAllProjects;
  final VoidCallback onOpenCharacterStudio;
  final VoidCallback onOpenAssets;
  final VoidCallback onManageStudio;
  final VoidCallback? onImport;
  final void Function(String? templateId) onTemplateQuickStart;
  final void Function(Project) onOpenProject;

  const InkwellHomeTab({
    super.key,
    required this.projects,
    required this.onOpenTemplates,
    required this.onNewProject,
    required this.onViewAllProjects,
    required this.onOpenCharacterStudio,
    required this.onOpenAssets,
    required this.onManageStudio,
    required this.onTemplateQuickStart,
    required this.onOpenProject,
    this.onImport,
  });

  @override
  State<InkwellHomeTab> createState() => _InkwellHomeTabState();
}

class _InkwellHomeTabState extends State<InkwellHomeTab> {
  String _templateFilter = 'manga';
  late Set<String> _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = AppSettings.bookmarkedTemplateIds.toSet();
  }

  Future<void> _toggleBookmark(String id) async {
    setState(() {
      if (_bookmarked.contains(id)) {
        _bookmarked.remove(id);
      } else {
        _bookmarked.add(id);
      }
    });
    await AppSettings.setBookmarkedTemplateIds(_bookmarked.toList());
  }

  static const _trendingTemplates = [
    _TrendingTemplate(
      id: 'manga_page',
      title: 'Shonen Classic',
      subtitle: 'Standard Action Layout',
      categories: ['manga'],
    ),
    _TrendingTemplate(
      id: 'webtoon',
      title: 'Webtoon Scroll',
      subtitle: 'Optimized for Mobile',
      categories: ['webtoon'],
    ),
    _TrendingTemplate(
      id: 'grid_2x2',
      title: 'Dynamic Grid',
      subtitle: 'Western Superhero Style',
      categories: ['manga', 'comic'],
    ),
  ];

  List<InkwellCharacter> get _cast {
    final saved = InkwellProfileService.characters;
    if (saved.isNotEmpty) return saved.take(6).toList();
    return _sampleCast;
  }

  static List<InkwellCharacter> get _sampleCast => [
        InkwellCharacter(
          id: 'sample_lia',
          name: 'Lia K.',
          imageAsset: 'assets/characters/ic_women.png',
          updatedAt: DateTime.now(),
        ),
        InkwellCharacter(
          id: 'sample_v7',
          name: 'V-7',
          imageAsset: 'assets/characters/ic_engineer.png',
          updatedAt: DateTime.now(),
        ),
        InkwellCharacter(
          id: 'sample_kaito',
          name: 'Kaito',
          imageAsset: 'assets/characters/ic_boy.png',
          updatedAt: DateTime.now(),
        ),
      ];

  List<_TrendingTemplate> get _filteredTrending {
    return _trendingTemplates.where((t) {
      if (_templateFilter == 'webtoon') {
        return t.categories.contains('webtoon');
      }
      return t.categories.contains('manga') || t.categories.contains('comic');
    }).toList();
  }

  ComicTemplate? _templateById(String id) {
    for (final t in kComicTemplates) {
      if (t.id == id) return t;
    }
    return null;
  }

  int _progressPercent(Project project) {
    final pages = ProjectDisplayUtils.pageCount(project);
    final panels = project.pages.fold<int>(0, (sum, page) => sum + page.length);
    if (panels == 0) return 12;
    final score = (pages * 4 + panels * 2).clamp(1, 24);
    return ((score / 24) * 100).round().clamp(8, 95);
  }

  @override
  Widget build(BuildContext context) {
    final featured = widget.projects.isNotEmpty ? widget.projects.first : null;
    final trending = _filteredTrending;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _SectionHeader(
              title: 'Continue Creating',
              actionLabel: 'View All',
              onAction: widget.onViewAllProjects,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: featured != null
                ? _ContinueCard(
                    project: featured,
                    progress: _progressPercent(featured),
                    onResume: () => widget.onOpenProject(featured),
                  )
                : _EmptyContinueCard(onStart: widget.onNewProject),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _ActionTile(
                  icon: Icons.add_box_outlined,
                  label: 'New Comic',
                  color: ComicTheme.primary,
                  bg: ComicTheme.inkwellLight,
                  onTap: widget.onNewProject,
                ),
                _ActionTile(
                  icon: Icons.face_retouching_natural_outlined,
                  label: 'Character Studio',
                  color: const Color(0xFFE91E63),
                  bg: const Color(0xFFFCE4EC),
                  onTap: widget.onOpenCharacterStudio,
                ),
                _ActionTile(
                  icon: Icons.dashboard_outlined,
                  label: 'Templates',
                  color: const Color(0xFFF9A825),
                  bg: const Color(0xFFFFF8E1),
                  onTap: widget.onOpenTemplates,
                ),
                _ActionTile(
                  icon: Icons.upload_file_outlined,
                  label: 'Import',
                  color: const Color(0xFF7E57C2),
                  bg: const Color(0xFFEDE7F6),
                  onTap: widget.onImport ?? widget.onNewProject,
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(
              title: 'Your Cast',
              actionLabel: 'Manage Studio >',
              onAction: widget.onManageStudio,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 108,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              scrollDirection: Axis.horizontal,
              itemCount: _cast.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) => _CastAvatar(
                character: _cast[i],
                onTap: widget.onOpenCharacterStudio,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Trending Templates',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Manga',
                  selected: _templateFilter == 'manga',
                  onTap: () => setState(() => _templateFilter = 'manga'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Webtoon',
                  selected: _templateFilter == 'webtoon',
                  onTap: () => setState(() => _templateFilter = 'webtoon'),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList.separated(
            itemCount: trending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = trending[i];
              final template = _templateById(item.id);
              if (template == null) return const SizedBox.shrink();
              return _TrendingTemplateCard(
                template: template,
                title: item.title,
                subtitle: item.subtitle,
                bookmarked: _bookmarked.contains(item.id),
                onBookmark: () => _toggleBookmark(item.id),
                onTap: () => widget.onTemplateQuickStart(item.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingTemplate {
  final String id;
  final String title;
  final String subtitle;
  final List<String> categories;

  const _TrendingTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categories,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: ComicTheme.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Project project;
  final int progress;
  final VoidCallback onResume;

  const _ContinueCard({
    required this.project,
    required this.progress,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final chapter = ProjectDisplayUtils.pageCount(project);
    final chapterLabel =
        'CHAPTER ${chapter.toString().padLeft(2, '0')}: ${project.name.toUpperCase()}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: _ProjectHero(project: project),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ComicTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    chapterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      '$progress% Complete',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Resume Drawing'),
              style: FilledButton.styleFrom(
                backgroundColor: ComicTheme.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContinueCard extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyContinueCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF006064)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ComicTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'START YOUR STORY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Your next masterpiece\nawaits',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Creating'),
              style: FilledButton.styleFrom(
                backgroundColor: ComicTheme.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CastAvatar extends StatelessWidget {
  final InkwellCharacter character;
  final VoidCallback? onTap;

  const _CastAvatar({required this.character, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: ComicTheme.inkwellLight,
              backgroundImage: AssetImage(character.imageAsset),
              onBackgroundImageError: (_, __) {},
              child: character.imageAsset.isEmpty
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              character.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ComicTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingTemplateCard extends StatelessWidget {
  final ComicTemplate template;
  final String title;
  final String subtitle;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  const _TrendingTemplateCard({
    required this.template,
    required this.title,
    required this.subtitle,
    required this.bookmarked,
    required this.onBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  height: 72,
                  child: TemplateCanvasPreview(
                    templateId: template.id,
                    accentColor: template.color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onBookmark,
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: bookmarked ? ComicTheme.primary : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  final Project project;

  const _ProjectHero({required this.project});

  @override
  Widget build(BuildContext context) {
    if (project.pages.isEmpty || project.pages.first.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF00695C)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.auto_stories_outlined,
              size: 48, color: Colors.white54),
        ),
      );
    }
    final panel = project.pages.first.first;
    return FittedBox(
      fit: BoxFit.cover,
      child: PanelContentPreview(
        panel: panel,
        width: panel.width,
        height: panel.height,
      ),
    );
  }
}
