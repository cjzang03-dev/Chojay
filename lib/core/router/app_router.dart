import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/partner/presentation/partner_dashboard_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final isSignedIn = ref.read(isSignedInProvider);
      final goingToSignIn = state.matchedLocation == '/sign-in';

      if (!isSignedIn) {
        return goingToSignIn ? null : '/sign-in';
      }

      // Route by role: tourists get the booking-focused shell, guides and
      // operators get the partner dashboard. Only decided at '/' or when
      // leaving sign-in — an in-shell navigation never gets bounced.
      if (goingToSignIn || state.matchedLocation == '/') {
        final profile = await ref.read(currentProfileProvider.future);
        return (profile?.isPartner ?? false) ? '/partner' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _LoadingGate(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/partner',
        builder: (context, state) => const PartnerDashboardShell(),
      ),
    ],
  );
});

/// Brief fallback shown at '/' while the redirect above resolves which
/// shell to land in (waits on the signed-in user's profile fetch).
class _LoadingGate extends StatelessWidget {
  const _LoadingGate();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

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
