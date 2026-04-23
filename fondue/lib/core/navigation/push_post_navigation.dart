import 'package:flutter/material.dart';

import 'push_chat_navigation.dart';
import '../../features/social/presentation/feed_screen.dart';

const String kPushPostType = 'POST_ACTIVITY';

bool isPostPushPayload(Map<String, dynamic> data) {
  final type = data['type']?.toString();
  final postId = data['post_id']?.toString();
  return type == kPushPostType && postId != null && postId.isNotEmpty;
}

Future<void> openPostFromPushData(Map<String, dynamic> data) async {
  if (!isPostPushPayload(data)) return;
  final nav = fondueNavigatorKey.currentState;
  if (nav == null || !nav.mounted) return;
  await nav.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const FeedScreen(),
    ),
  );
}
