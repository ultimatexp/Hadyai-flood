import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/pet_profile.dart';
import '../domain/medical_record.dart';

class PetProfileRepository {
  final SupabaseClient _client;

  PetProfileRepository(this._client);

  // ─── Pet Profiles ─────────────────────────────────────────────

  Future<List<PetProfile>> fetchMyPetProfiles() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('pet_profiles')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => PetProfile.fromJson(json)).toList();
  }

  Future<PetProfile?> fetchPetProfile(String id) async {
    final response = await _client
        .from('pet_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return PetProfile.fromJson(response);
  }

  Future<PetProfile> createPetProfile({
    required String name,
    required String species,
    String? breed,
    String? sex,
    DateTime? birthday,
    double? weightKg,
    String? bodySize,
    String? furLength,
    String? colorMain,
    String? colorSecondary,
    String? eyeColor,
    String? microchipNumber,
    List<String>? personalityTraits,
    String? bio,
    bool? isNeutered,
    List<String>? allergies,
    List<String>? conditions,
    List<dynamic>? imageFiles, // XFile list for upload
  }) async {
    List<String> imageUrls = [];

    // Upload images if provided
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (var imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.path.split('.').last;
        final fileName = 'pet-profiles/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

        await _client.storage.from('sos-photos').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

        final url = _client.storage.from('sos-photos').getPublicUrl(fileName);
        imageUrls.add(url);
      }
    }

    final data = {
      'owner_id': _client.auth.currentUser!.id,
      'name': name,
      'species': species,
      if (breed != null) 'breed': breed,
      if (sex != null) 'sex': sex,
      if (birthday != null) 'birthday': birthday.toIso8601String().split('T').first,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodySize != null) 'body_size': bodySize,
      if (furLength != null) 'fur_length': furLength,
      if (colorMain != null) 'color_main': colorMain,
      if (colorSecondary != null) 'color_secondary': colorSecondary,
      if (eyeColor != null) 'eye_color': eyeColor,
      if (microchipNumber != null) 'microchip_number': microchipNumber,
      if (personalityTraits != null) 'personality_traits': personalityTraits,
      if (bio != null) 'bio': bio,
      if (isNeutered != null) 'is_neutered': isNeutered,
      if (allergies != null) 'allergies': allergies,
      if (conditions != null) 'conditions': conditions,
      if (imageUrls.isNotEmpty) 'avatar_url': imageUrls.first,
      if (imageUrls.isNotEmpty) 'images': imageUrls,
    };

    final response = await _client
        .from('pet_profiles')
        .insert(data)
        .select()
        .single();

    return PetProfile.fromJson(response);
  }

  Future<void> updatePetProfile({
    required String id,
    String? name,
    String? species,
    String? breed,
    String? sex,
    DateTime? birthday,
    double? weightKg,
    String? bodySize,
    String? furLength,
    String? colorMain,
    String? colorSecondary,
    String? eyeColor,
    String? microchipNumber,
    List<String>? personalityTraits,
    String? bio,
    bool? isNeutered,
    List<String>? allergies,
    List<String>? conditions,
    String? avatarUrl,
    List<String>? images,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (name != null) 'name': name,
      if (species != null) 'species': species,
      if (breed != null) 'breed': breed,
      if (sex != null) 'sex': sex,
      if (birthday != null) 'birthday': birthday.toIso8601String().split('T').first,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodySize != null) 'body_size': bodySize,
      if (furLength != null) 'fur_length': furLength,
      if (colorMain != null) 'color_main': colorMain,
      if (colorSecondary != null) 'color_secondary': colorSecondary,
      if (eyeColor != null) 'eye_color': eyeColor,
      if (microchipNumber != null) 'microchip_number': microchipNumber,
      if (personalityTraits != null) 'personality_traits': personalityTraits,
      if (bio != null) 'bio': bio,
      if (isNeutered != null) 'is_neutered': isNeutered,
      if (allergies != null) 'allergies': allergies,
      if (conditions != null) 'conditions': conditions,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (images != null) 'images': images,
    };

    await _client.from('pet_profiles').update(data).eq('id', id);
  }

  Future<void> deletePetProfile(String id) async {
    await _client.from('pet_profiles').delete().eq('id', id);
  }

  Future<String> uploadProfileImage(dynamic imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final fileExt = imageFile.path.split('.').last;
    final fileName = 'pet-profiles/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

    await _client.storage.from('sos-photos').uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$fileExt'),
    );

    return _client.storage.from('sos-photos').getPublicUrl(fileName);
  }

  // ─── Medical Records ──────────────────────────────────────────

  Future<List<MedicalRecord>> fetchMedicalRecords(String petProfileId) async {
    final response = await _client
        .from('pet_medical_records')
        .select()
        .eq('pet_profile_id', petProfileId)
        .order('date', ascending: false);

    return (response as List).map((json) => MedicalRecord.fromJson(json)).toList();
  }

  Future<MedicalRecord> addMedicalRecord({
    required String petProfileId,
    required String recordType,
    required String title,
    String? description,
    required DateTime date,
    DateTime? nextDueDate,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _client
        .from('pet_medical_records')
        .insert({
          'pet_profile_id': petProfileId,
          'record_type': recordType,
          'title': title,
          if (description != null) 'description': description,
          'date': date.toIso8601String().split('T').first,
          if (nextDueDate != null) 'next_due_date': nextDueDate.toIso8601String().split('T').first,
          if (metadata != null) 'metadata': metadata,
        })
        .select()
        .single();

    return MedicalRecord.fromJson(response);
  }

  Future<void> deleteMedicalRecord(String id) async {
    await _client.from('pet_medical_records').delete().eq('id', id);
  }
}
