import 'package:flutter/material.dart';

class ComicTemplate {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const ComicTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  bool get isBlank => id.isEmpty;
}

const kComicTemplates = [
  ComicTemplate(
    id: 'grid_2x2',
    title: '4-Panel Grid',
    description: 'Classic comic page',
    icon: Icons.grid_4x4,
    color: Color(0xFF7E57C2),
  ),
  ComicTemplate(
    id: 'manga_page',
    title: 'Manga Page',
    description: 'Big left + 2 stacked',
    icon: Icons.menu_book,
    color: Color(0xFFD81B60),
  ),
  ComicTemplate(
    id: 'webtoon',
    title: 'Webtoon Scroll',
    description: 'Tall vertical panels',
    icon: Icons.smartphone,
    color: Color(0xFF1E88E5),
  ),
  ComicTemplate(
    id: 'grid_3x2',
    title: '6-Panel Grid',
    description: '3 columns × 2 rows',
    icon: Icons.grid_on,
    color: Color(0xFF5E35B1),
  ),
  ComicTemplate(
    id: 'comic_strip',
    title: 'Comic Strip',
    description: '3 panels in a row',
    icon: Icons.view_week,
    color: Color(0xFFFB8C00),
  ),
  ComicTemplate(
    id: 'single_splash',
    title: 'Full Page',
    description: 'One dramatic splash',
    icon: Icons.crop_free,
    color: Color(0xFF3949AB),
  ),
  ComicTemplate(
    id: 'single_column',
    title: '3-Row Strip',
    description: 'Vertical story flow',
    icon: Icons.view_agenda,
    color: Color(0xFF43A047),
  ),
  ComicTemplate(
    id: 'five_panel',
    title: '5-Panel Drama',
    description: 'Wide top + 4 below',
    icon: Icons.dashboard_customize,
    color: Color(0xFF6D4C41),
  ),
  ComicTemplate(
    id: 'two_column',
    title: 'Two Columns',
    description: 'Side-by-side panels',
    icon: Icons.view_column,
    color: Color(0xFF00897B),
  ),
  ComicTemplate(
    id: 'magazine',
    title: 'Magazine',
    description: 'Main story + sidebar',
    icon: Icons.auto_stories,
    color: Color(0xFF00838F),
  ),
  ComicTemplate(
    id: 'splash_three',
    title: 'Splash + Row',
    description: 'Hero panel + 3 below',
    icon: Icons.view_quilt,
    color: Color(0xFFEF6C00),
  ),
  ComicTemplate(
    id: 'four_strip',
    title: '4-Frame Strip',
    description: 'Four panels in a row',
    icon: Icons.view_carousel,
    color: Color(0xFF7B1FA2),
  ),
  ComicTemplate(
    id: 'header_content',
    title: 'Title + Body',
    description: 'Header with main area',
    icon: Icons.article,
    color: Color(0xFFC62828),
  ),
  ComicTemplate(
    id: 'two_row',
    title: 'Two Rows',
    description: 'Top and bottom panels',
    icon: Icons.view_day,
    color: Color(0xFF795548),
  ),
  ComicTemplate(
    id: 'three_column',
    title: 'Three Columns',
    description: 'Triple column layout',
    icon: Icons.view_column_outlined,
    color: Color(0xFF558B2F),
  ),
  ComicTemplate(
    id: 'grid_2x3',
    title: '2×3 Grid',
    description: 'Two columns, three rows',
    icon: Icons.apps,
    color: Color(0xFF0277BD),
  ),
  ComicTemplate(
    id: 'story_l',
    title: 'L-Shape Story',
    description: 'Main panel + side strip',
    icon: Icons.turn_right,
    color: Color(0xFF455A64),
  ),
  ComicTemplate(
    id: '',
    title: 'Blank Page',
    description: 'Start from scratch',
    icon: Icons.add_box_outlined,
    color: Color(0xFF546E7A),
  ),
];
