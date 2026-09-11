import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chojay/main.dart';

void main() {
  testWidgets('shows setup guidance when Supabase env is not configured',
      (WidgetTester tester) async {
    // Without --dart-define-from-file=env.json, Env.isConfigured is false;
    // the app should show setup guidance instead of crashing.
    await tester.pumpWidget(
      const ProviderScope(child: ChojayApp()),
    );

    expect(find.textContaining('Missing Supabase configuration'), findsOneWidget);
  });
}
