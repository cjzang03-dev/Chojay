import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/config/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_providers.dart';

void main() {
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

class ChojayApp extends ConsumerWidget {
  const ChojayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
