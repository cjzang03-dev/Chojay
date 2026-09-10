import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Placeholder for chat (build order step 6): reuses the website's existing
/// conversations/messages tables over Supabase realtime.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ComingSoon(
        icon: Icons.chat_bubble_outline,
        title: 'Chat',
        message: 'Message your operator or guide here soon.',
      ),
    );
  }
}
