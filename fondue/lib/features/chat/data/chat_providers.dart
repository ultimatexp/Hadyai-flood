import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_repository.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

// Conversations list provider
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  // Watch for changes in unread count to trigger a refresh
  ref.watch(unreadMessagesCountProvider);
  
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getConversations();
});

// Messages stream provider for a specific conversation
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamMessages(conversationId);
});

// Total unread message count provider
final unreadMessagesCountProvider = StreamProvider<int>((ref) async* {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    yield 0;
    return;
  }

  // Initial count
  final repo = ref.watch(chatRepositoryProvider);
  yield await repo.getTotalUnreadCount();

  // Listen to message changes for real-time updates
  // We stream all messages to ensure we catch everything, as RLS might filter
  // but we need to know when ANY message changes to re-check the count
  final stream = Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id']);

  await for (final _ in stream) {
    // When any message changes (new message, or message read/deleted),
    // re-fetch the total unread count from the server
    yield await repo.getTotalUnreadCount();
  }
});

// Unread notifications count (for inbox)
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  // This can be connected to a notifications table later
  return Stream.value(0);
});
