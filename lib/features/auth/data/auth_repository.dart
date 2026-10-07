import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';

/// The two ways someone can complete Google sign-in in this app: the
/// invisible-default tourist path (main app experience) and the separate
/// "Partner with us" path for guides/operators. Both use the same Google
/// credential; only the `profiles.user_type` written afterwards differs.
enum SignupIntent { tourist, guide, operator }

class AuthRepository {
  /// Native sign-in uses this exact redirect URI with Supabase, and only
  /// the scheme portion (below) with flutter_web_auth_2 — both must still
  /// be in Supabase's Authentication > URL Configuration > Redirect URLs
  /// allow-list, same as before.
  static const _nativeRedirectUri = 'com.journeyinbhutan.chojay://login-callback';
  static const _nativeCallbackScheme = 'com.journeyinbhutan.chojay';

  /// Survives the full-page reload that web's OAuth redirect causes, so
  /// [AuthBootstrap] can tell which role a brand-new web sign-in was for
  /// once the session lands back in a fresh app instance. Native doesn't
  /// need this to survive anything — signInWithGoogle awaits the whole
  /// flow — but reads it back the same way for one code path.
  static const _pendingIntentKey = 'pending_signup_intent';

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  /// Signs in with Google.
  ///
  /// [intent] controls the `user_type` written for a brand-new profile only.
  /// Tourist is the invisible default for the main app flow; guide/operator
  /// is only reachable from the separate "Partner with us" entry point.
  /// An existing profile's `user_type` is never overwritten here — that
  /// value is owned by admin approval / the website's identity checks.
  Future<void> signInWithGoogle(SignupIntent intent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingIntentKey, intent.name);

    if (kIsWeb) {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Without this, Supabase redirects back to the project's Site URL
        // instead of wherever this app is actually running — on a dev
        // build (flutter run -d chrome, a random port each run) that sends
        // the browser to the marketing site, not back to the app. Web uses
        // a full-page redirect, which tears this app instance down before
        // this call's future even resolves — profile bootstrap happens in
        // AuthBootstrap's signed-in listener once the session lands back
        // in the fresh app instance after the round trip.
        redirectTo: Uri.base.toString(),
      );
      return;
    }

    // Native: open the OAuth URL in a Custom Tab (Android) / ASWebAuthentication
    // Session (iOS) via flutter_web_auth_2, rather than Supabase's own
    // signInWithOAuth + an external-browser handoff. That approach left at
    // least one real device stuck on a black screen after returning from
    // the browser — a known class of Android task/activity bug with a
    // separate deep-link Intent resolving back into the app. This way, the
    // same call that opens the browser owns and closes it, with no
    // separate Intent step to go wrong.
    final oauthUrl = await supabase.auth.getOAuthSignInUrl(
      provider: OAuthProvider.google,
      redirectTo: _nativeRedirectUri,
    );
    final result = await FlutterWebAuth2.authenticate(
      url: oauthUrl.url,
      callbackUrlScheme: _nativeCallbackScheme,
    );
    await supabase.auth.getSessionFromUrl(Uri.parse(result));
  }

  /// Reads back the intent recorded before the most recent sign-in attempt
  /// and clears it, so a later sign-in never reuses a stale value. Defaults
  /// to [SignupIntent.tourist] if nothing was recorded (e.g. an existing
  /// session restored on app start, not a fresh sign-in).
  Future<SignupIntent> consumePendingIntent() async {
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
    await supabase.auth.signOut();
  }
}
