/// Runtime configuration read from `--dart-define-from-file`.
///
/// Values are compiled in at build time (never bundled as an on-disk asset),
/// so the same mechanism works for mobile, web, and CI builds without a
/// runtime file-read step. See `env.example.json` at the repo root for the
/// keys this app expects, and `README.md` for how to supply your own
/// `env.json` locally.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// The OAuth web client ID from Google Cloud Console, required by
  /// google_sign_in on Android/iOS even when using Supabase's hosted OAuth,
  /// and used directly for the web sign-in button.
  static const googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
