import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pet_providers.dart';
import '../domain/pet.dart';
import '../../../../core/theme/app_theme.dart';
import 'pet_detail_screen.dart';
import 'semantic_search_screen.dart';
import 'map_view_screen.dart';
import 'widgets/pet_card.dart';

import '../domain/pet_matcher_service.dart';

class PetFeedScreen extends ConsumerStatefulWidget {
  const PetFeedScreen({super.key});

  @override
  ConsumerState<PetFeedScreen> createState() => _PetFeedScreenState();
}

class _PetFeedScreenState extends ConsumerState<PetFeedScreen> {
  bool _hasCheckedMatches = false;

  @override
  void initState() {
    super.initState();
    // Check for matches slightly after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForMatches();
    });
  }

  Future<void> _checkForMatches() async {
    if (_hasCheckedMatches) return;
    _hasCheckedMatches = true;

    final matcher = ref.read(petMatcherProvider);
    final matches = await matcher.findMatchesForUser();

    if (matches.isNotEmpty && mounted) {
      _showMatchAlert(matches.first);
    }
  }

  void _showMatchAlert(Map<String, dynamic> match) {
    final lostPet = match['lostPet'] as Pet;
    final foundPet = match['foundPet'] as Pet;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.notification_important, color: Colors.amber),
            SizedBox(width: 8),
            Flexible(child: Text('Potential Match Found!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Someone found a pet that looks like your lost ${lostPet.species} "${lostPet.name ?? 'Pet'}"!'),
            const SizedBox(height: 16),
            const Text('Found Pet Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (foundPet.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(foundPet.imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(foundPet.description ?? 'No description'),
                      Text('Color: ${foundPet.colorMain ?? 'Unknown'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PetDetailScreen(pet: foundPet)),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentOrange),
            child: const Text('View Found Pet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lostPetsAsync = ref.watch(lostPetsProvider);
    final filter = ref.watch(petFilterProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Found & Lost Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.black87), 
            onPressed: () {
               Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const Scaffold(body: MapViewScreen()), 
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            tooltip: 'Map View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Button Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SemanticSearchScreen()),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.05),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.05, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    builder: (context, scale2, child) {
                      return Transform.scale(
                        scale: scale * scale2 / 1.05,
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        "Search",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter Chips Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // color: Colors.white, // Transparent to blend if needed, or keep white
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  context, 
                  ref, 
                  label: "All", 
                  isSelected: filter.status == 'All',
                  onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(status: 'All')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: "Lost", 
                  isSelected: filter.status == 'LOST',
                  color: Colors.red,
                  onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(status: 'LOST')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: "Found", 
                  isSelected: filter.status == 'FOUND',
                  color: AppTheme.primaryGreen,
                  onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(status: 'FOUND')),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: Colors.grey[300]), // Divider
                const SizedBox(width: 16),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: "Dogs", 
                  isSelected: filter.species == 'Dog',
                  icon: Icons.pets,
                  onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(species: filter.species == 'Dog' ? 'All' : 'Dog')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: "Cats", 
                  isSelected: filter.species == 'Cat',
                  icon: Icons.pets,
                  onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(species: filter.species == 'Cat' ? 'All' : 'Cat')),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Pet List
          Expanded(
            child: lostPetsAsync.when(
              data: (pets) {
                if (pets.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No pets found matching filters.'),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    return PetCard(pet: pet);
                  },
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, {
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final themeColor = color ?? Colors.orange;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
               Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
               const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


