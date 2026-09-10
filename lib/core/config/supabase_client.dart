import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Initializes the single Supabase client shared with the website
/// (same project, same `profiles`/`itineraries`/`bookings`/... tables).
///
/// Call once from `main()` before `runApp`.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // Supabase now calls this the "publishable key"; it's the same value
    // as the legacy anon key, so the env var keeps the more familiar name.
    publishableKey: Env.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
