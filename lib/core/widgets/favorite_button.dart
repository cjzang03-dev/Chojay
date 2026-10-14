import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A circular heart toggle, styled to sit on top of a cover photo (card
/// corner) or in an app bar (detail screen) — same widget, both contexts.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.compact = false,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 40.0;
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? AppColors.errorRed : AppColors.himalayanGreenDark,
            size: compact ? 18 : 22,
          ),
        ),
      ),
    );
  }
}
