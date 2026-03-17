import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/food_scan_result.dart';

class FoodScanRepository {
  final SupabaseClient _client;

  FoodScanRepository(this._client);

  /// Save a food scan result
  Future<FoodScanResult> saveScan(FoodScanResult result) async {
    final response = await _client
        .from('pet_food_scans')
        .insert(result.toInsertJson())
        .select()
        .single();
    return FoodScanResult.fromJson(response);
  }

  /// Fetch scan history for a specific pet
  Future<List<FoodScanResult>> fetchScansForPet(String petProfileId) async {
    final response = await _client
        .from('pet_food_scans')
        .select()
        .eq('pet_profile_id', petProfileId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => FoodScanResult.fromJson(json)).toList();
  }

  /// Fetch user's recent scans (last 20)
  Future<List<FoodScanResult>> fetchRecentScans() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('pet_food_scans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    return (response as List).map((json) => FoodScanResult.fromJson(json)).toList();
  }

  /// Fetch toxic ingredients for a species
  Future<List<Map<String, dynamic>>> fetchToxicIngredients(String species) async {
    final response = await _client
        .from('toxic_ingredients')
        .select()
        .eq('species', species);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upload food label image
  Future<String> uploadFoodImage(dynamic imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final fileExt = imageFile.path.split('.').last;
    final fileName = 'food-scans/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

    await _client.storage.from('sos-photos').uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$fileExt'),
    );

    return _client.storage.from('sos-photos').getPublicUrl(fileName);
  }

  /// Delete a food scan
  Future<void> deleteScan(String id) async {
    await _client.from('pet_food_scans').delete().eq('id', id);
  }
}
