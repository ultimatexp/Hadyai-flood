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
  final String species; // 'All', 'Dog', 'Cat'

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

// Provider for Blocked Users
final blockedUsersProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user == null) return [];
  
  return repository.fetchBlockedUsers(user.id);
});

// Provider for Pets Stream/Future with Filtering
final lostPetsProvider = FutureProvider<List<Pet>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  final filter = ref.watch(petFilterProvider);
  
  // Get blocked users
  List<String> blockedUsers = [];
  try {
    blockedUsers = await ref.watch(blockedUsersProvider.future);
  } catch (_) {
    // If it fails, we default to empty block list
  }
  
  final pets = await repository.fetchPets(
    status: filter.status,
    species: filter.species,
  );

  // Filter blocked users
  if (blockedUsers.isNotEmpty) {
    return pets.where((pet) => !blockedUsers.contains(pet.userId)).toList();
  }

  return pets;
});

// Provider for User's Reports
final myReportsProvider = FutureProvider<List<Pet>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user == null) return [];
  
  return repository.fetchUserReports(user.id);
});
