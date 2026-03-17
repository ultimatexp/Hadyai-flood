/// Reaction types matching the database constraint
enum ReactionType {
  heart,
  pray,
  strong,
  sad,
  celebrate;

  String get emoji {
    return switch (this) {
      ReactionType.heart => '❤️',
      ReactionType.pray => '🙏',
      ReactionType.strong => '💪',
      ReactionType.sad => '😢',
      ReactionType.celebrate => '🎉',
    };
  }

  String get label {
    return switch (this) {
      ReactionType.heart => 'Love',
      ReactionType.pray => 'Pray',
      ReactionType.strong => 'Strong',
      ReactionType.sad => 'Sad',
      ReactionType.celebrate => 'Celebrate',
    };
  }
}

/// Entity types that can be reacted to
enum ReactableEntityType {
  pet,
  shelter,
  story,
  feedPost('feed_post');

  final String? _value;
  const ReactableEntityType([this._value]);
  String get value => _value ?? name;
}

class Reaction {
  final String id;
  final String userId;
  final ReactableEntityType entityType;
  final String entityId;
  final ReactionType reactionType;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.reactionType,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      entityType: ReactableEntityType.values.firstWhere(
        (e) => e.value == json['entity_type'],
        orElse: () => ReactableEntityType.pet,
      ),
      entityId: json['entity_id'] as String,
      reactionType: ReactionType.values.firstWhere(
        (e) => e.name == json['reaction_type'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Aggregated reaction counts for display
class ReactionCounts {
  final int heart;
  final int pray;
  final int strong;
  final int sad;
  final int celebrate;

  const ReactionCounts({
    this.heart = 0,
    this.pray = 0,
    this.strong = 0,
    this.sad = 0,
    this.celebrate = 0,
  });

  int get total => heart + pray + strong + sad + celebrate;

  factory ReactionCounts.fromJson(Map<String, dynamic> json) {
    return ReactionCounts(
      heart: (json['heart'] as num?)?.toInt() ?? 0,
      pray: (json['pray'] as num?)?.toInt() ?? 0,
      strong: (json['strong'] as num?)?.toInt() ?? 0,
      sad: (json['sad'] as num?)?.toInt() ?? 0,
      celebrate: (json['celebrate'] as num?)?.toInt() ?? 0,
    );
  }

  int countFor(ReactionType type) {
    return switch (type) {
      ReactionType.heart => heart,
      ReactionType.pray => pray,
      ReactionType.strong => strong,
      ReactionType.sad => sad,
      ReactionType.celebrate => celebrate,
    };
  }
}
