import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../pets/presentation/semantic_search_screen.dart';
import '../../pets/presentation/pet_detail_screen.dart';
import '../../pets/domain/pet.dart';
import '../data/overview_providers.dart';
import '../data/dashboard_providers.dart';
import '../../pets/presentation/pet_feed_screen.dart';

import '../../pets/presentation/report_screen.dart';

import '../../inbox/presentation/inbox_screen.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(overviewStatsProvider);
    final latestFoundAsync = ref.watch(latestFoundPetsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Fondue Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black87),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
            }, 
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Action Buttons Row
            Row(
              children: [
                Expanded(child: _buildSearchButton(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildFoundPetButton(context)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 2. Stats Cards
            Text(
              "Today's Activity",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(child: _buildStatCard("Found", stats['today_found'] ?? 0, Colors.green)),
                  const SizedBox(width: 12),
                  // Use 'Searched' as placeholder or mock for now
                  Expanded(child: _buildStatCard("Searched", stats['today_search'] ?? 0, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Reunited", stats['today_success'] ?? 0, Colors.blue)),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("Failed to load stats"),
            ),
            
            const SizedBox(height: 24),
            
            // 3. Latest Found
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Latest Found",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PetFeedScreen()));
                  },
                  child: const Text("See All"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            latestFoundAsync.when(
              data: (pets) {
                if (pets.isEmpty) {
                  return const Center(child: Text("No found pets yet."));
                }
                return SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _buildPetCard(context, pets[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Text("Failed to load pets: $e"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SemanticSearchScreen()));
      },
      child: Container(
        height: 180, // Fixed height for consistency
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_rounded, size: 40, color: Colors.white),
            SizedBox(height: 12),
            Text(
              "Find Lost",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "AI Search",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundPetButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen(initialStatus: 'FOUND')));
      },
      child: Container(
        height: 180, // Match height
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // Green gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
             Icon(Icons.pets, size: 40, color: Colors.white),
             SizedBox(height: 12),
             Text(
               "Found Stray",
               textAlign: TextAlign.center,
               style: TextStyle(
                 color: Colors.white,
                 fontSize: 18,
                 fontWeight: FontWeight.bold,
               ),
             ),
             SizedBox(height: 4),
             Text(
               "Report Pet",
               textAlign: TextAlign.center,
               style: TextStyle(
                 color: Colors.white70,
                 fontSize: 13,
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet) {
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)));
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
             BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: pet.imageUrl != null
                    ? Image.network(pet.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pet.species,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
