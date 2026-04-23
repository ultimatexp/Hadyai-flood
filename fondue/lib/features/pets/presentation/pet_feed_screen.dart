import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fondue/l10n/app_localizations.dart';
import 'package:fondue/l10n/app_localizations_context.dart';
import 'package:lottie/lottie.dart';
import 'pet_providers.dart';
import '../domain/pet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/shimmer_loading.dart';
import 'pet_detail_screen.dart';
import 'pet_search_navigation.dart';
import 'map_view_screen.dart';
import 'widgets/pet_card.dart';

import '../domain/pet_matcher_service.dart';

class PetFeedScreen extends ConsumerStatefulWidget {
  const PetFeedScreen({super.key});

  @override
  ConsumerState<PetFeedScreen> createState() => _PetFeedScreenState();
}

class _PetFeedScreenState extends ConsumerState<PetFeedScreen> {
  static const String _gridPrefKey = 'pet_feed_grid_view';
  static const String _rewardOnlyPrefKey = 'pet_feed_reward_only';
  static const String _todayOnlyPrefKey = 'pet_feed_today_only';
  static const String _statusPrefKey = 'pet_feed_status';
  static const String _speciesPrefKey = 'pet_feed_species';

  bool _hasCheckedMatches = false;
  bool _isGridView = false;
  bool _rewardOnly = false;
  bool _todayOnly = false;

  @override
  void initState() {
    super.initState();
    _restoreViewPreference();
    // Check for matches slightly after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForMatches();
    });
  }

  Future<void> _restoreViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final savedGrid = prefs.getBool(_gridPrefKey);
    final savedRewardOnly = prefs.getBool(_rewardOnlyPrefKey);
    final savedTodayOnly = prefs.getBool(_todayOnlyPrefKey);
    final savedStatus = prefs.getString(_statusPrefKey);
    final savedSpecies = prefs.getString(_speciesPrefKey);

    if (savedGrid != null || savedRewardOnly != null || savedTodayOnly != null) {
      setState(() {
        if (savedGrid != null) _isGridView = savedGrid;
        if (savedRewardOnly != null) _rewardOnly = savedRewardOnly;
        if (savedTodayOnly != null) _todayOnly = savedTodayOnly;
      });
    }

    final currentFilter = ref.read(petFilterProvider);
    ref.read(petFilterProvider.notifier).setFilter(
      currentFilter.copyWith(
        status: savedStatus ?? currentFilter.status,
        species: savedSpecies ?? currentFilter.species,
      ),
    );
  }

  Future<void> _persistFeedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final filter = ref.read(petFilterProvider);
    await prefs.setBool(_gridPrefKey, _isGridView);
    await prefs.setBool(_rewardOnlyPrefKey, _rewardOnly);
    await prefs.setBool(_todayOnlyPrefKey, _todayOnly);
    await prefs.setString(_statusPrefKey, filter.status);
    await prefs.setString(_speciesPrefKey, filter.species);
  }

  Future<void> _setFilterAndPersist(PetFilter next) async {
    ref.read(petFilterProvider.notifier).setFilter(next);
    await _persistFeedPrefs();
  }

  Future<void> _toggleGridView() async {
    final next = !_isGridView;
    setState(() => _isGridView = next);
    await _persistFeedPrefs();
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year && value.month == now.month && value.day == now.day;
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
      builder: (ctx) {
        final d = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notification_important, color: Colors.amber),
              const SizedBox(width: 8),
              Flexible(child: Text(d.petFeedMatchDialogTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.petFeedMatchDialogBody(lostPet.species, lostPet.name ?? d.petFeedDefaultPetName)),
              const SizedBox(height: 16),
              Text(d.petFeedFoundPetDetails, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        Text(foundPet.description ?? d.petFeedNoDescription),
                        Text(
                          d.petFeedColorLabel(foundPet.colorMain ?? d.petFeedUnknownValue),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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
              child: Text(d.petFeedDismiss),
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
              child: Text(d.petFeedViewFoundPet),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lostPetsAsync = ref.watch(paginatedLostPetsProvider);
    final filter = ref.watch(petFilterProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.petFeedTitle),
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
            tooltip: l10n.petFeedMapTooltip,
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
                switchToHomePetSearch(ref, context);
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
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        l10n.petFeedSearch,
                        style: const TextStyle(
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
                  label: _isGridView ? 'Grid 3x' : 'List',
                  isSelected: _isGridView,
                  icon: _isGridView ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                  onTap: _toggleGridView,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: 'Reward only',
                  isSelected: _rewardOnly,
                  color: Colors.amber[700],
                  icon: Icons.monetization_on_outlined,
                  onTap: () async {
                    setState(() => _rewardOnly = !_rewardOnly);
                    await _persistFeedPrefs();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: 'Today only',
                  isSelected: _todayOnly,
                  color: Colors.blue,
                  icon: Icons.today_outlined,
                  onTap: () async {
                    setState(() => _todayOnly = !_todayOnly);
                    await _persistFeedPrefs();
                  },
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: Colors.grey[300]),
                const SizedBox(width: 16),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: l10n.petFilterAll, 
                  isSelected: filter.status == 'All',
                  onTap: () => _setFilterAndPersist(filter.copyWith(status: 'All')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: l10n.petFilterLost, 
                  isSelected: filter.status == 'LOST',
                  color: Colors.red,
                  onTap: () => _setFilterAndPersist(filter.copyWith(status: 'LOST')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: l10n.petFilterFound, 
                  isSelected: filter.status == 'FOUND',
                  color: AppTheme.primaryGreen,
                  onTap: () => _setFilterAndPersist(filter.copyWith(status: 'FOUND')),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: Colors.grey[300]), // Divider
                const SizedBox(width: 16),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: l10n.petFilterDogs, 
                  isSelected: filter.species == 'Dog',
                  icon: Icons.pets,
                  onTap: () => _setFilterAndPersist(
                    filter.copyWith(species: filter.species == 'Dog' ? 'All' : 'Dog'),
                  ),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context, 
                  ref, 
                  label: l10n.petFilterCats, 
                  isSelected: filter.species == 'Cat',
                  icon: Icons.pets,
                  onTap: () => _setFilterAndPersist(
                    filter.copyWith(species: filter.species == 'Cat' ? 'All' : 'Cat'),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Pet List
          Expanded(
            child: lostPetsAsync.when(
              data: (paged) {
                var pets = paged.pets;
                if (_rewardOnly) {
                  pets = pets.where((p) => (p.reward ?? 0) > 0).toList();
                }
                if (_todayOnly) {
                  pets = pets.where((p) => _isToday(p.createdAt)).toList();
                }
                if (pets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Lottie.asset('assets/lottie/Dog Paw Loading.json'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.petFeedEmptyTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.petFeedEmptySubtitle,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(paginatedLostPetsProvider.notifier).refresh();
                  },
                  color: AppTheme.accentOrange,
                  child: _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: pets.length + ((paged.hasMore || paged.isLoadingMore) ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= pets.length) {
                              if (paged.isLoadingMore) {
                                return const _GridLoadingTile();
                              }
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref.read(paginatedLostPetsProvider.notifier).loadMore();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.expand_more, color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            if (index >= pets.length - 6 && paged.hasMore && !paged.isLoadingMore) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.read(paginatedLostPetsProvider.notifier).loadMore();
                              });
                            }

                            final pet = pets[index];
                            return _PetSquareCard(pet: pet);
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: pets.length + ((paged.hasMore || paged.isLoadingMore) ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index >= pets.length) {
                              if (paged.isLoadingMore) {
                                return const PetCardSkeleton();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      ref.read(paginatedLostPetsProvider.notifier).loadMore();
                                    },
                                    icon: const Icon(Icons.expand_more),
                                    label: const Text('Load more'),
                                  ),
                                ),
                              );
                            }

                            if (index >= pets.length - 3 && paged.hasMore && !paged.isLoadingMore) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.read(paginatedLostPetsProvider.notifier).loadMore();
                              });
                            }

                            final pet = pets[index];
                            return PetCard(pet: pet);
                          },
                        ),
                );
              },
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(l10n.petFeedErrorTitle, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(paginatedLostPetsProvider),
                      child: Text(l10n.potentialMatchesRetry),
                    ),
                  ],
                ),
              ),
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, _) => const PetCardSkeleton(),
              ),
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

class _PetSquareCard extends StatelessWidget {
  final Pet pet;

  const _PetSquareCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (pet.imageUrl != null)
              Image.network(
                pet.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
              )
            else
              Container(color: Colors.grey[300]),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xAA000000)],
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Text(
                pet.titleForPreview(maxLen: 18, emptyFallback: 'Pet'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridLoadingTile extends StatelessWidget {
  const _GridLoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

