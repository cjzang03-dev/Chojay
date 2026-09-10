import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';

/// The secondary, clearly-separate entry point for guides and operators —
/// never presented as a peer option to the main tourist sign-in. Role choice
/// here is a visual card picker (mirroring Grab/Lyft's rider/driver split),
/// not a dropdown, since only this small audience ever needs to state which
/// they are.
class PartnerEntryScreen extends ConsumerStatefulWidget {
  const PartnerEntryScreen({super.key});

  @override
  ConsumerState<PartnerEntryScreen> createState() =>
      _PartnerEntryScreenState();
}

class _PartnerEntryScreenState extends ConsumerState<PartnerEntryScreen> {
  SignupIntent? _submitting;

  Future<void> _choose(SignupIntent intent) async {
    setState(() => _submitting = intent);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle(intent);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _ApplicationPendingScreen()),
      );
    } on SignInCancelledException {
      // no-op
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner with us')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'List your business',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us which best describes you. An admin reviews every '
              'application before it goes live.',
              style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
            ),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.hiking_rounded,
              title: 'Licensed Guide',
              description:
                  'I lead treks and tours in Bhutan under my own guide license.',
              isLoading: _submitting == SignupIntent.guide,
              onTap: _submitting == null
                  ? () => _choose(SignupIntent.guide)
                  : null,
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.business_center_rounded,
              title: 'Tour Operator',
              description:
                  'I run a licensed tour company that fulfills itineraries end-to-end.',
              isLoading: _submitting == SignupIntent.operator,
              onTap: _submitting == null
                  ? () => _choose(SignupIntent.operator)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.himalayanGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.himalayanGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: AppColors.stoneGrey, height: 1.3),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationPendingScreen extends StatelessWidget {
  const _ApplicationPendingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 56, color: AppColors.himalayanGreen),
              const SizedBox(height: 16),
              Text(
                'Application received',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'An admin will review your details before you can appear as '
                'a fulfillment option for itineraries. We\'ll notify you once '
                'you\'re approved.',
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
