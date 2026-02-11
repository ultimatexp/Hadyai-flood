import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      // 1. Fetch unread counts efficiently
      final unreadCounts = await _client.rpc('get_unread_conversation_counts');
      final unreadMap = {
        for (var row in (unreadCounts as List)) 
          row['conversation_id'] as String: row['unread_count'] as int
      };

      // 2. Get conversations
      final response = await _client
          .from('conversation_participants')
          .select('''
            conversation_id,
            last_read_at,
            conversations!inner (
              id,
              created_at,
              updated_at,
              pet_id,
              last_message,
              last_message_at
            )
          ''')
          .eq('user_id', userId)
          .order('conversations(last_message_at)', ascending: false);

      final List<Conversation> conversations = [];

      for (final row in response) {
        final convoData = row['conversations'] as Map<String, dynamic>;
        final lastReadAt = row['last_read_at'] != null
            ? DateTime.parse(row['last_read_at'] as String)
            : null;
        final conversationId = convoData['id'] as String;

        // Get other participant info using RPC to bypass RLS
        String? otherUserName;
        String? otherUserAvatar;
        String? otherUserId;

        try {
          final otherParticipants = await _client.rpc('get_other_participants', params: {
            'conv_id': conversationId,
            'current_user_id': userId,
          });

          if (otherParticipants != null && otherParticipants.isNotEmpty) {
            final other = otherParticipants[0];
            otherUserId = other['user_id'] as String?;
            otherUserName = other['full_name'] as String? ?? 'User';
            otherUserAvatar = other['avatar_url'] as String?;
          }
        } catch (e) {
          otherUserName = 'User';
        }

        otherUserAvatar ??= 'https://i.pravatar.cc/150?u=$otherUserId';

        conversations.add(Conversation(
          id: conversationId,
          createdAt: DateTime.parse(convoData['created_at'] as String),
          updatedAt: DateTime.parse(convoData['updated_at'] as String),
          petId: convoData['pet_id'] as String?,
          lastMessage: convoData['last_message'] as String?,
          lastMessageAt: convoData['last_message_at'] != null
              ? DateTime.parse(convoData['last_message_at'] as String)
              : null,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserAvatar: otherUserAvatar,
          lastReadAt: lastReadAt,
          unreadCount: unreadMap[conversationId] ?? 0,
        ));
      }

      return conversations;
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => Message.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Stream messages for real-time updates
  Stream<List<Message>> streamMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data
            .where((m) => m['is_deleted'] != true)
            .map((json) => Message.fromJson(json))
            .toList());
  }

  /// Send a message
  Future<Message?> sendMessage({
    required String conversationId,
    String? content,
    String? imageUrl,
    String? replyToId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final response = await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'image_url': imageUrl,
      'reply_to_id': replyToId,
    }).select().single();

    return Message.fromJson(response);
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  /// Create or get existing conversation with another user
  Future<String?> getOrCreateConversation({
    required String otherUserId,
    String? petId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    // Check if conversation exists
    final existingResponse = await _client.rpc('find_existing_conversation', params: {
      'user1': userId,
      'user2': otherUserId,
    });

    if (existingResponse != null && existingResponse.isNotEmpty) {
      return existingResponse[0]['id'] as String;
    }

    // Create new conversation
    final convoResponse = await _client
        .from('conversations')
        .insert({'pet_id': petId})
        .select()
        .single();

    final conversationId = convoResponse['id'] as String;

    // Add both participants
    await _client.from('conversation_participants').insert([
      {'conversation_id': conversationId, 'user_id': userId},
      {'conversation_id': conversationId, 'user_id': otherUserId},
    ]);

    return conversationId;
  }

  /// Get total unread message count
  Future<int> getTotalUnreadCount() async {
    try {
      final count = await _client.rpc('get_total_unread_count');
      return count as int;
    } catch (e) {
      print('Error fetching total unread count: $e');
      return 0;
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client
        .from('messages')
        .update({'is_deleted': true})
        .eq('id', messageId)
        .eq('sender_id', userId);
  }
}
