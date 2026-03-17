enum UserLevel {
  beginner,
  bronze,
  silver,
  gold,
  legend;

  String get thaiLabel {
    return switch (this) {
      UserLevel.beginner => 'มือใหม่',
      UserLevel.bronze => 'บรอนซ์',
      UserLevel.silver => 'ซิลเวอร์',
      UserLevel.gold => 'โกลด์',
      UserLevel.legend => 'ตำนาน',
    };
  }

  String get emoji {
    return switch (this) {
      UserLevel.beginner => '🌱',
      UserLevel.bronze => '🥉',
      UserLevel.silver => '🥈',
      UserLevel.gold => '🥇',
      UserLevel.legend => '👑',
    };
  }

  int get requiredPoints {
    return switch (this) {
      UserLevel.beginner => 0,
      UserLevel.bronze => 100,
      UserLevel.silver => 300,
      UserLevel.gold => 700,
      UserLevel.legend => 1500,
    };
  }
}

enum BadgeType {
  starter,
  protector,
  hero,
  streak,
  sharer,
  legend;

  String get emoji {
    return switch (this) {
      BadgeType.starter => '🌟',
      BadgeType.protector => '🐾',
      BadgeType.hero => '💪',
      BadgeType.streak => '🔥',
      BadgeType.sharer => '💎',
      BadgeType.legend => '👑',
    };
  }

  String get thaiLabel {
    return switch (this) {
      BadgeType.starter => 'ผู้เริ่มต้น',
      BadgeType.protector => 'ผู้พิทักษ์สัตว์',
      BadgeType.hero => 'ฮีโร่ชุมชน',
      BadgeType.streak => 'Active Streak',
      BadgeType.sharer => 'ผู้แชร์',
      BadgeType.legend => 'ตำนาน',
    };
  }

  String get description {
    return switch (this) {
      BadgeType.starter => 'รายงานสัตว์ครั้งแรก',
      BadgeType.protector => 'รายงานสัตว์ 5 ครั้ง',
      BadgeType.hero => 'ช่วยเหลือ 10 ครั้ง',
      BadgeType.streak => 'ใช้งาน 7 วันติด',
      BadgeType.sharer => 'แชร์ 10 โพสต์',
      BadgeType.legend => 'สะสม 1500 แต้ม',
    };
  }
}

class UserBadge {
  final String id;
  final String userId;
  final BadgeType badgeType;
  final DateTime earnedAt;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeType: BadgeType.values.firstWhere(
        (e) => e.name == json['badge_type'],
        orElse: () => BadgeType.starter,
      ),
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}

class UserStats {
  final String userId;
  final int totalPoints;
  final int petsReported;
  final int petsHelped;
  final int reactionsReceived;
  final int sharesCount;
  final UserLevel level;
  final int currentStreak;
  final int longestStreak;
  final List<UserBadge> badges;

  UserStats({
    required this.userId,
    this.totalPoints = 0,
    this.petsReported = 0,
    this.petsHelped = 0,
    this.reactionsReceived = 0,
    this.sharesCount = 0,
    this.level = UserLevel.beginner,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
  });

  double get progressToNextLevel {
    final currentReq = level.requiredPoints;
    final nextIdx = UserLevel.values.indexOf(level) + 1;
    if (nextIdx >= UserLevel.values.length) return 1.0;
    final nextReq = UserLevel.values[nextIdx].requiredPoints;
    return ((totalPoints - currentReq) / (nextReq - currentReq)).clamp(0.0, 1.0);
  }

  factory UserStats.fromJson(
    Map<String, dynamic> statsJson, {
    Map<String, dynamic>? streakJson,
    List<Map<String, dynamic>>? badgesJson,
  }) {
    return UserStats(
      userId: statsJson['user_id'] as String,
      totalPoints: (statsJson['total_points'] as num?)?.toInt() ?? 0,
      petsReported: (statsJson['pets_reported'] as num?)?.toInt() ?? 0,
      petsHelped: (statsJson['pets_helped'] as num?)?.toInt() ?? 0,
      reactionsReceived: (statsJson['reactions_received'] as num?)?.toInt() ?? 0,
      sharesCount: (statsJson['shares_count'] as num?)?.toInt() ?? 0,
      level: UserLevel.values.firstWhere(
        (e) => e.name == (statsJson['level'] as String? ?? 'beginner'),
        orElse: () => UserLevel.beginner,
      ),
      currentStreak: (streakJson?['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (streakJson?['longest_streak'] as num?)?.toInt() ?? 0,
      badges: (badgesJson ?? []).map((j) => UserBadge.fromJson(j)).toList(),
    );
  }
}
