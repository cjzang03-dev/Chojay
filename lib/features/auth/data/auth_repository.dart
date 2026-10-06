import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/config/supabase_client.dart';

/// The two ways someone can complete Google sign-in in this app: the
/// invisible-default tourist path (main app experience) and the separate
/// "Partner with us" path for guides/operators. Both use the same Google
/// credential; only the `profiles.user_type` written afterwards differs.
enum SignupIntent { tourist, guide, operator }

class AuthRepository {
  // Pinned to the pre-Credential-Manager v6 API (not the newer
  // GoogleSignIn.instance/.authenticate() v7 flow) — v7's Android
  // implementation hangs indefinitely after the account picker closes on
  // a range of real devices, a known, unresolved upstream bug (e.g.
  // flutter/flutter#187395). v6 uses the older, still-supported
  // Play Services Auth sign-in path, which doesn't have this failure mode.
  AuthRepository({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId:
                  Env.googleWebClientId.isEmpty ? null : Env.googleWebClientId,
            );

  final GoogleSignIn _googleSignIn;

  /// Survives the full-page reload that web's OAuth redirect causes, so
  /// [AuthBootstrap] can tell which role a brand-new web sign-in was for
  /// once the session lands back in a fresh app instance.
  static const _pendingIntentKey = 'pending_signup_intent';

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingIntentKey, intent.name);
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Without this, Supabase redirects back to the project's Site URL
        // instead of wherever this app is actually running — on a dev
        // build (flutter run -d chrome, a random port each run) that sends
        // the browser to the marketing site, not back to the app, so
        // sign-in silently never completes. Uri.base is the real running
        // origin in both dev and a deployed build. It must also be added
        // to Supabase's Authentication > URL Configuration > Redirect URLs
        // allow-list, or Supabase will reject it and fall back anyway.
        redirectTo: Uri.base.toString(),
      );
      // Web uses a full-page redirect, which tears this app instance down
      // before signInWithOAuth's future even resolves. Profile bootstrap
      // happens in AuthBootstrap's signed-in listener once the session
      // lands back in the fresh app instance after the round trip.
      return;
    }

    // signIn() returns null on user-cancel rather than throwing — kept as
    // a timeout too, as a safety net against the same class of plugin hang
    // (less likely on this older API, but cheap insurance).
    final googleUser = await _googleSignIn.signIn().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Google sign-in did not respond within 20s.',
      ),
    );
    if (googleUser == null) {
      throw const SignInCancelledException();
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    // No nonce here: unlike v7's Credential Manager flow, this older API's
    // ID token doesn't embed one, so passing one would make Supabase check
    // a nonce the token was never issued with.
    await supabase.auth
        .signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
            'Supabase did not respond to signInWithIdToken within 20s.',
          ),
        );

    await ensureProfile(intent);
  }

  /// Reads back the intent recorded before the most recent web sign-in
  /// attempt and clears it, so a later sign-in never reuses a stale value.
  /// Defaults to [SignupIntent.tourist] if nothing was recorded (e.g. an
  /// existing session restored on app start, not a fresh sign-in).
  Future<SignupIntent> consumePendingWebIntent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingIntentKey);
    await prefs.remove(_pendingIntentKey);
    return SignupIntent.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => SignupIntent.tourist,
    );
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
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await supabase.auth.signOut();
  }
}

class SignInCancelledException implements Exception {
  const SignInCancelledException();
}
