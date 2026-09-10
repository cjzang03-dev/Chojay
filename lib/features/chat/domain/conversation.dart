/// A direct-message conversation between two profiles. Mirrors the
/// website's existing `conversations` table (verified against
/// `cjzang03-dev/taledesti-quest` — app/dashboard/page.tsx's
/// MessagingTab), reused as-is: no schema change for chat.
class Conversation {
  const Conversation({
    required this.id,
    required this.participant1,
    required this.participant2,
    required this.otherUserId,
    this.lastMessage,
    this.lastMessageAt,
    this.otherFullName,
    this.otherPhotoUrl,
    this.otherUserType,
  });

  final String id;
  final String participant1;
  final String participant2;
  final String otherUserId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? otherFullName;
  final String? otherPhotoUrl;
  final String? otherUserType;

  String get otherDisplayName => otherFullName?.trim().isNotEmpty == true
      ? otherFullName!
      : 'User';

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
    Map<String, dynamic>? otherProfile,
  }) {
    final participant1 = json['participant_1'] as String;
    final participant2 = json['participant_2'] as String;
    final otherUserId =
        participant1 == currentUserId ? participant2 : participant1;
    return Conversation(
      id: json['id'] as String,
      participant1: participant1,
      participant2: participant2,
      otherUserId: otherUserId,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      otherFullName: otherProfile?['full_name'] as String?,
      otherPhotoUrl: otherProfile?['photo_url'] as String?,
      otherUserType: otherProfile?['user_type'] as String?,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool read;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
