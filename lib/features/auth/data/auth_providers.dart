import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
