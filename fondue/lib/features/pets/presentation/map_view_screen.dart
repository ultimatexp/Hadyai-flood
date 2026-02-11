import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pet_providers.dart';
import 'pet_detail_screen.dart';
import 'semantic_search_screen.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/pet.dart';
import '../../dashboard/data/dashboard_providers.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final Pet? initialPet;
  const MapViewScreen({super.key, this.initialPet});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  Pet? _selectedPet;

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialPet;
  }

  void _selectPet(Pet pet) {
    setState(() => _selectedPet = pet);
  }

  void _clearSelection() {
    setState(() => _selectedPet = null);
  }

  @override
  Widget build(BuildContext context) {
    final lostPetsAsync = ref.watch(lostPetsProvider);
    final filter = ref.watch(petFilterProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pet Map'),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
      ),
      body: lostPetsAsync.when(
        data: (pets) {
          final markers = pets
              .where((p) => p.lat != null && p.lng != null)
              .map((p) => Marker(
                    point: LatLng(p.lat!, p.lng!),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _selectPet(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _selectedPet?.id == p.id
                              ? AppTheme.accentOrange
                              : (p.status == 'LOST' ? Colors.red : AppTheme.primaryGreen),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: _selectedPet?.id == p.id ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: _selectedPet?.id == p.id ? 8 : 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: _buildMarkerContent(p),
                      ),
                    ),
                  ))
              .toList();

          return Stack(
            children: [
              // Map
              GestureDetector(
                onTap: _clearSelection,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: widget.initialPet != null && widget.initialPet!.lat != null && widget.initialPet!.lng != null
                        ? LatLng(widget.initialPet!.lat!, widget.initialPet!.lng!)
                        : const LatLng(7.005, 100.476), // Default to Hadyai
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}@2x.png?key=${AppConstants.mapTilerKey}',
                      userAgentPackageName: 'com.fondue.app',
                      retinaMode: true,
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),

              // Search Bar Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                left: 16,
                right: 80, // Leave space for legend
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SemanticSearchScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_search, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "Search by photo...",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filter Chips Overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 60,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildMapFilterChip(
                        label: "All",
                        isSelected: filter.status == 'All',
                        onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(status: 'All')),
                      ),
                      const SizedBox(width: 8),
                      _buildMapFilterChip(
                        label: "Lost",
                        isSelected: filter.status == 'LOST',
                        color: Colors.red,
                        onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(status: 'LOST')),
                      ),
                      const SizedBox(width: 8),
                      _buildMapFilterChip(
                        label: "Found",
                        isSelected: filter.status == 'FOUND',
                        color: AppTheme.primaryGreen,
                        onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(status: 'FOUND')),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 20, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      _buildMapFilterChip(
                        label: "Dogs",
                        isSelected: filter.species == 'Dog',
                        icon: Icons.pets,
                        onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(species: filter.species == 'Dog' ? 'All' : 'Dog')),
                      ),
                      const SizedBox(width: 8),
                      _buildMapFilterChip(
                        label: "Cats",
                        isSelected: filter.species == 'Cat',
                        icon: Icons.pets,
                        onTap: () => ref.read(petFilterProvider.notifier).setFilter(filter.copyWith(species: filter.species == 'Cat' ? 'All' : 'Cat')),
                      ),
                    ],
                  ),
                ),
              ),

              // Legend
              Positioned(
                bottom: 24,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendItem(Colors.red, "Lost"),
                      const SizedBox(height: 4),
                      _buildLegendItem(AppTheme.primaryGreen, "Found"),
                    ],
                  ),
                ),
              ),

              // List View FAB (placed before card so card appears on top)
              Positioned(
                bottom: 24,
                left: 16,
                child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(); // Return to list view
                        } else {
                          // Switch to Home tab (index 0) via provider
                          ref.read(dashboardTabIndexProvider.notifier).setTab(0);
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.format_list_bulleted, color: Colors.black87, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "List View",
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Pet Detail Card (Slide Up) - placed last to be on top
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: 16,
                right: 16,
                bottom: _selectedPet != null ? 24 : -300,
                child: _selectedPet != null
                    ? _buildPetDetailCard(context, _selectedPet!)
                    : const SizedBox.shrink(),
              ),

            ],
          );
        },
        error: (err, stack) => Center(child: Text('Error loading map: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMapFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetDetailCard(BuildContext context, Pet pet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet Image
                Hero(
                  tag: 'pet_image_${pet.id}',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: pet.imageUrl != null
                        ? Image.network(
                            pet.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),

                const SizedBox(width: 16),

                // Pet Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: pet.status == 'LOST'
                                ? [Colors.red, Colors.red.shade700]
                                : [AppTheme.primaryGreen, AppTheme.primaryGreen.withGreen(150)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pet.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Name
                      Text(
                        pet.name ?? pet.species,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Species & Color
                      Row(
                        children: [
                          Icon(Icons.pets, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            pet.species,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          if (pet.colorMain != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.palette, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              pet.colorMain!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Time ago
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeAgo(pet.createdAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                GestureDetector(
                  onTap: _clearSelection,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // View Details Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "View Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.pets, color: Colors.grey[400], size: 40),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return '${diff.inMinutes} min ago';
  }

  Widget _buildMarkerContent(Pet pet) {
    final species = pet.species.trim().toLowerCase();
    // If it's a Cat or Dog, show the specific image
    if (species.contains('cat') || species.contains('dog')) {
      final imagePath = species.contains('cat') 
          ? 'assets/icon.png' // Use verified app icon
          : 'assets/doggy.jpg';
      
      return Padding(
        padding: const EdgeInsets.all(2.0), // Padding to show the status color ring
        child: ClipOval(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            cacheWidth: 150, // Optimize memory for large assets
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.pets, color: Colors.orange[200], size: 20); // Fallback if image fails
            },
          ),
        ),
      );
    }
    
    // Default Icon for others
    return Icon(
      Icons.pets,
      color: Colors.white,
      size: _selectedPet?.id == pet.id ? 26 : 22,
    );
  }
}
