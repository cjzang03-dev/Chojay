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
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  Future<void>? _initFuture;

  /// `GoogleSignIn.instance` must be initialized exactly once before use.
  /// Deferred to first sign-in (rather than the constructor) since
  /// initialize() is async.
  Future<void> _ensureInitialized() {
    return _initFuture ??= _googleSignIn.initialize(
      // Required on Android/iOS so Supabase can verify the Google ID token
      // server-side; unused on web (Supabase's OAuth redirect flow is used
      // there instead).
      serverClientId:
          Env.googleWebClientId.isEmpty ? null : Env.googleWebClientId,
    );
  }

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

    await _ensureInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelledException();
      }
      rethrow;
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
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

    // Mirrors the website's setup-profile upsert (verified against
    // cjzang03-dev/taledesti-quest): tourists start 'active' and are only
    // gated at first booking, while guides/operators start 'pending' until
    // admin approval. Every profile also gets verification_status:
    // 'pending' there, so we set the same here rather than leaving it null
    // — website logic (and the admin verification queue) checks this field.
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
      'status': intent == SignupIntent.tourist ? 'active' : 'pending',
      'verification_status': 'pending',
    });
  }

  Future<void> signOut() async {
    if (!kIsWeb && _initFuture != null) {
      await _googleSignIn.signOut();
    }
    await supabase.auth.signOut();
  }
}

class SignInCancelledException implements Exception {
  const SignInCancelledException();
}
