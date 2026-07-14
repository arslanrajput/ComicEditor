import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/comic_template.dart';
import '../theme/comic_theme.dart';
import '../widgets/template_canvas_preview.dart';

/// "Choose Your Canvas" — template browser matching Inkwell design.
class TemplatesCanvasScreen extends StatefulWidget {
  final ValueChanged<String?> onTemplateSelected;

  const TemplatesCanvasScreen({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  State<TemplatesCanvasScreen> createState() => _TemplatesCanvasScreenState();
}

class _TemplatesCanvasScreenState extends State<TemplatesCanvasScreen> {
  String _category = 'all';
  String _searchQuery = '';

  List<ComicTemplate> get _filtered {
    var list = kComicTemplates.where((t) => !t.isBlank);

    if (_category != 'all') {
      list = list.where((t) => t.category == _category);
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        final title = canvasDisplayTitle(t).toLowerCase();
        return title.contains(q) ||
            t.description.toLowerCase().contains(q) ||
            canvasDisplayTag(t).toLowerCase().contains(q) ||
            t.categoryLabel.toLowerCase().contains(q);
      });
    }

    return sortCanvasTemplates(
      list,
      featuredFirst: _category == 'all' && _searchQuery.isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = _filtered;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Canvas',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse our curated collection of professional layouts to jumpstart your next masterpiece.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search layouts, styles, or themes...',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'All Templates',
                        selected: _category == 'all',
                        onTap: () => setState(() => _category = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Manga',
                        selected: _category == 'manga',
                        onTap: () => setState(() => _category = 'manga'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Webtoon',
                        selected: _category == 'webtoon',
                        onTap: () => setState(() => _category = 'webtoon'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (templates.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No layouts match your search')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList.separated(
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _TemplateCanvasCard(
                template: templates[i],
                onUse: () => widget.onTemplateSelected(templates[i].id),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ComicTheme.primary : ComicTheme.inkwellLight,
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
              color: selected ? Colors.white : ComicTheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCanvasCard extends StatelessWidget {
  final ComicTemplate template;
  final VoidCallback onUse;

  const _TemplateCanvasCard({
    required this.template,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final title = canvasDisplayTitle(template);
    final tag = canvasDisplayTag(template);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onUse,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: TemplateCanvasPreview(
                  templateId: template.id,
                  accentColor: template.color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ComicTheme.inkwellLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ComicTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.grey.shade100,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onUse,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.add, color: Colors.black54, size: 22),
                      ),
                    ),
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
