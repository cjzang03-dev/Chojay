import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';

/// The two ways someone can complete Google sign-in in this app: the
/// invisible-default tourist path (main app experience) and the separate
/// "Partner with us" path for guides/operators. Both use the same Google
/// credential; only the `profiles.user_type` written afterwards differs.
enum SignupIntent { tourist, guide, operator }

class AuthRepository {
  /// The whole app now signs in through the browser-based OAuth redirect
  /// (the same flow the website uses) rather than the native
  /// google_sign_in plugin. The plugin requires Play Services to validate
  /// this app's package name + signing certificate against an "Android"
  /// OAuth client in Google Cloud Console, and that check kept failing
  /// with ApiException: 10 (DEVELOPER_ERROR) on real devices even with a
  /// byte-for-byte confirmed-correct package name, SHA-1 and client ID —
  /// across two different phone brands, ruling out device-specific causes.
  /// The browser redirect flow never touches that Android-client
  /// validation at all, so this entire failure class doesn't apply to it.
  static const _nativeRedirectUri = 'com.journeyinbhutan.chojay://login-callback';

  /// Survives the external-browser round trip (a full-page reload on web,
  /// an app backgrounding on native) so [AuthBootstrap] can tell which role
  /// a brand-new sign-in was for once the session lands back in the app.
  static const _pendingIntentKey = 'pending_signup_intent';

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  /// Starts Google sign-in via Supabase's hosted browser-redirect OAuth
  /// flow, on every platform.
  ///
  /// [intent] controls the `user_type` written for a brand-new profile only.
  /// Tourist is the invisible default for the main app flow; guide/operator
  /// is only reachable from the separate "Partner with us" entry point.
  /// An existing profile's `user_type` is never overwritten here — that
  /// value is owned by admin approval / the website's identity checks.
  ///
  /// This only launches the browser round trip; it does not wait for
  /// sign-in to actually complete. Web tears this app instance down with a
  /// full-page redirect before the returned future would resolve anyway;
  /// native backgrounds the app and comes back via [_nativeRedirectUri]'s
  /// deep link. Either way, profile bootstrap happens in
  /// [AuthBootstrap]'s signed-in listener once the session lands back.
  Future<void> signInWithGoogle(SignupIntent intent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingIntentKey, intent.name);

    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      // Without this, Supabase redirects back to the project's Site URL
      // instead of wherever this app is actually running. On web, a dev
      // build (flutter run -d chrome, a random port each run) would
      // otherwise send the browser to the marketing site, not back to the
      // app. On native, it must be this app's own registered deep link
      // scheme, or the browser has nowhere to hand the session back to.
      // Both values must also be added to Supabase's Authentication > URL
      // Configuration > Redirect URLs allow-list, or Supabase rejects the
      // redirect and falls back anyway.
      redirectTo: kIsWeb ? Uri.base.toString() : _nativeRedirectUri,
    );
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
