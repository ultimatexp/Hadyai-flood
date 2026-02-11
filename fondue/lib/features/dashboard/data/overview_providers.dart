
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pets/presentation/pet_providers.dart';
import '../../pets/data/pet_repository.dart';
import '../../pets/domain/pet.dart';

final overviewStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.read(petRepositoryProvider);
  return repository.fetchStats();
});

final latestFoundPetsProvider = FutureProvider<List<Pet>>((ref) async {
  final repository = ref.read(petRepositoryProvider);
  return repository.fetchLatestFoundPets(limit: 5);
});
