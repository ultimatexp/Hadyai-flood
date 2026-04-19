import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/chat/presentation/chat_detail_screen.dart';

/// Navigator key for [MaterialApp]; required for navigation from push handlers.
final GlobalKey<NavigatorState> fondueNavigatorKey = GlobalKey<NavigatorState>();

const String kPushChatMessageType = 'CHAT_MESSAGE';

bool isChatPushPayload(Map<String, dynamic> data) {
  final type = data['type']?.toString();
  final conversationId = data['conversation_id']?.toString();
  return type == kPushChatMessageType &&
      conversationId != null &&
      conversationId.isNotEmpty;
}

/// Opens [ChatDetailScreen] for a chat notification (FCM `data` from the Edge Function).
Future<void> openChatFromPushData(Map<String, dynamic> data) async {
  if (!isChatPushPayload(data)) return;

  final conversationId = data['conversation_id']!.toString();
  final senderId = data['sender_id']?.toString();

  String name = 'Chat';
  String avatar = 'https://i.pravatar.cc/150?u=${senderId ?? conversationId}';

  if (senderId != null) {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', senderId)
          .maybeSingle();
      if (row != null) {
        final fullName = row['full_name'] as String?;
        if (fullName != null && fullName.trim().isNotEmpty) {
          name = fullName.trim();
        }
        final avatarUrl = row['avatar_url'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          avatar = avatarUrl;
        }
      }
    } catch (_) {
      // Keep placeholders
    }
  }

  final nav = fondueNavigatorKey.currentState;
  if (nav == null) return;

  if (!nav.mounted) return;

  await nav.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ChatDetailScreen(
        conversationId: conversationId,
        name: name,
        avatar: avatar,
        otherUserId: senderId,
      ),
    ),
  );
}
