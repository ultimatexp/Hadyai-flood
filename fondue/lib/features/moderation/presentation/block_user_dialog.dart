import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/moderation_providers.dart';
import '../../pets/presentation/pet_providers.dart';
import '../../social/data/social_providers.dart';

class BlockUserDialog {
  /// Show block confirmation dialog. Returns true if user was blocked.
  static Future<bool?> show(
    BuildContext context,
    WidgetRef ref, {
    required String blockedUserId,
    required String blockedUserName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block "$blockedUserName"?\n\n'
          'You will no longer see their posts or receive messages from them. '
          'They will not be notified that you blocked them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      final repo = ref.read(moderationRepositoryProvider);
      await repo.blockUser(
        blockerId: user.id,
        blockedId: blockedUserId,
        reasonForDeveloper: 'User blocked from UI (possible abusive behavior).',
      );

      // Refresh blocked users list and pet feed
      ref.invalidate(blockedUsersProvider);
      ref.invalidate(lostPetsProvider);
      ref.invalidate(feedPostsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$blockedUserName has been blocked'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await repo.unblockUser(
                  blockerId: user.id,
                  blockedId: blockedUserId,
                );
                ref.invalidate(blockedUsersProvider);
                ref.invalidate(lostPetsProvider);
                ref.invalidate(feedPostsProvider);
              },
            ),
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: $e')),
        );
      }
      return false;
    }
  }
}
