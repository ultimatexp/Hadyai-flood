import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_providers.dart';
import '../domain/conversation.dart';
import 'chat_detail_screen.dart';

/// Chat list screen showing all conversations
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: const [],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a chat by contacting a pet owner',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final convo = conversations[index];
                return _buildConversationTile(context, ref, convo);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error loading chats', style: TextStyle(color: Colors.grey[600])),
              TextButton(
                onPressed: () => ref.invalidate(conversationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, WidgetRef ref, Conversation convo) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: convo.id,
              name: convo.otherUserName ?? 'User',
              avatar: convo.otherUserAvatar ?? 'https://i.pravatar.cc/150?u=${convo.otherUserId}',
            ),
          ),
        ).then((_) {
          // Refresh conversations when returning
          ref.invalidate(conversationsProvider);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    convo.otherUserAvatar ?? 'https://i.pravatar.cc/150?u=${convo.otherUserId}',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    convo.otherUserName ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    convo.lastMessage ?? 'No messages yet',
                    style: TextStyle(
                      color: convo.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: convo.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Time and unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(convo.lastMessageAt),
                  style: TextStyle(
                    color: convo.unreadCount > 0 ? const Color(0xFFFF9800) : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                if (convo.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${convo.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localTime);
    
    if (diff.inDays == 0) {
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[localTime.weekday - 1];
    } else {
      return '${localTime.day}/${localTime.month}';
    }
  }
}
