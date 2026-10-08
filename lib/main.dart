import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/config/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_providers.dart';

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
      // Diagnostic only, temporary: a self-contained ticking clock drawn on
      // top of every screen, independent of any provider or route state.
      // Earlier fixes (Impeller off, TextureView, rebuilding realtime
      // channels on resume) didn't stop the black screen on resume, and it
      // shows no red error either — which only rules out a Dart exception,
      // not a genuine engine/renderer freeze vs. the UI isolate itself
      // being stuck. If this clock is still ticking next time the screen
      // goes black, Flutter is alive and something is painting solid black
      // on purpose (a real bug to find in code); if it's frozen too, the
      // problem is below Flutter entirely (the Android surface itself).
      builder: (context, child) => Stack(
        children: [
          ?child,
          const Positioned(bottom: 8, right: 8, child: _HeartbeatOverlay()),
        ],
      ),
    );
  }
}

class _HeartbeatOverlay extends StatefulWidget {
  const _HeartbeatOverlay();

  @override
  State<_HeartbeatOverlay> createState() => _HeartbeatOverlayState();
}

class _HeartbeatOverlayState extends State<_HeartbeatOverlay> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _now;
    final label =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return IgnorePointer(
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
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
