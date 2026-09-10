import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client.dart';
import '../domain/conversation.dart';

/// Reuses the website's existing direct-messaging schema as-is
/// (`conversations`, `messages`, plus the `get_public_profile(s)_by_id(s)`
/// RPCs it already exposes for safely reading another user's public
/// profile fields under RLS). No new tables for chat.
///
/// Deliberately out of scope for this pass (the website has these; flagged
/// as deferred rather than silently built or silently dropped): message
/// reactions, in-app report/block. Worth adding once the core loop
/// (discover → book → message an operator) is proven.
class ChatRepository {
  String get _currentUserId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('Must be signed in to use chat.');
    return id;
  }

  Future<List<Conversation>> fetchConversations() async {
    final userId = _currentUserId;
    final rows = await supabase
        .from('conversations')
        .select()
        .or('participant_1.eq.$userId,participant_2.eq.$userId')
        .order('last_message_at', ascending: false);

    final otherIds = rows
        .map((r) => r['participant_1'] == userId
            ? r['participant_2'] as String
            : r['participant_1'] as String)
        .toSet()
        .toList();

    var profilesById = <String, dynamic>{};
    if (otherIds.isNotEmpty) {
      final profiles = await supabase
          .rpc('get_public_profiles_by_ids', params: {'profile_ids': otherIds});
      profilesById = {
        for (final p in (profiles as List)) (p as Map)['id'] as String: p,
      };
    }

    return rows
        .map((r) => Conversation.fromJson(
              r,
              currentUserId: userId,
              otherProfile: profilesById[r['participant_1'] == userId
                  ? r['participant_2']
                  : r['participant_1']] as Map<String, dynamic>?,
            ))
        .toList();
  }

  /// Finds the existing conversation with [otherUserId], or creates one.
  /// Mirrors the website's `startNewConversation`.
  Future<String> startOrGetConversation(String otherUserId) async {
    final userId = _currentUserId;
    final existing = await supabase
        .from('conversations')
        .select('id')
        .or(
          'and(participant_1.eq.$userId,participant_2.eq.$otherUserId),'
          'and(participant_1.eq.$otherUserId,participant_2.eq.$userId)',
        )
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final inserted = await supabase
        .from('conversations')
        .insert({
          'participant_1': userId,
          'participant_2': otherUserId,
          'last_message': '',
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  /// Fetches a conversation's messages and marks the ones addressed to the
  /// current user as read (matching the website's behavior on opening a
  /// thread).
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final rows = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');

    await supabase
        .from('messages')
        .update({'read': true})
        .eq('conversation_id', conversationId)
        .eq('receiver_id', _currentUserId);

    return rows.map(ChatMessage.fromJson).toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    final userId = _currentUserId;
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'receiver_id': receiverId,
      'content': content,
      'read': false,
    });
    await supabase.from('conversations').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    final senderProfile = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();
    final senderName = senderProfile?['full_name'] as String? ?? 'Someone';
    await supabase.from('notifications').insert({
      'user_id': receiverId,
      'title': 'New message from $senderName \u{1F4AC}',
      'message': content.length > 60 ? '${content.substring(0, 60)}...' : content,
      'type': 'message',
      'related_id': conversationId,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await supabase.from('messages').delete().eq('id', messageId);
  }

  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(ChatMessage message) onInsert,
  ) {
    final channel = supabase.channel('messages-$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onInsert(ChatMessage.fromJson(payload.newRecord)),
        )
        .subscribe();
    return channel;
  }
}
