import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/conversation.dart';
import 'chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(chatRepositoryProvider).fetchConversations();
});
