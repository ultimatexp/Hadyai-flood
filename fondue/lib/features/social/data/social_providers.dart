import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/reaction.dart';
import '../domain/feed_post.dart';
import '../domain/story.dart';
import '../domain/user_stats.dart';

final _supabase = Supabase.instance.client;

// ============================================================
// REACTIONS
// ============================================================

/// Toggle a reaction on an entity. Returns true if added, false if removed.
Future<bool> toggleReaction({
  required ReactableEntityType entityType,
  required String entityId,
  required ReactionType reactionType,
}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated');

  // Check if reaction exists
  final existing = await _supabase
      .from('post_reactions')
      .select('id')
      .eq('user_id', userId)
      .eq('entity_type', entityType.value)
      .eq('entity_id', entityId)
      .eq('reaction_type', reactionType.name)
      .maybeSingle();

  if (existing != null) {
    // Remove reaction
    await _supabase
        .from('post_reactions')
        .delete()
        .eq('id', existing['id']);
    return false;
  } else {
    // Add reaction
    await _supabase.from('post_reactions').insert({
      'user_id': userId,
      'entity_type': entityType.value,
      'entity_id': entityId,
      'reaction_type': reactionType.name,
    });
    return true;
  }
}

/// Get reaction counts for an entity
Future<ReactionCounts> getReactionCounts(ReactableEntityType entityType, String entityId) async {
  final rows = await _supabase
      .from('post_reactions')
      .select('reaction_type')
      .eq('entity_type', entityType.value)
      .eq('entity_id', entityId);

  int heart = 0, pray = 0, strong = 0, sad = 0, celebrate = 0;
  for (final row in rows) {
    switch (row['reaction_type']) {
      case 'heart': heart++;
      case 'pray': pray++;
      case 'strong': strong++;
      case 'sad': sad++;
      case 'celebrate': celebrate++;
    }
  }
  return ReactionCounts(heart: heart, pray: pray, strong: strong, sad: sad, celebrate: celebrate);
}

/// Get user's reactions on an entity
Future<Set<ReactionType>> getMyReactions(ReactableEntityType entityType, String entityId) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return {};

  final rows = await _supabase
      .from('post_reactions')
      .select('reaction_type')
      .eq('user_id', userId)
      .eq('entity_type', entityType.value)
      .eq('entity_id', entityId);

  return rows.map<ReactionType>((r) => 
    ReactionType.values.firstWhere((e) => e.name == r['reaction_type'])
  ).toSet();
}

// ============================================================
// FEED POSTS
// ============================================================

/// Fetch feed posts with pagination
Future<List<FeedPost>> fetchFeedPosts({int limit = 20, int offset = 0}) async {
  final userId = _supabase.auth.currentUser?.id;

  final rows = await _supabase
      .from('feed_posts')
      .select('*')
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);

  final posts = <FeedPost>[];
  for (final row in rows) {
    Set<ReactionType> myReacts = {};
    if (userId != null) {
      final reactRows = await _supabase
          .from('post_reactions')
          .select('reaction_type')
          .eq('user_id', userId)
          .eq('entity_type', 'feed_post')
          .eq('entity_id', row['id']);
      myReacts = reactRows.map<ReactionType>((r) =>
        ReactionType.values.firstWhere((e) => e.name == r['reaction_type'])
      ).toSet();
    }
    posts.add(FeedPost.fromJson(row, myReactions: myReacts));
  }
  return posts;
}

/// Auto-generate a feed post from a pet report
Future<void> createPetReportFeedPost({
  required String petId,
  required String title,
  required String status,
  String? imageUrl,
  String? body,
}) async {
  final userId = _supabase.auth.currentUser?.id;
  final postType = status == 'REUNITED' ? 'reunion' : 'pet_report';

  await _supabase.from('feed_posts').insert({
    'post_type': postType,
    'title': title,
    'body': body,
    'image_url': imageUrl,
    'entity_type': 'pet',
    'entity_id': petId,
    'user_id': userId,
    'metadata': {'status': status},
  });
}

// ============================================================
// STORIES
// ============================================================

/// Fetch active stories grouped by user
Future<List<StoryGroup>> fetchActiveStories() async {
  final rows = await _supabase
      .from('stories')
      .select('*')
      .gt('expires_at', DateTime.now().toIso8601String())
      .order('created_at', ascending: false);

  final stories = rows.map<Story>((r) => Story.fromJson(r)).toList();

  // Group by user
  final Map<String, List<Story>> grouped = {};
  for (final s in stories) {
    grouped.putIfAbsent(s.userId, () => []).add(s);
  }

  return grouped.entries.map((e) => StoryGroup(
    userId: e.key,
    userName: e.value.first.userName,
    userAvatar: e.value.first.userAvatar,
    primaryType: e.value.first.storyType,
    stories: e.value,
  )).toList();
}

/// Create a new story
Future<void> createStory({
  required String mediaUrl,
  String? caption,
  required StoryType type,
  String? entityId,
}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated');

  await _supabase.from('stories').insert({
    'user_id': userId,
    'media_url': mediaUrl,
    'caption': caption,
    'story_type': type.value,
    'entity_id': entityId,
  });
}

/// Record a story view
Future<void> viewStory(String storyId) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return;

  await _supabase.from('story_views').upsert({
    'story_id': storyId,
    'viewer_id': userId,
  }, onConflict: 'story_id,viewer_id');

  // Increment view count
  await _supabase.rpc('increment_story_views', params: {'p_story_id': storyId}).catchError((_) {});
}

// ============================================================
// USER STATS & GAMIFICATION
// ============================================================

/// Fetch user stats, streaks, and badges
Future<UserStats> fetchUserStats(String userId) async {
  // Fetch all in parallel
  final Future<Map<String, dynamic>?> statsFuture = _supabase
      .from('user_stats')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
  final Future<Map<String, dynamic>?> streakFuture = _supabase
      .from('user_streaks')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
  final Future<List<Map<String, dynamic>>> badgesFuture = _supabase
      .from('user_badges')
      .select()
      .eq('user_id', userId);

  final statsResult = await statsFuture;
  final streakResult = await streakFuture;
  final badgesResult = await badgesFuture;

  if (statsResult == null) {
    // Auto-create
    await _supabase.from('user_stats').insert({'user_id': userId});
    await _supabase.from('user_streaks').insert({'user_id': userId});
    return UserStats(userId: userId);
  }

  return UserStats.fromJson(
    statsResult,
    streakJson: streakResult,
    badgesJson: badgesResult.cast<Map<String, dynamic>>(),
  );
}

/// Increment a stat and check for badge unlocks
Future<List<BadgeType>> incrementStat(String statField, {int amount = 1}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return [];

  // Update the stat
  final current = await _supabase
      .from('user_stats')
      .select(statField)
      .eq('user_id', userId)
      .single();

  final newVal = ((current[statField] as num?)?.toInt() ?? 0) + amount;
  await _supabase
      .from('user_stats')
      .update({statField: newVal, 'updated_at': DateTime.now().toIso8601String()})
      .eq('user_id', userId);

  // Check and award badges
  return _checkBadges(userId);
}

/// Update daily streak
Future<int> updateStreak() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return 0;

  final streak = await _supabase
      .from('user_streaks')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  if (streak == null) {
    await _supabase.from('user_streaks').insert({
      'user_id': userId,
      'current_streak': 1,
      'longest_streak': 1,
      'last_active_date': todayStr,
    });
    return 1;
  }

  final lastActive = DateTime.tryParse(streak['last_active_date'] ?? '');
  if (lastActive == null) return 0;

  final diff = today.difference(lastActive).inDays;
  int currentStreak = (streak['current_streak'] as num?)?.toInt() ?? 0;

  if (diff == 0) {
    // Already active today
    return currentStreak;
  } else if (diff == 1) {
    // Consecutive day
    currentStreak++;
  } else {
    // Streak broken
    currentStreak = 1;
  }

  final longestStreak = (streak['longest_streak'] as num?)?.toInt() ?? 0;
  await _supabase.from('user_streaks').update({
    'current_streak': currentStreak,
    'longest_streak': currentStreak > longestStreak ? currentStreak : longestStreak,
    'last_active_date': todayStr,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('user_id', userId);

  return currentStreak;
}

/// Check and award badges
Future<List<BadgeType>> _checkBadges(String userId) async {
  final stats = await fetchUserStats(userId);
  final existingBadges = stats.badges.map((b) => b.badgeType).toSet();
  final newBadges = <BadgeType>[];

  final checks = {
    BadgeType.starter: stats.petsReported >= 1,
    BadgeType.protector: stats.petsReported >= 5,
    BadgeType.hero: stats.petsHelped >= 10,
    BadgeType.streak: stats.currentStreak >= 7,
    BadgeType.sharer: stats.sharesCount >= 10,
    BadgeType.legend: stats.totalPoints >= 1500,
  };

  for (final entry in checks.entries) {
    if (entry.value && !existingBadges.contains(entry.key)) {
      await _supabase.from('user_badges').insert({
        'user_id': userId,
        'badge_type': entry.key.name,
      });
      newBadges.add(entry.key);
    }
  }

  // Update level based on points
  final newLevel = UserLevel.values.lastWhere(
    (l) => stats.totalPoints >= l.requiredPoints,
    orElse: () => UserLevel.beginner,
  );
  if (newLevel != stats.level) {
    await _supabase.from('user_stats').update({
      'level': newLevel.name,
    }).eq('user_id', userId);
  }

  return newBadges;
}

// ============================================================
// RIVERPOD PROVIDERS
// ============================================================

/// Feed posts provider with pagination
final feedPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) async {
  return fetchFeedPosts();
});

/// Active stories provider
final activeStoriesProvider = FutureProvider.autoDispose<List<StoryGroup>>((ref) async {
  return fetchActiveStories();
});

/// User stats provider (for current user)
final currentUserStatsProvider = FutureProvider.autoDispose<UserStats?>((ref) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return null;
  return fetchUserStats(userId);
});

/// Reaction counts for an entity
final reactionCountsProvider = FutureProvider.autoDispose.family<ReactionCounts, (ReactableEntityType, String)>((ref, args) async {
  final (entityType, entityId) = args;
  final rows = await _supabase
      .from('post_reactions')
      .select('reaction_type')
      .eq('entity_type', entityType.value)
      .eq('entity_id', entityId);

  int heart = 0, pray = 0, strong = 0, sad = 0, celebrate = 0;
  for (final row in rows) {
    switch (row['reaction_type']) {
      case 'heart': heart++;
      case 'pray': pray++;
      case 'strong': strong++;
      case 'sad': sad++;
      case 'celebrate': celebrate++;
    }
  }
  return ReactionCounts(heart: heart, pray: pray, strong: strong, sad: sad, celebrate: celebrate);
});

/// My reactions for an entity
final myReactionsProvider = FutureProvider.autoDispose.family<Set<ReactionType>, (ReactableEntityType, String)>((ref, args) async {
  final (entityType, entityId) = args;
  return getMyReactions(entityType, entityId);
});

/// User stats provider for any user
final userStatsProvider = FutureProvider.autoDispose.family<UserStats, String>((ref, userId) async {
  return fetchUserStats(userId);
});

// ============================================================
// USER POSTS (for profile page)
// ============================================================

/// Fetch posts by a specific user
Future<List<FeedPost>> fetchUserPosts(String userId, {int limit = 50}) async {
  final currentUserId = _supabase.auth.currentUser?.id;

  final rows = await _supabase
      .from('feed_posts')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(limit);

  final posts = <FeedPost>[];
  for (final row in rows) {
    Set<ReactionType> myReacts = {};
    if (currentUserId != null) {
      final reactRows = await _supabase
          .from('post_reactions')
          .select('reaction_type')
          .eq('user_id', currentUserId)
          .eq('entity_type', 'feed_post')
          .eq('entity_id', row['id']);
      myReacts = reactRows.map<ReactionType>((r) =>
        ReactionType.values.firstWhere((e) => e.name == r['reaction_type'])
      ).toSet();
    }
    posts.add(FeedPost.fromJson(row, myReactions: myReacts));
  }
  return posts;
}

/// User posts provider for profile page
final userPostsProvider = FutureProvider.autoDispose.family<List<FeedPost>, String>((ref, userId) async {
  return fetchUserPosts(userId);
});
