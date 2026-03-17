class FoodScanResult {
  final String id;
  final String userId;
  final String petProfileId;
  final String? productName;
  final String? imageUrl;
  final List<String> ingredients;
  final Map<String, dynamic> guaranteedAnalysis;
  final String verdict; // SUITABLE, CAUTION, NOT_RECOMMENDED
  final int score; // 1-10
  final List<String> warnings;
  final String? aiAnalysis;
  final DateTime createdAt;

  FoodScanResult({
    required this.id,
    required this.userId,
    required this.petProfileId,
    this.productName,
    this.imageUrl,
    this.ingredients = const [],
    this.guaranteedAnalysis = const {},
    required this.verdict,
    required this.score,
    this.warnings = const [],
    this.aiAnalysis,
    required this.createdAt,
  });

  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    return FoodScanResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      petProfileId: json['pet_profile_id'] as String,
      productName: json['product_name'] as String?,
      imageUrl: json['image_url'] as String?,
      ingredients: _parseStringList(json['ingredients']),
      guaranteedAnalysis: (json['guaranteed_analysis'] as Map<String, dynamic>?) ?? {},
      verdict: json['verdict'] as String? ?? 'CAUTION',
      score: (json['score'] as int?) ?? 5,
      warnings: _parseStringList(json['warnings']),
      aiAnalysis: json['ai_analysis'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'pet_profile_id': petProfileId,
      'product_name': productName,
      'image_url': imageUrl,
      'ingredients': ingredients,
      'guaranteed_analysis': guaranteedAnalysis,
      'verdict': verdict,
      'score': score,
      'warnings': warnings,
      'ai_analysis': aiAnalysis,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
