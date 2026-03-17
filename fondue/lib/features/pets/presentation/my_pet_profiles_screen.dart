import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/pet_profile.dart';
import 'pet_profile_providers.dart';
import 'pet_profile_screen.dart';
import 'create_pet_profile_screen.dart';

class MyPetProfilesScreen extends ConsumerWidget {
  const MyPetProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profilesAsync = ref.watch(myPetProfilesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        title: const Text('สัตว์เลี้ยงของฉัน'),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.selectionClick();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePetProfileScreen()),
          );
          if (result == true) {
            ref.invalidate(myPetProfilesProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสัตว์เลี้ยง'),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmptyState(context, ref, isDark);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myPetProfilesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return _buildPetCard(context, profiles[index], isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cute paw icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentOrange.withOpacity(0.15),
                    AppTheme.accentOrange.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, size: 56, color: AppTheme.accentOrange),
            ),
            const SizedBox(height: 24),
            Text(
              'ยังไม่มีโปรไฟล์สัตว์เลี้ยง',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'สร้างโปรไฟล์สัตว์เลี้ยงของคุณเพื่อ\nติดตามสุขภาพ จัดการรูปภาพ\nและแชร์ QR Code ให้คนช่วยค้นหาได้ง่าย',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.selectionClick();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePetProfileScreen()),
                );
                if (result == true) {
                  ref.invalidate(myPetProfilesProvider);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('สร้างโปรไฟล์สัตว์เลี้ยง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, PetProfile profile, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetProfileScreen(petProfileId: profile.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pet avatar
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: SizedBox(
                width: 110,
                height: 120,
                child: profile.avatarUrl != null
                    ? Image.network(
                        profile.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Species badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _speciesEmoji(profile.species),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Breed
                    if (profile.breed != null)
                      Text(
                        profile.breed!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Quick info chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildMiniChip(
                          profile.ageText,
                          Icons.cake_outlined,
                          isDark,
                        ),
                        _buildMiniChip(
                          profile.sex == 'male'
                              ? 'ผู้'
                              : (profile.sex == 'female' ? 'เมีย' : '?'),
                          profile.sex == 'male' ? Icons.male : Icons.female,
                          isDark,
                        ),
                        if (profile.weightKg != null)
                          _buildMiniChip(
                            '${profile.weightKg} kg',
                            Icons.monitor_weight_outlined,
                            isDark,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.accentOrange.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.pets, size: 40, color: AppTheme.accentOrange),
      ),
    );
  }

  Widget _buildMiniChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _speciesEmoji(String species) {
    switch (species) {
      case 'Dog': return '🐕';
      case 'Cat': return '🐈';
      case 'Bird': return '🐦';
      case 'Rabbit': return '🐰';
      default: return '🐾';
    }
  }
}
