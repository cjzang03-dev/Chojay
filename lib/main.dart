import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/config/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.isConfigured) {
    await initSupabase();
  }
  runApp(const ProviderScope(child: ChojayApp()));
}

class ChojayApp extends ConsumerWidget {
  const ChojayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isConfigured) {
      return const MaterialApp(home: _MissingConfigScreen());
    }

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
