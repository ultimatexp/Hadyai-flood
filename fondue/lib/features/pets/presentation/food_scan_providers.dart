import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/food_scan_repository.dart';
import '../data/gemini_service.dart';
import '../domain/food_scan_result.dart';
import 'gemini_provider.dart';

// Repository provider
final foodScanRepositoryProvider = Provider<FoodScanRepository>((ref) {
  return FoodScanRepository(Supabase.instance.client);
});

// Scan history for a specific pet
final foodScanHistoryProvider =
    FutureProvider.family<List<FoodScanResult>, String>((ref, petProfileId) async {
  final repo = ref.watch(foodScanRepositoryProvider);
  return repo.fetchScansForPet(petProfileId);
});

// Recent scans for the user
final recentFoodScansProvider =
    FutureProvider<List<FoodScanResult>>((ref) async {
  final repo = ref.watch(foodScanRepositoryProvider);
  return repo.fetchRecentScans();
});

// Toxic ingredients for a species
final toxicIngredientsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, species) async {
  final repo = ref.watch(foodScanRepositoryProvider);
  return repo.fetchToxicIngredients(species);
});

/// State for the food analysis flow
class FoodAnalysisState {
  final FoodAnalysisStatus status;
  final FoodScanResult? result;
  final String? error;

  const FoodAnalysisState({
    required this.status,
    this.result,
    this.error,
  });

  const FoodAnalysisState.idle()
      : status = FoodAnalysisStatus.idle,
        result = null,
        error = null;

  const FoodAnalysisState.scanning()
      : status = FoodAnalysisStatus.scanning,
        result = null,
        error = null;

  FoodAnalysisState.done(FoodScanResult r)
      : status = FoodAnalysisStatus.result,
        result = r,
        error = null;

  FoodAnalysisState.failed(String e)
      : status = FoodAnalysisStatus.error,
        result = null,
        error = e;
}

enum FoodAnalysisStatus { idle, scanning, result, error }

/// Manages the food analysis state machine: idle → scanning → result/error
class FoodAnalysisNotifier extends Notifier<FoodAnalysisState> {
  @override
  FoodAnalysisState build() => const FoodAnalysisState.idle();

  Future<FoodScanResult?> analyzeFood({
    required Uint8List imageBytes,
    required String petProfileId,
    required String species,
    String? breed,
    String? ageText,
    double? weightKg,
    List<String> allergies = const [],
    List<String> conditions = const [],
    String? imageUrl,
  }) async {
    state = const FoodAnalysisState.scanning();

    try {
      // Fetch toxic ingredients for this species
      final foodScanRepo = ref.read(foodScanRepositoryProvider);
      final gemini = ref.read(geminiServiceProvider);
      final toxics = await foodScanRepo.fetchToxicIngredients(species);

      // Analyze with Gemini
      final result = await gemini.analyzePetFood(
        imageBytes: imageBytes,
        species: species,
        breed: breed,
        ageText: ageText,
        weightKg: weightKg,
        allergies: allergies,
        conditions: conditions,
        toxicIngredients: toxics,
      );

      if (result.containsKey('error')) {
        state = FoodAnalysisState.failed(result['error'] as String);
        return null;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        state = FoodAnalysisState.failed('Not logged in');
        return null;
      }

      // Build the scan result
      final scanResult = FoodScanResult(
        id: '', // will be assigned by DB
        userId: userId,
        petProfileId: petProfileId,
        productName: result['product_name'] as String?,
        imageUrl: imageUrl,
        ingredients: (result['ingredients'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        guaranteedAnalysis:
            (result['guaranteed_analysis'] as Map<String, dynamic>?) ?? {},
        verdict: result['verdict'] as String? ?? 'CAUTION',
        score: (result['score'] as int?) ?? 5,
        warnings: (result['warnings'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        aiAnalysis: result['analysis_text'] as String?,
        createdAt: DateTime.now(),
      );

      // Save to DB
      final saved = await foodScanRepo.saveScan(scanResult);
      state = FoodAnalysisState.done(saved);
      return saved;
    } catch (e) {
      state = FoodAnalysisState.failed(e.toString());
      return null;
    }
  }

  void reset() {
    state = const FoodAnalysisState.idle();
  }
}

// Provider for the analysis state machine
final foodAnalysisProvider =
    NotifierProvider<FoodAnalysisNotifier, FoodAnalysisState>(
  FoodAnalysisNotifier.new,
);
