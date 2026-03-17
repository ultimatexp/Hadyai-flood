import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Notification model for Activity Feed
class ActivityItem {
  final String id;
  final String type;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? entityId;
  final bool isRead;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.imageUrl,
    this.entityId,
    this.isRead = false,
    required this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      entityId: json['entity_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  IconData get icon {
    return switch (type) {
      'reaction' => Icons.favorite,
      'comment' => Icons.chat_bubble,
      'match' => Icons.pets,
      'badge' => Icons.emoji_events,
      'reunion' => Icons.celebration,
      'chat' => Icons.message,
      'system' => Icons.info_outline,
      _ => Icons.notifications,
    };
  }

  Color get color {
    return switch (type) {
      'reaction' => Colors.red,
      'comment' => Colors.blue,
      'match' => Colors.orange,
      'badge' => Colors.amber,
      'reunion' => Colors.green,
      'chat' => Colors.purple,
      'system' => Colors.grey,
      _ => Colors.grey,
    };
  }
}

/// Provider for activity feed
final activityFeedProvider = FutureProvider.autoDispose<List<ActivityItem>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final rows = await Supabase.instance.client
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);

  return rows.map<ActivityItem>((r) => ActivityItem.fromJson(r)).toList();
});

/// Instagram-style activity feed (grouped by time)
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('กิจกรรม'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activityFeedProvider),
        color: const Color(0xFFFF9800),
        child: activityAsync.when(
          data: (items) {
            if (items.isEmpty) return _buildEmptyState();

            // Group by time
            final today = <ActivityItem>[];
            final thisWeek = <ActivityItem>[];
            final earlier = <ActivityItem>[];
            final now = DateTime.now();

            for (final item in items) {
              final diff = now.difference(item.createdAt).inDays;
              if (diff == 0) {
                today.add(item);
              } else if (diff < 7) {
                thisWeek.add(item);
              } else {
                earlier.add(item);
              }
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (today.isNotEmpty) ...[
                  _SectionHeader(title: 'วันนี้'),
                  ...today.map((item) => _ActivityCard(item: item)),
                ],
                if (thisWeek.isNotEmpty) ...[
                  _SectionHeader(title: 'สัปดาห์นี้'),
                  ...thisWeek.map((item) => _ActivityCard(item: item)),
                ],
                if (earlier.isNotEmpty) ...[
                  _SectionHeader(title: 'ก่อนหน้า'),
                  ...earlier.map((item) => _ActivityCard(item: item)),
                ],
              ],
            );
          },
          loading: () => ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) => ListTile(
              leading: Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200])),
              title: Container(width: 160, height: 14, color: Colors.grey[200]),
              subtitle: Container(width: 80, height: 10, color: Colors.grey[200]),
            ),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('ไม่สามารถโหลดกิจกรรม', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, size: 48, color: Color(0xFFFF9800)),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีการแจ้งเตือน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'กิจกรรมของคุณจะปรากฏที่นี่',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.isRead ? Colors.transparent : Colors.orange.withOpacity(0.04),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 24),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _timeAgo(item.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        trailing: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              )
            : null,
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'ตอนนี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาที';
    if (diff.inHours < 24) return '${diff.inHours} ชม.';
    if (diff.inDays < 7) return '${diff.inDays} วัน';
    return '${diff.inDays ~/ 7} สัปดาห์';
  }
}
