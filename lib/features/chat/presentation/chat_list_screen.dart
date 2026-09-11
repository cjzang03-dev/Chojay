import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../data/chat_providers.dart';
import '../domain/conversation.dart';
import 'chat_thread_screen.dart';

/// Direct-message inbox, reusing the website's existing conversations —
/// a message sent from the app shows up in the operator's website inbox
/// and vice versa.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(conversationsProvider.future),
        child: conversationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
              ),
            ],
          ),
          data: (conversations) {
            if (conversations.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 500,
                    child: ComingSoon(
                      icon: Icons.chat_bubble_outline,
                      title: 'No messages yet',
                      message: 'Request a booking to start a conversation '
                          'with an operator.',
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(conversation: conversation);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.himalayanGreen.withValues(alpha: 0.1),
        backgroundImage: conversation.otherPhotoUrl != null &&
                conversation.otherPhotoUrl!.isNotEmpty
            ? NetworkImage(conversation.otherPhotoUrl!)
            : null,
        child: conversation.otherPhotoUrl == null ||
                conversation.otherPhotoUrl!.isEmpty
            ? Icon(
                conversation.otherUserType == 'guide'
                    ? Icons.hiking_rounded
                    : Icons.business_center_rounded,
                color: AppColors.himalayanGreen,
              )
            : null,
      ),
      title: Text(conversation.otherDisplayName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        lastMessage == null || lastMessage.isEmpty
            ? 'No messages yet'
            : lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.stoneGrey),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            conversationId: conversation.id,
            otherUserId: conversation.otherUserId,
            otherDisplayName: conversation.otherDisplayName,
          ),
        ),
      ),
    );
  }
}
