class Pet {
  final String id;
  final String? userId; // Owner of the listing
  final String? name;
  final String species;
  final String status; // 'LOST', 'FOUND', 'ADOPTABLE'
  final String? sex;
  final String? colorMain;
  final String? description;
  final String? imageUrl;
  final List<String> images; // Multiple photos
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final DateTime? expiresAt; // Report expiration date
  final double? distance; // Computed for feed
  final String? contactInfo;
  final double? reward; // Reward amount if offered

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
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    // Parse images array
    List<String> imagesList = [];
    if (json['images'] != null) {
      imagesList = (json['images'] as List).map((e) => e.toString()).toList();
    }
    // Add primary image_url to the list if not already there
    final primaryImage = json['image_url'] as String?;
    if (primaryImage != null && !imagesList.contains(primaryImage)) {
      imagesList.insert(0, primaryImage);
    }

    return Pet(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['pet_name'] as String?,
      species: json['species'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'LOST',
      sex: json['sex'] as String?,
      colorMain: json['color_main'] as String?,
      description: json['description'] as String?,
      imageUrl: primaryImage,
      images: imagesList,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
      distance: json['dist_meters'] != null ? (json['dist_meters'] as num).toDouble() : null,
      contactInfo: json['contact_info'] as String?,
      reward: _parseDouble(json['reward']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Add keys that match Supabase columns for insertion
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
      // 'image_url' usually handled by storage upload then update
    };
  }
}
