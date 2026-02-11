/// Represents a chat conversation
class Conversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? petId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  
  // Joined from conversation_participants
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final DateTime? lastReadAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.petId,
    this.lastMessage,
    this.lastMessageAt,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.lastReadAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      petId: json['pet_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String) 
          : null,
      otherUserId: json['other_user_id'] as String?,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
