import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../domain/profile.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
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
