import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';

// Provider for the Repository
final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(Supabase.instance.client);
});

class PetFilter {
  final String status; // 'All', 'LOST', 'FOUND', 'ADOPTABLE'
  final String species; // 'All', 'Dog', 'Cat', 'Bird', etc.

  const PetFilter({this.status = 'All', this.species = 'All'});

  PetFilter copyWith({String? status, String? species}) {
    return PetFilter(
      status: status ?? this.status,
      species: species ?? this.species,
    );
  }
}

class PetFilterNotifier extends Notifier<PetFilter> {
  @override
  PetFilter build() => const PetFilter();

  void setFilter(PetFilter filter) {
    state = filter;
  }
}

final petFilterProvider = NotifierProvider<PetFilterNotifier, PetFilter>(PetFilterNotifier.new);

// Provider for Pets Stream/Future with Filtering
final lostPetsProvider = FutureProvider<List<Pet>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  final filter = ref.watch(petFilterProvider);
  
  return repository.fetchPets(
    status: filter.status,
    species: filter.species,
  );
});

// Provider for User's Reports
final myReportsProvider = FutureProvider<List<Pet>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user == null) return [];
  
  return repository.fetchUserReports(user.id);
});
