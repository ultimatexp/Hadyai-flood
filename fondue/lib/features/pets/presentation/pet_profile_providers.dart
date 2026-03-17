import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/pet_profile_repository.dart';
import '../domain/pet_profile.dart';
import '../domain/medical_record.dart';

// Repository provider
final petProfileRepositoryProvider = Provider<PetProfileRepository>((ref) {
  return PetProfileRepository(Supabase.instance.client);
});

// My pet profiles
final myPetProfilesProvider = FutureProvider<List<PetProfile>>((ref) async {
  final repo = ref.watch(petProfileRepositoryProvider);
  return repo.fetchMyPetProfiles();
});

// Single pet profile by ID
final petProfileProvider = FutureProvider.family<PetProfile?, String>((ref, id) async {
  final repo = ref.watch(petProfileRepositoryProvider);
  return repo.fetchPetProfile(id);
});

// Medical records for a pet profile
final medicalRecordsProvider = FutureProvider.family<List<MedicalRecord>, String>((ref, petProfileId) async {
  final repo = ref.watch(petProfileRepositoryProvider);
  return repo.fetchMedicalRecords(petProfileId);
});
