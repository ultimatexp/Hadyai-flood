import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileRepository {
  final SupabaseClient _client;

  UserProfileRepository(this._client);

  static const String currentTermsVersion = '2026-02-08';

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

  Future<void> acceptTerms() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'terms_accepted': true,
          'terms_version': currentTermsVersion,
          'terms_accepted_at': DateTime.now().toIso8601String(),
        },
      ),
    );
  }
}
