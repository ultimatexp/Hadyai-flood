import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/moderation_repository.dart';
import '../../pets/presentation/pet_providers.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(Supabase.instance.client);
});

final blockedProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final blockedIds = await ref.watch(blockedUsersProvider.future);
  
  if (blockedIds.isEmpty) return [];
  
  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .inFilter('id', blockedIds);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    // If profiles fetch fails, return empty or handle error
    return [];
  }
});
