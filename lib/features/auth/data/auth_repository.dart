import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/config/supabase_client.dart';

/// The two ways someone can complete Google sign-in in this app: the
/// invisible-default tourist path (main app experience) and the separate
/// "Partner with us" path for guides/operators. Both use the same Google
/// credential; only the `profiles.user_type` written afterwards differs.
enum SignupIntent { tourist, guide, operator }

class AuthRepository {
  AuthRepository({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // Required on Android/iOS so Supabase can verify the Google ID
              // token server-side; unused on web (Supabase's OAuth redirect
              // flow is used there instead).
              serverClientId: Env.googleWebClientId.isEmpty
                  ? null
                  : Env.googleWebClientId,
              scopes: const ['email', 'profile'],
            );

  final GoogleSignIn _googleSignIn;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  /// Signs in with Google and ensures a matching `profiles` row exists.
  ///
  /// [intent] controls the `user_type` written for a brand-new profile only.
  /// Tourist is the invisible default for the main app flow; guide/operator
  /// is only reachable from the separate "Partner with us" entry point.
  /// An existing profile's `user_type` is never overwritten here — that
  /// value is owned by admin approval / the website's identity checks.
  Future<void> signInWithGoogle(SignupIntent intent) async {
    if (kIsWeb) {
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
      // Web uses a redirect; profile bootstrap happens in the auth-state
      // listener once the session lands back in the app (see AuthController).
      return;
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const SignInCancelledException();
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );

    await ensureProfile(intent);
  }

  /// Creates a `profiles` row for a first-time sign-in. No-ops if one
  /// already exists, so returning operators/guides/tourists are unaffected.
  Future<void> ensureProfile(SignupIntent intent) async {
    final user = currentUser;
    if (user == null) return;

    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    await supabase.from('profiles').insert({
      'id': user.id,
      'email': user.email,
      'full_name': user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          '',
      'user_type': switch (intent) {
        SignupIntent.tourist => 'tourist',
        SignupIntent.guide => 'guide',
        SignupIntent.operator => 'operator',
      },
    });
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await supabase.auth.signOut();
  }
}

class SignInCancelledException implements Exception {
  const SignInCancelledException();
}
