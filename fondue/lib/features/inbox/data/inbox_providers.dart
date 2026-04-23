
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inbox_repository.dart';
import '../domain/notification.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(Supabase.instance.client);
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repository = ref.watch(inboxRepositoryProvider);
  return repository.fetchNotifications();
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) async* {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    yield 0;
    return;
  }

  final repo = ref.watch(inboxRepositoryProvider);
  yield await repo.getUnreadCount();

  final stream = Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id']);

  await for (final _ in stream) {
    yield await repo.getUnreadCount();
  }
});
