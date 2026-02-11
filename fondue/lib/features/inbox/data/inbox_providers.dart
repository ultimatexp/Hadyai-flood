
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
