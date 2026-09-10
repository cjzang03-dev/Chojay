import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
    } on SignInCancelledException {
      // User backed out of the Google chooser; nothing to show.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.himalayanGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.landscape_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Journey in Bhutan',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Curated Bhutan itineraries, matched with\nlicensed local guides and operators.',
                style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
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
                  label: Text(_isSigningIn ? 'Signing in…' : 'Continue with Google'),
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
                child: const Text('Are you a guide or tour operator? Partner with us'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
