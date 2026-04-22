import 'package:supabase_flutter/supabase_flutter.dart';

class ModerationRepository {
  final SupabaseClient _client;

  ModerationRepository(this._client);

  /// Report content (pet listing or user)
  Future<void> reportContent({
    required String reporterId,
    String? reportedUserId,
    required String entityId,
    required String entityType,
    required String reason,
    String? details,
  }) async {
    await _client.from('reports').insert({
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'entity_id': entityId,
      'entity_type': entityType,
      'reason': reason,
      'details': details,
      'status': 'pending',
    });
  }

  /// Block a user
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
    String? reasonForDeveloper,
  }) async {
    await _client.from('blocked_users').upsert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });

    // Guideline 1.2: blocking should also notify the developer.
    // We record it as a "report" so it shows up in the moderation queue.
    await _client.from('reports').insert({
      'reporter_id': blockerId,
      'reported_user_id': blockedId,
      'entity_id': blockedId,
      'entity_type': 'user',
      'reason': 'Blocked user',
      'details': reasonForDeveloper,
      'status': 'pending',
    });
  }

  /// Unblock a user
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _client
        .from('blocked_users')
        .delete()
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId);
  }

  /// Get list of blocked user IDs
  Future<List<String>> getBlockedUserIds(String userId) async {
    final result = await _client
        .from('blocked_users')
        .select('blocked_id')
        .eq('blocker_id', userId);

    if (result == null) return [];
    return (result as List)
        .map((row) => row['blocked_id'] as String)
        .toList();
  }
}
