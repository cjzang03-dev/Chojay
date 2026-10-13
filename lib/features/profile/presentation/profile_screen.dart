import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';
import '../../notifications/presentation/notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_account_screen.dart';
import 'travel_preferences_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openHelpAndSupport(BuildContext context) async {
    final uri = Uri.parse('https://journeyinbhutan.com/bhutan-travel-info');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t open the travel guide.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    // Re-read on auth-state changes so sign-out reflects immediately.
    ref.watch(authStateProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    // profiles.full_name/photo_url (editable in-app) win once set; Google's
    // own metadata is just the fallback for a brand-new profile.
    final name = profile?.fullName?.isNotEmpty == true
        ? profile!.fullName!
        : user?.userMetadata?['full_name'] as String? ??
            user?.userMetadata?['name'] as String? ??
            'Traveler';
    final avatarUrl = profile?.photoUrl?.isNotEmpty == true
        ? profile!.photoUrl
        : user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text(
            'A journey that\'s uniquely yours',
            style: TextStyle(color: AppColors.stoneGrey),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.himalayanGreen,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 32)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Traveler',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: profile),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'ACCOUNT & PREFERENCES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.stoneGrey,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Personal information',
                  subtitle: 'Your traveler details',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: profile),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _MenuRow(
                  icon: Icons.public_rounded,
                  label: 'Travel preferences',
                  subtitle: 'USD · English',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TravelPreferencesScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _MenuRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _MenuRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & support',
                  subtitle: 'Bhutan travel essentials',
                  onTap: () => _openHelpAndSupport(context),
                ),
                const Divider(height: 1, indent: 56),
                _MenuRow(
                  icon: Icons.shield_outlined,
                  label: 'Privacy & account',
                  subtitle: 'Your information, your choice',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyAccountScreen()),
                  ),
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

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.himalayanGreenDark),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.stoneGrey),
    );
  }
}
