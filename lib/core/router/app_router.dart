import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isSignedIn = ref.read(isSignedInProvider);
      final goingToSignIn = state.matchedLocation == '/sign-in';

      if (!isSignedIn && !goingToSignIn) return '/sign-in';
      if (isSignedIn && goingToSignIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );
});

/// Bridges the Supabase auth stream (via [isSignedInProvider]) to
/// go_router's [Listenable]-based refresh mechanism so a sign-in/sign-out
/// immediately re-runs the redirect above.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _subscription = _ref.listen<bool>(
      isSignedInProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<bool> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
