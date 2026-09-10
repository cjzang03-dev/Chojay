import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared placeholder for tabs not yet built, so every stub reads the same
/// rather than each screen inventing its own "TODO" look.
class ComingSoon extends StatelessWidget {
  const ComingSoon({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.stoneGrey),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
