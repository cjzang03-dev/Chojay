import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/config/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_providers.dart';
import 'features/chat/data/chat_providers.dart';
import 'features/notifications/data/notifications_providers.dart';

void main() {
  // Flutter's default release-mode ErrorWidget.builder renders nothing
  // visible — so a widget that throws mid-build shows up as exactly the
  // same blank/black screen as a genuine renderer hang, with no way to
  // tell them apart from a screenshot. Make build errors always show up
  // in red with the actual message, in every build mode.
  ErrorWidget.builder = (details) => Material(
        color: Colors.red.shade900,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Text(
                '${details.exception}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
      );

  // Without this guard, an exception thrown before runApp() ever paints a
  // frame (e.g. Supabase.initialize() failing on a device) leaves whatever
  // the native splash screen happens to show — solid black in dark mode,
  // with nothing in the UI to say why. Catching it here guarantees the
  // device always shows the actual error instead of an unexplained black
  // screen.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Env.isConfigured) {
      await initSupabase();
    }
    runApp(const ProviderScope(child: ChojayApp()));
  }, (error, stackTrace) {
    runApp(_StartupErrorApp(error: error));
  });
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'The app failed to start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SelectableText('$error'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChojayApp extends ConsumerStatefulWidget {
  const ChojayApp({super.key});

  @override
  ConsumerState<ChojayApp> createState() => _ChojayAppState();
}

class _ChojayAppState extends ConsumerState<ChojayApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The chat and notifications realtime subscriptions (open WebSocket
    // channels) don't get any signal when Android suspends the app's
    // network in the background — unlike Supabase's own auth token
    // refresh, which supabase_flutter already pauses/resumes itself. A
    // channel that went stale while backgrounded won't reliably recover on
    // its own, so force both providers to tear down and rebuild their
    // channel from scratch on resume rather than trust the stale one.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(conversationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) {
      return const MaterialApp(home: _MissingConfigScreen());
    }

    ref.watch(authBootstrapProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Journey in Bhutan',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Shown instead of crashing when SUPABASE_URL/SUPABASE_ANON_KEY weren't
/// passed via --dart-define-from-file. See README.md for setup.
class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.settings_outlined, size: 48),
              SizedBox(height: 16),
              Text(
                'Missing Supabase configuration.\n\n'
                'Copy env.example.json to env.json, fill in your Supabase '
                'project values, and run with:\n'
                '--dart-define-from-file=env.json',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
