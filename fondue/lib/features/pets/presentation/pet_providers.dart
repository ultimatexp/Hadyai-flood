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

class PaginatedPetsState {
  final List<Pet> pets;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedPetsState({
    this.pets = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginatedPetsState copyWith({
    List<Pet>? pets,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedPetsState(
      pets: pets ?? this.pets,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PaginatedLostPetsNotifier extends AsyncNotifier<PaginatedPetsState> {
  static const int _pageSize = 20;

  int _offset = 0;
  List<String> _blockedUsers = const [];

  @override
  Future<PaginatedPetsState> build() async {
    final repository = ref.watch(petRepositoryProvider);
    final filter = ref.watch(petFilterProvider);

    _offset = 0;
    _blockedUsers = await _loadBlockedUsers(repository);

    final page = await repository.fetchPets(
      status: filter.status,
      species: filter.species,
      limit: _pageSize,
      offset: 0,
    );
    _offset = page.length;

    return PaginatedPetsState(
      pets: _applyBlockedUsers(page),
      hasMore: page.length == _pageSize,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => build());
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(petRepositoryProvider);
      final filter = ref.read(petFilterProvider);

      final page = await repository.fetchPets(
        status: filter.status,
        species: filter.species,
        limit: _pageSize,
        offset: _offset,
      );
      _offset = _offset + page.length;

      final merged = [...current.pets, ..._applyBlockedUsers(page)];
      state = AsyncData(
        current.copyWith(
          pets: merged,
          hasMore: page.length == _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<List<String>> _loadBlockedUsers(PetRepository repository) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    try {
      return await repository.fetchBlockedUsers(user.id);
    } catch (_) {
      return [];
    }
  }

  List<Pet> _applyBlockedUsers(List<Pet> pets) {
    if (_blockedUsers.isEmpty) return pets;
    return pets.where((pet) => !(_blockedUsers.contains(pet.userId))).toList();
  }
}

final paginatedLostPetsProvider =
    AsyncNotifierProvider.autoDispose<PaginatedLostPetsNotifier, PaginatedPetsState>(
  PaginatedLostPetsNotifier.new,
);
