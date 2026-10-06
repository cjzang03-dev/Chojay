import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../domain/profile.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Bootstraps a `profiles` row the moment a sign-in's session lands. Every
/// platform now signs in through the same external-browser OAuth redirect
/// (see [AuthRepository.signInWithGoogle]), which returns before sign-in
/// actually completes, so this listener — not the call site — is what
/// actually creates the profile. Watched once from `ChojayApp` so it lives
/// for the app's lifetime.
final authBootstrapProvider = Provider<void>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final subscription = repo.authStateChanges.listen((state) async {
    if (state.event == AuthChangeEvent.signedIn) {
      final intent = await repo.consumePendingIntent();
      await repo.ensureProfile(intent);
    }
  });
  ref.onDispose(subscription.cancel);
});

/// The live Supabase auth state; the router redirect and sign-in screen
/// both key off this rather than polling `currentUser` directly.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final session = authState?.session ?? Supabase.instance.client.auth.currentSession;
  return session != null;
});

/// The signed-in user's own `profiles` row — used to decide whether they
/// land in the tourist shell or the partner (guide/operator) dashboard.
/// Recomputes whenever auth state changes, so it always reflects the
/// currently-signed-in user rather than a stale one.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final row = await supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();
  if (row == null) return null;
  return Profile.fromJson(row);
});
