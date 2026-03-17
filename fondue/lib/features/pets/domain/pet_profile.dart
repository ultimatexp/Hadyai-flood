class PetProfile {
  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final DateTime? birthday;
  final double? weightKg;
  final String? bodySize;
  final String? furLength;
  final String? colorMain;
  final String? colorSecondary;
  final String? eyeColor;
  final String? microchipNumber;
  final List<String> personalityTraits;
  final String? bio;
  final String? avatarUrl;
  final List<String> images;
  final bool isNeutered;
  final List<String> allergies;
  final List<String> conditions;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.birthday,
    this.weightKg,
    this.bodySize,
    this.furLength,
    this.colorMain,
    this.colorSecondary,
    this.eyeColor,
    this.microchipNumber,
    this.personalityTraits = const [],
    this.bio,
    this.avatarUrl,
    this.images = const [],
    this.isNeutered = false,
    this.allergies = const [],
    this.conditions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate age from birthday
  String get ageText {
    if (birthday == null) return 'Unknown';
    final now = DateTime.now();
    final years = now.year - birthday!.year;
    final months = now.month - birthday!.month;
    final adjustedMonths = months < 0 ? months + 12 : months;
    final adjustedYears = months < 0 ? years - 1 : years;

    if (adjustedYears > 0) {
      return adjustedMonths > 0
          ? '$adjustedYears yr${adjustedYears > 1 ? 's' : ''} $adjustedMonths mo'
          : '$adjustedYears yr${adjustedYears > 1 ? 's' : ''}';
    }
    return '$adjustedMonths mo';
  }

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      species: json['species'] as String? ?? 'Dog',
      breed: json['breed'] as String?,
      sex: json['sex'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'] as String)
          : null,
      weightKg: _parseDouble(json['weight_kg']),
      bodySize: json['body_size'] as String?,
      furLength: json['fur_length'] as String?,
      colorMain: json['color_main'] as String?,
      colorSecondary: json['color_secondary'] as String?,
      eyeColor: json['eye_color'] as String?,
      microchipNumber: json['microchip_number'] as String?,
      personalityTraits: _parseStringList(json['personality_traits']),
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      images: _parseStringArray(json['images']),
      isNeutered: json['is_neutered'] as bool? ?? false,
      allergies: _parseStringArray(json['allergies']),
      conditions: _parseStringArray(json['conditions']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex,
      'birthday': birthday?.toIso8601String().split('T').first,
      'weight_kg': weightKg,
      'body_size': bodySize,
      'fur_length': furLength,
      'color_main': colorMain,
      'color_secondary': colorSecondary,
      'eye_color': eyeColor,
      'microchip_number': microchipNumber,
      'personality_traits': personalityTraits,
      'bio': bio,
      'is_neutered': isNeutered,
      'allergies': allergies,
      'conditions': conditions,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static List<String> _parseStringArray(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
