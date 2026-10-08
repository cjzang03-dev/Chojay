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
    // Deliberately synchronous (no `async`/`await`). go_router doesn't
    // paint anything — not even the '/' route's own builder — until
    // `redirect` finishes, so an awaited network call in here (e.g. the
    // profile fetch below, used to live here) left the screen fully black
    // on a cold start for however long that call took. Role-based routing
    // now happens inside `_LoadingGate`, which paints a spinner immediately
    // and navigates onward itself once the profile fetch resolves.
    redirect: (context, state) {
      final isSignedIn = ref.read(isSignedInProvider);
      final goingToSignIn = state.matchedLocation == '/sign-in';

      if (!isSignedIn) {
        return goingToSignIn ? null : '/sign-in';
      }
      if (goingToSignIn) {
        return '/';
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

/// Shown at '/' the moment a signed-in user lands there (straight from
/// cold start, or bounced back from '/sign-in'). Paints its spinner
/// immediately, then decides which shell to send them to itself once the
/// profile fetch resolves — see the comment on `redirect` above for why
/// that decision doesn't live in `redirect` itself.
class _LoadingGate extends ConsumerWidget {
  const _LoadingGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    profileAsync.when(
      data: (profile) {
        final target = (profile?.isPartner ?? false) ? '/partner' : '/home';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(target);
        });
      },
      loading: () {},
      // Fail open to the tourist shell rather than leaving the user stuck
      // on a spinner forever if the profile fetch errors (e.g. no network).
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/home');
        });
      },
    );

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
