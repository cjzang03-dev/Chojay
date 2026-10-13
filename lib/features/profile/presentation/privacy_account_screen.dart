import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';

/// Account deletion isn't self-service yet, so this routes the request to
/// the same support inbox the website's privacy policy already publishes,
/// rather than silently doing nothing or faking a delete.
class PrivacyAccountScreen extends ConsumerWidget {
  const PrivacyAccountScreen({super.key});

  Future<void> _emailSupport(BuildContext context, {required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'journeyinbhutan2026@gmail.com',
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t open your email app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text(
            'Your information, your choice. We only collect what\'s needed '
            'to verify travelers, guides, and operators, and to connect you '
            'directly — never sold, never shared beyond what a booking '
            'requires.',
            style: TextStyle(color: AppColors.stoneGrey, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.himalayanGreenDark),
                  title: const Text('Request a copy of your data'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _emailSupport(context, subject: 'Data request'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                  title: const Text('Request account deletion'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _emailSupport(context, subject: 'Account deletion request'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
