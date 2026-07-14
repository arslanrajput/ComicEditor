import 'dart:io';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_info.dart';
import '../theme/comic_theme.dart';
import '../widgets/app_logo.dart';
import '../services/inkwell_profile_service.dart';

/// Inkwell top app bar — adapts per tab (search on Projects, etc.).
class InkwellAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenu;
  final VoidCallback onProfile;
  final bool showSearch;
  final VoidCallback? onSearchTap;
  final bool showTitleOnly;

  final bool showCloudSync;
  final VoidCallback? onCloudSyncTap;

  const InkwellAppBar({
    super.key,
    required this.onMenu,
    required this.onProfile,
    this.showSearch = false,
    this.onSearchTap,
    this.showTitleOnly = false,
    this.showCloudSync = false,
    this.onCloudSyncTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final avatarPath = InkwellProfileService.avatarPath;

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: ComicTheme.primary),
        onPressed: onMenu,
        tooltip: 'Menu',
      ),
      title: showTitleOnly
          ? null
          : Text(
              AppInfo.appName,
              style: GoogleFonts.dmSerifDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: ComicTheme.primary,
              ),
            ),
      centerTitle: true,
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search, color: ComicTheme.primary),
            onPressed: onSearchTap,
            tooltip: 'Search',
          ),
        if (showCloudSync)
          IconButton(
            icon: const Icon(Icons.cloud_done_outlined,
                color: ComicTheme.primary),
            onPressed: onCloudSyncTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Projects and characters are saved on this device.',
                      ),
                    ),
                  );
                },
            tooltip: 'Saved on device',
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ComicTheme.inkwellLight,
              backgroundImage:
                  avatarPath != null ? FileImage(File(avatarPath)) : null,
              child: avatarPath == null
                  ? Icon(Icons.person, color: ComicTheme.primary, size: 22)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Character Studio / Plot Assistant style app bar with custom title.
class InkwellStudioAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const InkwellStudioAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          onBack != null ? Icons.arrow_back : Icons.menu,
          color: ComicTheme.primary,
        ),
        onPressed: onBack ?? () => Scaffold.maybeOf(context)?.openDrawer(),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: ComicTheme.primary,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }
}

/// Animated notch bottom bar — iOS-style blur with sliding notch indicator.
class InkwellBottomNav extends StatelessWidget {
  final NotchBottomBarController controller;
  final ValueChanged<int> onTap;

  const InkwellBottomNav({
    super.key,
    required this.controller,
    required this.onTap,
  });

  static const _inactive = Color(0xFF90A4AE);

  @override
  Widget build(BuildContext context) {
    return AnimatedNotchBottomBar(
      notchBottomBarController: controller,
      color: Colors.white.withValues(alpha: 0.88),
      showLabel: true,
      showBlurBottomBar: true,
      blurOpacity: 0.75,
      blurFilterX: 16,
      blurFilterY: 24,
      notchColor: ComicTheme.primary,
      kBottomRadius: 28,
      kIconSize: 22,
      durationInMilliSeconds: 320,
      elevation: 0,
      showShadow: true,
      shadowElevation: 12,
      removeMargins: false,
      bottomBarHeight: 64,
      itemLabelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: ComicTheme.primary,
      ),
      bottomBarItems: const [
        BottomBarItem(
          inActiveItem: Icon(Icons.home_outlined, color: _inactive),
          activeItem: Icon(Icons.home, color: Colors.white),
          itemLabel: 'Home',
        ),
        BottomBarItem(
          inActiveItem: Icon(Icons.add_box_outlined, color: _inactive),
          activeItem: Icon(Icons.add_box, color: Colors.white),
          itemLabel: 'Create',
        ),
        BottomBarItem(
          inActiveItem: Icon(Icons.dashboard_outlined, color: _inactive),
          activeItem: Icon(Icons.dashboard, color: Colors.white),
          itemLabel: 'Templates',
        ),
        BottomBarItem(
          inActiveItem: Icon(Icons.folder_outlined, color: _inactive),
          activeItem: Icon(Icons.folder, color: Colors.white),
          itemLabel: 'Projects',
        ),
        BottomBarItem(
          inActiveItem: Icon(Icons.person_outline, color: _inactive),
          activeItem: Icon(Icons.person, color: Colors.white),
          itemLabel: 'Profile',
        ),
      ],
      onTap: onTap,
    );
  }
}
/// Brand header used inside Home tab.
class InkwellBrandHeader extends StatelessWidget {
  const InkwellBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogo(size: 32),
        const SizedBox(width: 8),
        Text(
          AppInfo.appName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: ComicTheme.primary,
          ),
        ),
      ],
    );
  }
}
