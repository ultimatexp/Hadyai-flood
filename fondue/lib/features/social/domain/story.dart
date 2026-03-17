enum StoryType {
  user,
  shelter,
  petUpdate('pet_update'),
  reunion,
  alert;

  final String? _value;
  const StoryType([this._value]);
  String get value => _value ?? name;

  String get ringColor {
    return switch (this) {
      StoryType.user => '#4CAF50',
      StoryType.shelter => '#FF9800',
      StoryType.petUpdate => '#2196F3',
      StoryType.reunion => '#FFD700',
      StoryType.alert => '#EF5350',
    };
  }
}

class Story {
  final String id;
  final String userId;
  final String mediaUrl;
  final String? caption;
  final StoryType storyType;
  final String? entityId;
  final DateTime expiresAt;
  final int viewCount;
  final DateTime createdAt;
  // Joined
  final String? userName;
  final String? userAvatar;

  Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    this.caption,
    required this.storyType,
    this.entityId,
    required this.expiresAt,
    this.viewCount = 0,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: json['media_url'] as String,
      caption: json['caption'] as String?,
      storyType: StoryType.values.firstWhere(
        (e) => e.value == json['story_type'],
        orElse: () => StoryType.user,
      ),
      entityId: json['entity_id'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
    );
  }
}

/// Grouped stories by user for the stories bar
class StoryGroup {
  final String userId;
  final String? userName;
  final String? userAvatar;
  final StoryType primaryType;
  final List<Story> stories;
  final bool hasUnviewed;

  StoryGroup({
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.primaryType,
    required this.stories,
    this.hasUnviewed = true,
  });
}
