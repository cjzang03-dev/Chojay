import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    // Re-read on auth-state changes so sign-out reflects immediately.
    ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.himalayanGreen.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: AppColors.himalayanGreen, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            user?.userMetadata?['full_name'] as String? ??
                user?.email ??
                'Traveler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(user!.email!, style: TextStyle(color: AppColors.stoneGrey)),
          ],
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
