import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Currency and language aren't switchable yet (everything in this app is
/// USD/English) — this screen states that plainly rather than offering
/// controls that don't do anything.
class TravelPreferencesScreen extends StatelessWidget {
  const TravelPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel preferences')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.attach_money_rounded, color: AppColors.himalayanGreenDark),
                  title: Text('Currency'),
                  subtitle: Text('USD'),
                ),
                Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.language_rounded, color: AppColors.himalayanGreenDark),
                  title: Text('Language'),
                  subtitle: Text('English'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Sample prices across the app are shown in USD. More currencies '
            'and languages are on the way.',
            style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
          ),
        ],
      ),
    );
  }
}
