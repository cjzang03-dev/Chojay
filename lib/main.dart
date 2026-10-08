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
      // The clock confirmed Flutter itself is alive and still painting when
      // the screen goes black — so either something is deliberately
      // covering the real page in solid black, or the real page's content
      // is collapsing to near-zero size and the window's raw (black)
      // clear color shows through everywhere nothing was painted.
      // `Positioned.fill` forces the routed content to always take the
      // full screen regardless of its own intrinsic size, which rules out
      // (and fixes, if that's the cause) the second case. The small pill
      // above the clock also reports exactly what size that content thinks
      // it has — if it ever reads something tiny like "0×0" instead of the
      // full screen size, that's hard proof of a collapsed-size bug to
      // chase next, rather than another guess.
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          if (child != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _childSizeNotifier.value =
                        '${constraints.maxWidth.toStringAsFixed(0)}×'
                        '${constraints.maxHeight.toStringAsFixed(0)}';
                  });
                  return child;
                },
              ),
            ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: _childSizeNotifier,
                  builder: (context, value, _) => _DebugPill(text: value),
                ),
                const SizedBox(height: 4),
                const _HeartbeatOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagnostic only, temporary — see the comment on [ChojayApp.build]'s
/// `builder`.
final _childSizeNotifier = ValueNotifier<String>('(measuring…)');

class _DebugPill extends StatelessWidget {
  const _DebugPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
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
