import 'dart:convert';

/// Mirrors Supabase `pets` rows used by the Next.js app (`select('*')`, found-pet API, etc.).
/// Field names map snake_case columns to Dart properties.
class Pet {
  final String id;
  final String? userId;
  final String? name;
  final String species;
  final String status;
  final String? sex;
  final String? colorMain;
  final String? description;
  final String? imageUrl;
  final List<String> images;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final double? distance;
  final String? contactInfo;
  final double? reward;

  /// Web status page + `updatePetDetails` (`breed`, `color`, `marks`).
  final String? breed;
  final String? marks;
  final String? legacyColor;
  final String? petType;

  /// Found-pet API / Gemini traits.
  final String? colorSecondary;
  final String? colorPattern;
  final String? furLength;
  final String? eyeColor;
  final String? bodySize;
  final String? collarColor;
  final String? uniqueMarks;
  final DateTime? lastSeenAt;

  /// JSONB nested traits (ear_shape, has_collar, …).
  final Map<String, dynamic>? characteristics;

  final String? exifTime;
  final Map<String, dynamic>? exifLocation;

  /// Search / ML metadata (strings as stored in Postgres).
  final String? dominantColorsJson;
  final String? colorPercentagesJson;
  final String? labColorsJson;

  /// Vector presence only (embedding payload can be huge).
  final bool hasImageEmbedding;

  Pet({
    required this.id,
    this.userId,
    this.name,
    required this.species,
    required this.status,
    this.sex,
    this.colorMain,
    this.description,
    this.imageUrl,
    this.images = const [],
    this.lat,
    this.lng,
    required this.createdAt,
    this.expiresAt,
    this.distance,
    this.contactInfo,
    this.reward,
    this.breed,
    this.marks,
    this.legacyColor,
    this.petType,
    this.colorSecondary,
    this.colorPattern,
    this.furLength,
    this.eyeColor,
    this.bodySize,
    this.collarColor,
    this.uniqueMarks,
    this.lastSeenAt,
    this.characteristics,
    this.exifTime,
    this.exifLocation,
    this.dominantColorsJson,
    this.colorPercentagesJson,
    this.labColorsJson,
    this.hasImageEmbedding = false,
  });

  static String? _trimmedString(dynamic value) {
    if (value == null) return null;
    final t = value.toString().trim();
    return t.isEmpty ? null : t;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _jsonMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final t = value.trim();
      if (t.isEmpty) return null;
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  /// Normalizes API/DB values: null/empty → [fallbackUnknown], `dog`/`cat` → title case.
  static String normalizeSpecies(dynamic value, {String fallbackUnknown = 'Unknown'}) {
    if (value == null) return fallbackUnknown;
    final raw = value.toString().trim();
    if (raw.isEmpty) return fallbackUnknown;
    final lower = raw.toLowerCase();
    if (lower == 'dog' || lower == 'dogs') return 'Dog';
    if (lower == 'cat' || lower == 'cats') return 'Cat';
    if (lower == 'unknown') return fallbackUnknown;
    return raw;
  }

  static String? normalizeNullableDescription(dynamic value) {
    if (value == null) return null;
    final t = value.toString().trim();
    return t.isEmpty ? null : t;
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    final imagesList = <String>[];
    if (json['images'] != null) {
      imagesList.addAll((json['images'] as List).map((e) => e.toString()));
    }
    final primaryImage = json['image_url'] as String?;
    if (primaryImage != null && !imagesList.contains(primaryImage)) {
      imagesList.insert(0, primaryImage);
    }

    final emb = json['embedding'];
    final hasEmb = emb != null && emb.toString().trim().isNotEmpty;

    return Pet(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['pet_name'] as String?,
      species: normalizeSpecies(json['species'] ?? json['pet_type']),
      status: json['status'] as String? ?? 'LOST',
      sex: json['sex'] as String?,
      colorMain: _trimmedString(json['color_main']) ?? _trimmedString(json['color']),
      description: normalizeNullableDescription(json['description']),
      imageUrl: primaryImage,
      images: imagesList,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      distance: json['dist_meters'] != null ? (json['dist_meters'] as num).toDouble() : null,
      contactInfo: json['contact_info'] as String?,
      reward: _parseDouble(json['reward']),
      breed: _trimmedString(json['breed']),
      marks: _trimmedString(json['marks']),
      legacyColor: _trimmedString(json['color']),
      petType: _trimmedString(json['pet_type']),
      colorSecondary: _trimmedString(json['color_secondary']),
      colorPattern: _trimmedString(json['color_pattern']),
      furLength: _trimmedString(json['fur_length']),
      eyeColor: _trimmedString(json['eye_color']),
      bodySize: _trimmedString(json['body_size']),
      collarColor: _trimmedString(json['collar_color']),
      uniqueMarks: _trimmedString(json['unique_marks']),
      lastSeenAt: _parseDateTime(json['last_seen_at']),
      characteristics: _jsonMap(json['characteristics']),
      exifTime: _trimmedString(json['exif_time']),
      exifLocation: _jsonMap(json['exif_location']),
      dominantColorsJson: json['dominant_colors']?.toString(),
      colorPercentagesJson: json['color_percentages']?.toString(),
      labColorsJson: json['lab_colors']?.toString(),
      hasImageEmbedding: hasEmb,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Human-readable rows from [characteristics] (single level).
  Iterable<MapEntry<String, String>> get characteristicEntries sync* {
    final c = characteristics;
    if (c == null) return;
    for (final e in c.entries) {
      final k = e.key;
      final val = e.value;
      if (val == null) continue;
      if (val is bool) {
        yield MapEntry(k, val ? 'Yes' : 'No');
      } else if (val is List) {
        yield MapEntry(k, val.map((x) => x.toString()).join(', '));
      } else if (val is Map) {
        yield MapEntry(k, val.toString());
      } else {
        yield MapEntry(k, val.toString());
      }
    }
  }

  bool get hasExtendedAttributes {
    return (breed != null && breed!.isNotEmpty) ||
        (marks != null && marks!.isNotEmpty) ||
        (uniqueMarks != null && uniqueMarks!.isNotEmpty) ||
        (legacyColor != null && legacyColor!.isNotEmpty) ||
        (petType != null && petType!.isNotEmpty) ||
        (colorSecondary != null && colorSecondary!.isNotEmpty) ||
        (colorPattern != null && colorPattern!.isNotEmpty) ||
        (furLength != null && furLength!.isNotEmpty) ||
        (eyeColor != null && eyeColor!.isNotEmpty) ||
        (bodySize != null && bodySize!.isNotEmpty) ||
        (collarColor != null && collarColor!.isNotEmpty) ||
        lastSeenAt != null ||
        (exifTime != null && exifTime!.isNotEmpty) ||
        exifLocation != null ||
        (characteristics != null && characteristics!.isNotEmpty) ||
        (dominantColorsJson != null && dominantColorsJson!.isNotEmpty) ||
        (colorPercentagesJson != null && colorPercentagesJson!.isNotEmpty) ||
        (labColorsJson != null && labColorsJson!.isNotEmpty) ||
        hasImageEmbedding;
  }

  /// Title for feed/list when [name] is missing (e.g. web posts without `pet_name`).
  String titleForPreview({int maxLen = 28, String emptyFallback = 'Pet'}) {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final d = description?.trim();
    if (d != null && d.isNotEmpty) {
      return d.length > maxLen ? '${d.substring(0, maxLen - 1)}…' : d;
    }
    return emptyFallback;
  }

  /// Non-empty description text, or [emptyLabel] when null/blank/whitespace.
  String descriptionPreview({String emptyLabel = 'No description'}) {
    final d = description?.trim();
    if (d == null || d.isEmpty) return emptyLabel;
    return d;
  }

  Pet copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? status,
    String? sex,
    String? colorMain,
    String? description,
    String? imageUrl,
    List<String>? images,
    double? lat,
    double? lng,
    DateTime? createdAt,
    DateTime? expiresAt,
    double? distance,
    String? contactInfo,
    double? reward,
    String? breed,
    String? marks,
    String? legacyColor,
    String? petType,
    String? colorSecondary,
    String? colorPattern,
    String? furLength,
    String? eyeColor,
    String? bodySize,
    String? collarColor,
    String? uniqueMarks,
    DateTime? lastSeenAt,
    Map<String, dynamic>? characteristics,
    String? exifTime,
    Map<String, dynamic>? exifLocation,
    String? dominantColorsJson,
    String? colorPercentagesJson,
    String? labColorsJson,
    bool? hasImageEmbedding,
  }) {
    return Pet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      status: status ?? this.status,
      sex: sex ?? this.sex,
      colorMain: colorMain ?? this.colorMain,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      distance: distance ?? this.distance,
      contactInfo: contactInfo ?? this.contactInfo,
      reward: reward ?? this.reward,
      breed: breed ?? this.breed,
      marks: marks ?? this.marks,
      legacyColor: legacyColor ?? this.legacyColor,
      petType: petType ?? this.petType,
      colorSecondary: colorSecondary ?? this.colorSecondary,
      colorPattern: colorPattern ?? this.colorPattern,
      furLength: furLength ?? this.furLength,
      eyeColor: eyeColor ?? this.eyeColor,
      bodySize: bodySize ?? this.bodySize,
      collarColor: collarColor ?? this.collarColor,
      uniqueMarks: uniqueMarks ?? this.uniqueMarks,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      characteristics: characteristics ?? this.characteristics,
      exifTime: exifTime ?? this.exifTime,
      exifLocation: exifLocation ?? this.exifLocation,
      dominantColorsJson: dominantColorsJson ?? this.dominantColorsJson,
      colorPercentagesJson: colorPercentagesJson ?? this.colorPercentagesJson,
      labColorsJson: labColorsJson ?? this.labColorsJson,
      hasImageEmbedding: hasImageEmbedding ?? this.hasImageEmbedding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_name': name,
      'species': species,
      'status': status,
      'sex': sex,
      'color_main': colorMain,
      'description': description,
      'lat': lat,
      'lng': lng,
      'breed': breed,
      'marks': marks,
      'color': legacyColor,
      'pet_type': petType,
    };
  }
}
