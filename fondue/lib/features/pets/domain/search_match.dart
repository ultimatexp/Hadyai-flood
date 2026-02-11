import 'pet.dart';

/// Represents a pet match result from semantic search
/// Contains the base Pet data plus similarity scores
class SearchMatch {
  final Pet pet;
  final double combinedScore;      // Final weighted score (0-1)
  final double embeddingSimilarity; // AI vision similarity (0-1)
  final double colorSimilarity;     // Color matching (0-1)
  final double featureScore;        // Gemini feature matching (0-1)

  SearchMatch({
    required this.pet,
    required this.combinedScore,
    required this.embeddingSimilarity,
    required this.colorSimilarity,
    required this.featureScore,
  });

  factory SearchMatch.fromJson(Map<String, dynamic> json) {
    return SearchMatch(
      pet: Pet.fromJson(json),
      combinedScore: (json['combined_score'] as num?)?.toDouble() ?? 0.0,
      embeddingSimilarity: (json['embedding_similarity'] as num?)?.toDouble() ?? 0.0,
      colorSimilarity: (json['color_similarity'] as num?)?.toDouble() ?? 0.0,
      featureScore: (json['feature_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Display percentage (0-100%)
  int get matchPercent => (combinedScore * 100).round();
  int get embeddingPercent => (embeddingSimilarity * 100).round();
  int get colorPercent => (colorSimilarity * 100).round();
  int get featurePercent => (featureScore * 100).round();
}
