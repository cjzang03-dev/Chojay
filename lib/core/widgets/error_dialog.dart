import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A blocking, copyable error dialog — used instead of a SnackBar for
/// sign-in failures specifically, since a SnackBar is easy to miss when
/// someone's attention is on waiting for the next screen to appear, and
/// diagnosing an auth failure needs the exact error text, not just "it
/// failed somehow".
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required Object error,
}) {
  final message = error.toString();
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SelectableText(message),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: message)),
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
