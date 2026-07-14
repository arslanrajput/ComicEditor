import 'package:flutter/material.dart';

/// Inkwell brand mark — launcher icon and in-app logo.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showShadow = false,
  });

  static const _assetPath = 'assets/branding/app_icon.png';

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF005696),
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: Icon(Icons.edit, color: Colors.white, size: size * 0.5),
        ),
      ),
    );

    if (!showShadow) return logo;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: logo,
    );
  }
}
