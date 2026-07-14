import 'package:flutter/material.dart';

import '../PanelModel/Project.dart';

/// UI helpers for Inkwell project cards.
class ProjectDisplayUtils {
  ProjectDisplayUtils._();

  static int pageCount(Project project) => project.pages.length;

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Edited ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Edited ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Edited Yesterday';
    if (diff.inDays < 7) return 'Edited ${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Edited ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String statusLabel(Project project) {
    final panels = project.pages.fold<int>(
      0,
      (sum, page) => sum + page.length,
    );
    final hours = DateTime.now().difference(project.lastModified).inHours;
    if (hours < 48) return 'In Progress';
    if (panels <= 2) return 'Sketching';
    return 'Review';
  }

  static (Color bg, Color fg) statusColors(String status) {
    switch (status) {
      case 'In Progress':
        return (const Color(0xFFE1F0FF), const Color(0xFF005696));
      case 'Sketching':
        return (const Color(0xFFFCE4EC), const Color(0xFFC2185B));
      case 'Review':
        return (const Color(0xFFFFF8E1), const Color(0xFFF9A825));
      default:
        return (const Color(0xFFECEFF1), const Color(0xFF546E7A));
    }
  }

  static String genreHint(Project project) {
    final pages = pageCount(project);
    if (pages > 20) return 'Action';
    if (pages > 8) return 'Fantasy';
    return 'Comic';
  }
}
