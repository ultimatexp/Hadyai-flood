import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'pet.dart';
import '../data/pet_repository.dart';
import '../presentation/pet_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetMatcherService {
  final PetRepository _repository;
  
  PetMatcherService(this._repository);

  // Find potential matches for the user's lost pets among found pets
  Future<List<Map<String, dynamic>>> findMatchesForUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    // 1. Get User's Lost Pets
    final myReports = await _repository.fetchUserReports(user.id);
    final myLostPets = myReports.where((p) => p.status == 'LOST').toList();

    if (myLostPets.isEmpty) return [];

    // 2. Get All Found Pets
    final allFoundPets = await _repository.fetchPets(status: 'FOUND');
    
    // 3. Get dismissed matches to filter them out
    final dismissedKeys = await _getDismissedMatchKeys();

    List<Map<String, dynamic>> matches = [];

    // 4. Compare
    for (var lostPet in myLostPets) {
      for (var foundPet in allFoundPets) {
        // Skip dismissed matches
        final matchKey = '${lostPet.id}_${foundPet.id}';
        if (dismissedKeys.contains(matchKey)) continue;

        double score = _calculateMatchScore(lostPet, foundPet);
        
        if (score > 0.6) { // Threshold for "Potential Match"
          matches.add({
            'lostPet': lostPet,
            'foundPet': foundPet,
            'score': score,
          });
        }
      }
    }

    // Sort by score
    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return matches;
  }

  // Get list of dismissed match pairs for current user
  Future<Set<String>> _getDismissedMatchKeys() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await Supabase.instance.client
          .from('dismissed_matches')
          .select('lost_pet_id, found_pet_id')
          .eq('user_id', user.id);

      final Set<String> keys = {};
      for (var row in response) {
        keys.add('${row['lost_pet_id']}_${row['found_pet_id']}');
      }
      return keys;
    } catch (e) {
      print('Error fetching dismissed matches: $e');
      return {};
    }
  }

  // Dismiss a match so it won't show again
  Future<bool> dismissMatch(String lostPetId, String foundPetId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      await Supabase.instance.client.from('dismissed_matches').upsert({
        'user_id': user.id,
        'lost_pet_id': lostPetId,
        'found_pet_id': foundPetId,
      });
      return true;
    } catch (e) {
      print('Error dismissing match: $e');
      return false;
    }
  }

  // Find potential matches for a specific lost pet
  Future<List<Map<String, dynamic>>> findMatchesForPet(Pet lostPet) async {
    // 1. Get All Found Pets
    final allFoundPets = await _repository.fetchPets(status: 'FOUND');

    List<Map<String, dynamic>> matches = [];

    // 2. Compare
    for (var foundPet in allFoundPets) {
      double score = _calculateMatchScore(lostPet, foundPet);
      
      if (score > 0.6) { // Threshold for "Potential Match"
        matches.add({
          'lostPet': lostPet,
          'foundPet': foundPet,
          'score': score,
        });
      }
    }

    // Sort by score
    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return matches;
  }

  double _calculateMatchScore(Pet lost, Pet found) {
    double score = 0.0;
    
    // 1. Species (Must match)
    if (lost.species.toLowerCase() != found.species.toLowerCase()) {
      return 0.0;
    }
    score += 0.3;

    // 2. Sex (If known)
    if (lost.sex != null && found.sex != null && lost.sex != 'Unknown' && found.sex != 'Unknown') {
      if (lost.sex == found.sex) {
        score += 0.1;
      } else {
        return 0.0; // Hard mismatch on sex
      }
    }

    // 3. Distance (if both have location)
    if (lost.lat != null && lost.lng != null && found.lat != null && found.lng != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        lost.lat!, lost.lng!, 
        found.lat!, found.lng!
      );
      
      if (distanceInMeters < 1000) { // < 1km
        score += 0.4;
      } else if (distanceInMeters < 5000) { // < 5km
        score += 0.2;
      } else if (distanceInMeters < 10000) { // < 10km
        score += 0.1;
      }
    }

    // 4. Color (Simple fuzzy match)
    if (lost.colorMain != null && found.colorMain != null) {
      if (found.colorMain!.toLowerCase().contains(lost.colorMain!.toLowerCase()) || 
          lost.colorMain!.toLowerCase().contains(found.colorMain!.toLowerCase())) {
        score += 0.2;
      }
    }

    return score;
  }
}

final petMatcherProvider = Provider<PetMatcherService>((ref) {
  return PetMatcherService(ref.read(petRepositoryProvider));
});
