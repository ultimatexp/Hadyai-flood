import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/moderation_providers.dart';
import '../../pets/presentation/pet_providers.dart'; 

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedProfilesAsync = ref.watch(blockedProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: blockedProfilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.block, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   Text(
                    'No blocked users',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final userId = profile['id'] as String;
              final name = profile['full_name'] as String? ?? 'Unknown User';
              final avatarUrl = profile['avatar_url'] as String?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  backgroundColor: Colors.grey[200],
                  child: avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: TextButton(
                  onPressed: () async {
                    _unblockUser(context, ref, userId, name);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Future<void> _unblockUser(BuildContext context, WidgetRef ref, String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(moderationRepositoryProvider);
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) return;

        await repo.unblockUser(
          blockerId: currentUser.id,
          blockedId: userId,
        );
        
        // Invalidate blockedUsersProvider to refresh the list
        // This will propagate to blockedProfilesProvider
        ref.invalidate(blockedUsersProvider);
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error unblocking user: $e')),
          );
        }
      }
    }
  }
}
