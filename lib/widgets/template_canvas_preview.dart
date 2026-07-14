import 'package:flutter/material.dart';

import '../models/comic_template.dart';
import 'template_layout_preview.dart';

/// PNG thumbnails for featured canvas templates (from design mockups).
const kTemplateThumbnailAssets = <String, String>{
  'manga_page': 'assets/templates/manga_page.png',
  'webtoon': 'assets/templates/webtoon.png',
  'single_splash': 'assets/templates/single_splash.png',
  'grid_2x2': 'assets/templates/grid_2x2.png',
  'comic_strip': 'assets/templates/grid_2x2.png',
};

String? templateThumbnailAsset(String templateId) =>
    kTemplateThumbnailAssets[templateId];

/// Template preview — real thumbnail image when available, else layout art.
class TemplateCanvasPreview extends StatelessWidget {
  final String templateId;
  final Color accentColor;

  const TemplateCanvasPreview({
    super.key,
    required this.templateId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final asset = templateThumbnailAsset(templateId);
    if (asset != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _fallbackPreview(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: TemplateLayoutPreview(
                templateId: templateId,
                accentColor: accentColor,
                width: double.infinity,
                height: double.infinity,
                showPageBorder: false,
              ),
            ),
          ),
        ],
      );
    }
    return _fallbackPreview();
  }

  Widget _fallbackPreview() {
    switch (templateId) {
      case 'manga_page':
        return _MangaShonenPreview(accent: accentColor);
      case 'webtoon':
        return _WebtoonScrollPreview(accent: accentColor);
      case 'single_splash':
        return _HeroJourneyPreview(accent: accentColor);
      case 'grid_2x2':
      case 'comic_strip':
        return _DailyStripPreview(accent: accentColor);
      default:
        return Container(
          color: accentColor.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(20),
          child: TemplateLayoutPreview(
            templateId: templateId,
            accentColor: accentColor,
            width: double.infinity,
            height: double.infinity,
            showPageBorder: true,
          ),
        );
    }
  }
}

class _MangaShonenPreview extends StatelessWidget {
  final Color accent;

  const _MangaShonenPreview({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(child: _bwPanel(radius: 4)),
                const SizedBox(height: 6),
                Expanded(child: _bwPanel(radius: 4)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(flex: 2, child: _bwPanel(radius: 4)),
                const SizedBox(height: 6),
                Expanded(child: _bwPanel(radius: 4)),
                const SizedBox(height: 6),
                Expanded(child: _bwPanel(radius: 4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bwPanel({required double radius}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              width: 28,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black54),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebtoonScrollPreview extends StatelessWidget {
  final Color accent;

  const _WebtoonScrollPreview({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81C784), Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          Expanded(child: _colorPanel(const Color(0xFF66BB6A))),
          const SizedBox(height: 5),
          Expanded(child: _colorPanel(const Color(0xFF43A047))),
          const SizedBox(height: 5),
          Expanded(child: _colorPanel(const Color(0xFF388E3C))),
        ],
      ),
    );
  }

  Widget _colorPanel(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _HeroJourneyPreview extends StatelessWidget {
  final Color accent;

  const _HeroJourneyPreview({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7043), Color(0xFFE53935), Color(0xFF1E88E5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 16,
            right: 40,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white38, width: 2),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 24,
            width: 56,
            height: 72,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black87, width: 2),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 14,
            child: Container(
              width: 48,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStripPreview extends StatelessWidget {
  final Color accent;

  const _DailyStripPreview({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFECEFF1),
      padding: const EdgeInsets.all(18),
      child: Center(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                4,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Featured templates shown first on the canvas screen (matches mockup).
const kCanvasFeaturedTemplateIds = [
  'manga_page',
  'webtoon',
  'single_splash',
  'grid_2x2',
];

String canvasDisplayTitle(ComicTemplate template) {
  if (template.id == 'grid_2x2') return 'Daily Strip';
  return template.title;
}

String canvasDisplayTag(ComicTemplate template) {
  switch (template.id) {
    case 'manga_page':
      return 'Manga • 6 Panels';
    case 'webtoon':
      return 'Webtoon • Vertical';
    case 'single_splash':
      return 'Superhero • Action';
    case 'grid_2x2':
      return 'Slice of Life • 4 Panels';
    case 'comic_strip':
      return 'Slice of Life • 4 Panels';
    default:
      if (template.category == 'webtoon') {
        return '${template.categoryLabel} • Vertical';
      }
      return '${template.categoryLabel} • ${template.panelCount} Panels';
  }
}

List<ComicTemplate> sortCanvasTemplates(
  Iterable<ComicTemplate> templates, {
  bool featuredFirst = true,
}) {
  final list = templates.where((t) => !t.isBlank).toList();
  if (!featuredFirst) return list;

  final featured = <ComicTemplate>[];
  for (final id in kCanvasFeaturedTemplateIds) {
    for (final t in list) {
      if (t.id == id) {
        featured.add(t);
        break;
      }
    }
  }
  final rest = list.where((t) => !kCanvasFeaturedTemplateIds.contains(t.id));
  return [...featured, ...rest];
}
