import 'package:flutter/material.dart';

/// Shared visual language for Comic Creator (matches product wireframes).
class ComicTheme {
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color scaffoldBg = Color(0xFFF4F6F8);
  static const Color toolbarBg = Color(0xFFECEFF1);
  static const Color drawerBg = Color(0xFFCFD8DC);
  static const Color panelBorder = Color(0xFFB0BEC5);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: panelBorder.withValues(alpha: 0.5)),
        ),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static BoxDecoration projectBarDecoration({bool selected = false}) {
    return BoxDecoration(
      color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: selected ? primary : panelBorder,
        width: selected ? 1.5 : 1,
      ),
    );
  }

  /// Flat panel frame for PDF/PNG export (no shadow — shadows get clipped at page edge).
  static BoxDecoration comicPanelFrameExport() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.black87, width: 1.5),
    );
  }

  static BoxDecoration editorToolbarDecoration() {
    return BoxDecoration(
      color: toolbarBg,
      border: Border(
        bottom: BorderSide(color: panelBorder.withValues(alpha: 0.6)),
      ),
    );
  }

  /// Comic-panel frame on the layout canvas (wireframe-style thick border).
  static BoxDecoration comicPanelFrame({required bool selected}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: selected ? primaryDark : Colors.black87,
        width: selected ? 3 : 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: selected ? 0.18 : 0.1),
          blurRadius: selected ? 6 : 3,
          offset: const Offset(1, 2),
        ),
      ],
    );
  }

  static const List<Color> backgroundPresets = [
    Colors.white,
    Color(0xFFFFF9C4),
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFCE4EC),
    Color(0xFFEFEBE9),
    Color(0xFF263238),
    Color(0xFF5D4037),
  ];

  static Widget toolbarIconButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? primaryDark : Colors.black87,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? ComicTheme.primaryDark : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
