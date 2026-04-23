import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/shimmer_loading.dart';
import '../../pets/presentation/pet_search_navigation.dart';
import '../../pets/presentation/pet_detail_screen.dart';
import '../../pets/domain/pet.dart';
import '../data/overview_providers.dart';
import '../data/dashboard_providers.dart';
import '../../pets/presentation/pet_feed_screen.dart';

import '../../pets/presentation/report_screen.dart';

import '../../inbox/presentation/inbox_screen.dart';
import '../../inbox/data/inbox_providers.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(overviewStatsProvider);
    final latestFoundAsync = ref.watch(latestFoundPetsProvider);
    final unreadNotificationsAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadNotifications = unreadNotificationsAsync.asData?.value ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Fondue Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: unreadNotifications > 0
                ? Badge(
                    label: Text('$unreadNotifications', style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.notifications, color: Colors.black87),
                  )
                : const Icon(Icons.notifications, color: Colors.black87),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
            }, 
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(overviewStatsProvider);
          ref.invalidate(latestFoundPetsProvider);
        },
        color: AppTheme.accentOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Greeting Header
              _buildGreetingHeader(context),
              const SizedBox(height: 20),

              // 1. Action Buttons Row
              Row(
                children: [
                  Expanded(child: _buildSearchButton(context, ref)),
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
                    Expanded(child: _buildAnimatedStatCard("Found", stats['today_found'] ?? 0, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAnimatedStatCard("Searched", stats['today_search'] ?? 0, Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAnimatedStatCard("Reunited", stats['today_success'] ?? 0, Colors.blue)),
                  ],
                ),
                loading: () => Row(
                  children: const [
                    Expanded(child: StatCardSkeleton()),
                    SizedBox(width: 12),
                    Expanded(child: StatCardSkeleton()),
                    SizedBox(width: 12),
                    Expanded(child: StatCardSkeleton()),
                  ],
                ),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No found pets yet. Be the first to report!",
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
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
              loading: () => SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => const PetCardSmallSkeleton(),
                ),
              ),
              error: (e, __) => Text("Failed to load pets: $e"),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? 'Guest';
    final firstName = name.toString().split(' ').first;
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 12) {
      greeting = 'Good morning';
      emoji = '☀️';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      emoji = '🐾';
    } else {
      greeting = 'Good evening';
      emoji = '🌙';
    }

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: user?.userMetadata?['avatar_url'] != null
              ? ClipOval(
                  child: Image.network(
                    user!.userMetadata!['avatar_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                  ),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $emoji',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        switchToHomePetSearch(ref, context);
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

  Widget _buildAnimatedStatCard(String title, int count, Color color) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: count),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
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
                value.toString(),
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
      },
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
                    pet.titleForPreview(emptyFallback: 'Pet'),
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
