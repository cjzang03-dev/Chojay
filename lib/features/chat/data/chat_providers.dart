import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../domain/conversation.dart';
import 'chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// Newest-first conversation list, kept live via a realtime subscription —
/// without this, the list only ever reflects whatever existed the first
/// time this provider was built, since the Chat tab stays mounted inside
/// HomeShell's IndexedStack and never rebuilds on its own when a new
/// message arrives.
final conversationsProvider =
    AsyncNotifierProvider.autoDispose<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AutoDisposeAsyncNotifier<List<Conversation>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Conversation>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    _channel?.unsubscribe();
    _channel = null;

    if (supabase.auth.currentUser != null) {
      _channel = repo.subscribeToIncomingMessages(() async {
        state = await AsyncValue.guard(repo.fetchConversations);
      });
    }
    ref.onDispose(() => _channel?.unsubscribe());

    return repo.fetchConversations();
  }
}
