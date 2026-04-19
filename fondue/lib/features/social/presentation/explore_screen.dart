import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pets/presentation/pet_providers.dart';
import '../../pets/presentation/pet_detail_screen.dart';
import '../../pets/presentation/pet_search_navigation.dart';
import '../../pets/domain/pet.dart';


/// Instagram Explore-style discovery screen with staggered grid
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(lostPetsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Search bar header
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('สำรวจ'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    switchToHomePetSearch(ref, context);
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey[500], size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'ค้นหาสัตว์เลี้ยง...',
                          style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(label: 'ทั้งหมด', icon: Icons.grid_view, isSelected: _selectedFilter == 'all', onTap: () => setState(() => _selectedFilter = 'all')),
                  _FilterChip(label: '🐶 หมา', isSelected: _selectedFilter == 'dog', onTap: () => setState(() => _selectedFilter = 'dog')),
                  _FilterChip(label: '🐱 แมว', isSelected: _selectedFilter == 'cat', onTap: () => setState(() => _selectedFilter = 'cat')),
                  _FilterChip(label: '📍 ใกล้ฉัน', icon: Icons.location_on, isSelected: _selectedFilter == 'nearby', onTap: () => setState(() => _selectedFilter = 'nearby')),
                  _FilterChip(label: '🎉 กลับบ้าน', isSelected: _selectedFilter == 'reunited', onTap: () => setState(() => _selectedFilter = 'reunited')),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(top: 8)),

          // Staggered grid
          petsAsync.when(
            data: (pets) {
              // Apply filter
              final filtered = _applyFilter(pets);

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('ไม่พบผลลัพธ์', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _ExploreGridItem(
                        pet: filtered[index],
                        isLarge: _isLargeCell(index),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PetDetailScreen(pet: filtered[index])),
                          );
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  childCount: 9,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
              ),
            ),
            error: (_, __) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('เกิดข้อผิดพลาด', style: TextStyle(color: Colors.grey[600]))),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  List<Pet> _applyFilter(List<Pet> pets) {
    return switch (_selectedFilter) {
      'dog' => pets.where((p) => p.species.toLowerCase().contains('dog') || p.species.toLowerCase().contains('หมา')).toList(),
      'cat' => pets.where((p) => p.species.toLowerCase().contains('cat') || p.species.toLowerCase().contains('แมว')).toList(),
      'nearby' => pets.where((p) => p.distance != null && p.distance! < 5000).toList(),
      'reunited' => pets.where((p) => p.status == 'REUNITED').toList(),
      _ => pets,
    };
  }

  bool _isLargeCell(int index) {
    // Instagram-style pattern: every 10th item starting at 0, and every 10th + 6
    final mod = index % 10;
    return mod == 0 || mod == 6;
  }
}

class _ExploreGridItem extends StatelessWidget {
  final Pet pet;
  final bool isLarge;
  final VoidCallback onTap;

  const _ExploreGridItem({
    required this.pet,
    required this.isLarge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            pet.imageUrl != null
                ? Image.network(
                    pet.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),

            // Status badge overlay
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(pet.status).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _statusLabel(pet.status),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Bottom gradient
            if (isLarge)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pet.name ?? pet.species,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (pet.distance != null)
                        Text(
                          '${(pet.distance! / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[200],
    child: Icon(Icons.pets, color: Colors.grey[400], size: 32),
  );

  Color _statusColor(String status) {
    return switch (status) {
      'LOST' => Colors.red,
      'FOUND' => Colors.green,
      'REUNITED' => Colors.blue,
      _ => Colors.grey,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'LOST' => 'หาย',
      'FOUND' => 'พบ',
      'REUNITED' => 'กลับบ้าน',
      _ => status,
    };
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF9800) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


