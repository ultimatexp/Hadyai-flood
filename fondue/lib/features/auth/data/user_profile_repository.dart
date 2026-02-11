import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileRepository {
  final SupabaseClient _client;

  UserProfileRepository(this._client);

  Future<void> updateProfile({
    String? name,
    String? contactInfo,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{};
    if (name != null) updates['full_name'] = name;
    if (contactInfo != null) updates['contact_info'] = contactInfo;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _client.auth.updateUser(
        UserAttributes(
          data: updates,
        ),
      );
    }
  }

  Future<void> completeOnboarding() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.auth.updateUser(
      UserAttributes(
        data: {'onboarding_completed': true},
      ),
    );
  }
}
