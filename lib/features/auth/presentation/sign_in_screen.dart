import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_dialog.dart';
import '../../itineraries/data/itineraries_providers.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';
import 'partner_entry_screen.dart';

/// The app's front door. Unlike the website (browse-first, sign-in only at
/// booking), the app asks for sign-in immediately: this is for people
/// already committed to using the product, not casual browsers. Kept to a
/// single deliberate action — modeled on the speed of Klook/Grab/Lyft's
/// sign-in screens — with no role picker: anyone signing in here is a
/// tourist by default.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isSigningIn = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _isSigningIn = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(SignupIntent.tourist);
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, title: 'Sign-in failed', error: e);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroPhoto = ref.watch(signInHeroPhotoProvider).valueOrNull;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: _HeroPanel(photoUrl: heroPhoto),
          ),
          Expanded(
            flex: 5,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                child: Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSigningIn ? null : _continueWithGoogle,
                        icon: _isSigningIn
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.g_mobiledata, size: 26),
                        label: Text(
                            _isSigningIn ? 'Signing in…' : 'Continue with Google'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By continuing you agree to our Terms and Privacy Policy.',
                      style: TextStyle(fontSize: 12, color: AppColors.stoneGrey),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isSigningIn
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PartnerEntryScreen(),
                                ),
                              ),
                      child: const Text(
                          'Are you a guide or tour operator? Partner with us'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed photo with the title/tagline overlaid on a gradient scrim —
/// reuses a real, already-approved itinerary cover photo rather than the
/// flat icon tile this screen used to show. Falls back to the icon tile
/// while the photo loads, if there isn't one yet, or if it fails to load.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrl != null && photoUrl!.isNotEmpty)
            Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const _FallbackBackdrop(),
              errorBuilder: (context, error, stackTrace) =>
                  const _FallbackBackdrop(),
            )
          else
            const _FallbackBackdrop(),
          // Scrim so white title text stays legible over any photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journey in Bhutan',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Curated Bhutan itineraries, matched with licensed '
                  'local guides and operators.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBackdrop extends StatelessWidget {
  const _FallbackBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.himalayanGreenLight, AppColors.himalayanGreenDark],
        ),
      ),
      child: const Center(
        child: Icon(Icons.landscape_rounded, color: Colors.white54, size: 72),
      ),
    );
  }
}
