import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../PanelModel/Project.dart';
import '../theme/comic_theme.dart';
import '../utils/project_display_utils.dart';
import '../widgets/panel_content_preview.dart';

/// Projects tab — "Your Projects" with featured, grid, and list cards.
class InkwellProjectsTab extends StatelessWidget {
  final List<Project> projects;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNewProject;
  final void Function(Project) onOpen;
  final void Function(Project) onMenu;

  const InkwellProjectsTab({
    super.key,
    required this.projects,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onNewProject,
    required this.onOpen,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _EmptyProjects(onBrowse: onNewProject);
    }

    final featured = projects.first;
    final grid = projects.length > 1
        ? projects.sublist(1, projects.length > 3 ? 3 : projects.length)
        : <Project>[];
    final list = projects.length > 3 ? projects.sublist(3) : <Project>[];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Projects',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${projects.length} active comic canvas${projects.length == 1 ? '' : 'es'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      color: ComicTheme.primary,
                      onPressed: () => _showSortSheet(context),
                    ),
                  ],
                ),
              ),
            ),
            if (searchQuery.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    autofocus: true,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search projects…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _FeaturedProjectCard(
                  project: featured,
                  onTap: () => onOpen(featured),
                  onMenu: () => onMenu(featured),
                ),
              ),
            ),
            if (grid.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (var i = 0; i < grid.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _GridProjectCard(
                            project: grid[i],
                            onTap: () => onOpen(grid[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (list.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ListProjectCard(
                    project: list[i],
                    onTap: () => onOpen(list[i]),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 16,
          child: FilledButton.icon(
            onPressed: onNewProject,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New Project'),
            style: FilledButton.styleFrom(
              backgroundColor: ComicTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Sort by last edited')),
            const ListTile(title: Text('Sort by name')),
            const ListTile(title: Text('Sort by date created')),
            const SizedBox(height: 8),
            Text(
              'Change default in Profile → Settings',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptyProjects({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'No projects yet',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + New Project or browse Templates to start.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBrowse,
              style: FilledButton.styleFrom(
                backgroundColor: ComicTheme.primary,
              ),
              child: const Text('+ New Project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  const _FeaturedProjectCard({
    required this.project,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final status = ProjectDisplayUtils.statusLabel(project);
    final (bg, fg) = ProjectDisplayUtils.statusColors(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  child: _ProjectCover(project: project),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              ProjectDisplayUtils.timeAgo(project.lastModified),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.menu_book_outlined,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${ProjectDisplayUtils.pageCount(project)} Pages',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: onMenu,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _GridProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = ProjectDisplayUtils.statusLabel(project);
    final (bg, fg) = ProjectDisplayUtils.statusColors(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(height: 120, child: _ProjectCover(project: project)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: fg,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ProjectDisplayUtils.timeAgo(project.lastModified),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ListProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: _ProjectCover(project: project),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ProjectDisplayUtils.timeAgo(project.lastModified),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        ProjectDisplayUtils.pageCount(project).clamp(1, 5),
                        (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? ComicTheme.primary
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCover extends StatelessWidget {
  final Project project;

  const _ProjectCover({required this.project});

  @override
  Widget build(BuildContext context) {
    if (project.pages.isEmpty || project.pages.first.isEmpty) {
      return Container(
        color: ComicTheme.inkwellLight,
        child: const Center(
          child: Icon(Icons.auto_stories_outlined,
              size: 40, color: ComicTheme.primary),
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
