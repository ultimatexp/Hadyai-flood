/// Represents a chat message
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final String? replyToId;
  final DateTime createdAt;
  final bool isDeleted;
  
  // Computed
  final Message? replyTo;
  final String? senderName;
  final String? senderAvatar;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.replyToId,
    required this.createdAt,
    this.isDeleted = false,
    this.replyTo,
    this.senderName,
    this.senderAvatar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      replyToId: json['reply_to_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'image_url': imageUrl,
      'reply_to_id': replyToId,
    };
  }
}
