import 'reaction.dart';

enum FeedPostType {
  petReport('pet_report'),
  reunion('reunion'),
  shelterUpdate('shelter_update'),
  milestone('milestone'),
  story('story');

  final String value;
  const FeedPostType(this.value);

  String get icon {
    return switch (this) {
      FeedPostType.petReport => '🐾',
      FeedPostType.reunion => '🎉',
      FeedPostType.shelterUpdate => '🏠',
      FeedPostType.milestone => '🏆',
      FeedPostType.story => '📖',
    };
  }

  String get label {
    return switch (this) {
      FeedPostType.petReport => 'Pet Report',
      FeedPostType.reunion => 'Reunion!',
      FeedPostType.shelterUpdate => 'Shelter Update',
      FeedPostType.milestone => 'Milestone',
      FeedPostType.story => 'Story',
    };
  }
}

class FeedPost {
  final String id;
  final FeedPostType postType;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? entityType;
  final String? entityId;
  final String? userId;
  final Map<String, dynamic> metadata;
  final ReactionCounts reactionCounts;
  final int commentCount;
  final DateTime createdAt;
  // Joined data
  final String? authorName;
  final String? authorAvatar;
  // User's own reactions
  final Set<ReactionType> myReactions;

  FeedPost({
    required this.id,
    required this.postType,
    required this.title,
    this.body,
    this.imageUrl,
    this.entityType,
    this.entityId,
    this.userId,
    this.metadata = const {},
    this.reactionCounts = const ReactionCounts(),
    this.commentCount = 0,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.myReactions = const {},
  });

  factory FeedPost.fromJson(Map<String, dynamic> json, {Set<ReactionType>? myReactions}) {
    final type = FeedPostType.values.firstWhere(
      (e) => e.value == json['post_type'],
      orElse: () => FeedPostType.petReport,
    );

    final rcJson = json['reaction_counts'];
    final rc = rcJson is Map<String, dynamic> 
        ? ReactionCounts.fromJson(rcJson)
        : const ReactionCounts();

    return FeedPost(
      id: json['id'] as String,
      postType: type,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      userId: json['user_id'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      reactionCounts: rc,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: json['author_name'] as String?,
      authorAvatar: json['author_avatar'] as String?,
      myReactions: myReactions ?? {},
    );
  }

  FeedPost copyWith({
    ReactionCounts? reactionCounts,
    Set<ReactionType>? myReactions,
    int? commentCount,
  }) {
    return FeedPost(
      id: id,
      postType: postType,
      title: title,
      body: body,
      imageUrl: imageUrl,
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      metadata: metadata,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      authorName: authorName,
      authorAvatar: authorAvatar,
      myReactions: myReactions ?? this.myReactions,
    );
  }
}
