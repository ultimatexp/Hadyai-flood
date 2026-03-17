import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/pet_profile.dart';
import '../domain/medical_record.dart';
import 'pet_profile_providers.dart';
import 'create_pet_profile_screen.dart';
import 'pet_medical_screen.dart';
import 'vaccine_schedule_screen.dart';
import 'vaccine_providers.dart';
import 'pet_food_scan_screen.dart';

class PetProfileScreen extends ConsumerStatefulWidget {
  final String petProfileId;
  const PetProfileScreen({super.key, required this.petProfileId});

  @override
  ConsumerState<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends ConsumerState<PetProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(petProfileProvider(widget.petProfileId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
        body: Center(child: Text('Error: $err')),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
            body: const Center(child: Text('Pet profile not found')),
          );
        }
        return _buildProfileUI(context, profile, isDark);
      },
    );
  }

  Widget _buildProfileUI(BuildContext context, PetProfile profile, bool isDark) {
    final allImages = profile.images.isNotEmpty
        ? profile.images
        : (profile.avatarUrl != null ? [profile.avatarUrl!] : <String>[]);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // ═══════════════════════════════
          // HERO IMAGE SECTION
          // ═══════════════════════════════
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  // TODO: Generate QR / Share
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('แชร์โปรไฟล์สัตว์เลี้ยง (เร็วๆ นี้)')),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: allImages.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        PageView.builder(
                          itemCount: allImages.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (context, index) {
                            return Image.network(
                              allImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.pets, size: 80, color: Colors.white),
                              ),
                            );
                          },
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                              ),
                            ),
                          ),
                        ),
                        // Image dots indicator
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 60,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(allImages.length, (i) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _currentImageIndex == i ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentImageIndex == i
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                );
                              }),
                            ),
                          ),
                        // Name overlay
                        Positioned(
                          bottom: 16,
                          left: 20,
                          right: 20,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildChip(profile.species, Icons.pets),
                                        if (profile.breed != null) ...[
                                          const SizedBox(width: 6),
                                          _buildChip(profile.breed!, Icons.category),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: isDark ? AppTheme.cardDark : Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.pets, size: 80, color: Colors.grey[400]),
                      ),
                    ),
            ),
          ),

          // ═══════════════════════════════
          // QUICK STATS BAR
          // ═══════════════════════════════
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Expanded(
                    child: _buildQuickStat(
                      Icons.cake_outlined,
                      'อายุ',
                      profile.ageText,
                      isDark,
                    ),
                  ),
                  _divider(isDark),
                  Expanded(
                    child: _buildQuickStat(
                      profile.sex == 'male' ? Icons.male : (profile.sex == 'female' ? Icons.female : Icons.help_outline),
                      'เพศ',
                      profile.sex == 'male' ? 'ผู้' : (profile.sex == 'female' ? 'เมีย' : 'ไม่ทราบ'),
                      isDark,
                    ),
                  ),
                  _divider(isDark),
                  Expanded(
                    child: _buildQuickStat(
                      Icons.monitor_weight_outlined,
                      'น้ำหนัก',
                      profile.weightKg != null ? '${profile.weightKg} kg' : '-',
                      isDark,
                    ),
                  ),
                  _divider(isDark),
                  Expanded(
                    child: _buildQuickStat(
                      Icons.straighten,
                      'ขนาด',
                      _sizeLabel(profile.bodySize),
                      isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════
          // FOOD SCANNER ACTION
          // ═══════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetFoodScanScreen(
                        preSelectedPetId: profile.id,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E7D32).withOpacity(0.08),
                        const Color(0xFF66BB6A).withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔍 Food Scanner',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Scan food labels to check safety',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ═══════════════════════════════
          // TABS
          // ═══════════════════════════════
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.accentOrange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.accentOrange,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'ข้อมูล'),
                  Tab(icon: Icon(Icons.photo_library_outlined), text: 'แกลเลอรี'),
                  Tab(icon: Icon(Icons.medical_services_outlined), text: 'สุขภาพ'),
                ],
              ),
            ),
          ),

          // TAB CONTENT
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(profile, isDark),
                _buildGalleryTab(profile, isDark),
                _buildMedicalTab(profile, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Overview Tab ──────────────────────────────────────────────
  Widget _buildOverviewTab(PetProfile profile, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            _buildSectionTitle('เกี่ยวกับ', Icons.auto_awesome, isDark),
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Personality Traits
          if (profile.personalityTraits.isNotEmpty) ...[
            _buildSectionTitle('บุคลิกภาพ', Icons.emoji_emotions_outlined, isDark),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.personalityTraits.map((trait) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentOrange.withOpacity(0.15),
                        AppTheme.accentOrange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                  ),
                  child: Text(
                    trait,
                    style: TextStyle(
                      color: isDark ? Colors.orange[200] : Colors.orange[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Physical Details
          _buildSectionTitle('ลักษณะทางกายภาพ', Icons.palette_outlined, isDark),
          const SizedBox(height: 10),
          _buildDetailGrid(profile, isDark),

          const SizedBox(height: 20),

          // Medical Flags
          _buildSectionTitle('สถานะสุขภาพ', Icons.health_and_safety_outlined, isDark),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(
                profile.isNeutered ? 'ทำหมันแล้ว ✓' : 'ยังไม่ทำหมัน',
                profile.isNeutered ? Colors.green : Colors.orange,
                isDark,
              ),
              if (profile.microchipNumber != null)
                _buildStatusBadge(
                  'มีไมโครชิป 📟',
                  Colors.blue,
                  isDark,
                ),
              if (profile.allergies.isNotEmpty)
                _buildStatusBadge(
                  'มีอาการแพ้ ⚠️',
                  Colors.red,
                  isDark,
                ),
            ],
          ),

          // Allergies
          if (profile.allergies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'อาการแพ้:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            ...profile.allergies.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.red[300]),
                  const SizedBox(width: 8),
                  Text(a, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700])),
                ],
              ),
            )),
          ],

          // Conditions
          if (profile.conditions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'โรคประจำตัว:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            ...profile.conditions.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.medical_information, size: 16, color: Colors.blue[300]),
                  const SizedBox(width: 8),
                  Text(c, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700])),
                ],
              ),
            )),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Gallery Tab ───────────────────────────────────────────────
  Widget _buildGalleryTab(PetProfile profile, bool isDark) {
    final images = profile.images;
    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('ยังไม่มีรูปภาพ', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _showFullScreenImage(context, images, index);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Medical Tab ───────────────────────────────────────────────
  Widget _buildMedicalTab(PetProfile profile, bool isDark) {
    final recordsAsync = ref.watch(medicalRecordsProvider(profile.id));

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('ยังไม่มีบันทึกสุขภาพ', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VaccineScheduleScreen(
                        petProfileId: profile.id,
                        petName: profile.name,
                        species: profile.species,
                      ),
                    ),
                  ).then((_) => ref.invalidate(medicalRecordsProvider(profile.id))),
                  icon: const Icon(Icons.vaccines, size: 18),
                  label: const Text('ดูตารางวัคซีน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF533483),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddMedicalRecord(profile),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('เพิ่มบันทึก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        // Group by type
        final vaccinations = records.where((r) => r.recordType == 'vaccination').toList();
        final overdueVaccinations = vaccinations.where((r) => r.isOverdue).toList();
        final dueSoon = vaccinations.where((r) => r.isDueSoon).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vaccine schedule hero card
              _buildVaccineScheduleCard(profile, isDark),
              const SizedBox(height: 12),
              // Overdue alert
              if (overdueVaccinations.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${overdueVaccinations.length} วัคซีนเกินกำหนด!',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Due soon alert
              if (dueSoon.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.amber[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${dueSoon.length} วัคซีนใกล้ถึงกำหนด',
                          style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Records list
              ...records.map((record) => _buildMedicalRecordCard(record, isDark)),

              const SizedBox(height: 16),

              // Add button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddMedicalRecord(profile),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('เพิ่มบันทึก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record, bool isDark) {
    final dateStr = DateFormat('d MMM yyyy').format(record.date);
    final iconData = _recordTypeIcon(record.recordType);
    final color = _recordTypeColor(record.recordType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.recordTypeLabel} • $dateStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                if (record.nextDueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        record.isOverdue ? Icons.error_outline : Icons.schedule,
                        size: 14,
                        color: record.isOverdue ? Colors.red : Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ครั้งถัดไป: ${DateFormat('d MMM yyyy').format(record.nextDueDate!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: record.isOverdue ? Colors.red : Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vaccine Schedule Card ──────────────────────────────────────
  Widget _buildVaccineScheduleCard(PetProfile profile, bool isDark) {
    final scheduleAsync = ref.watch(vaccineScheduleProvider(profile.id));

    return scheduleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedule) {
        final percentage = (schedule.shieldScore * 100).round();
        final scoreColor = schedule.shieldScore >= 0.8
            ? Colors.green
            : (schedule.shieldScore >= 0.5 ? Colors.amber : Colors.red);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VaccineScheduleScreen(
                  petProfileId: profile.id,
                  petName: profile.name,
                  species: profile.species,
                ),
              ),
            ).then((_) {
              ref.invalidate(medicalRecordsProvider(profile.id));
              ref.invalidate(vaccineScheduleProvider(profile.id));
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFF0F3460), const Color(0xFF533483)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF533483).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Mini shield gauge
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: schedule.shieldScore,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      ),
                      Text('🛡️', style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ตารางวัคซีน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ป้องกัน $percentage% • ${schedule.overdueCount > 0 ? "${schedule.overdueCount} เกินกำหนด" : "ครบตามกำหนด"}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.6)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.accentOrange),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? Colors.grey[700] : Colors.grey[200],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGrid(PetProfile profile, bool isDark) {
    final details = <MapEntry<String, String>>[
      if (profile.colorMain != null) MapEntry('สีหลัก', profile.colorMain!),
      if (profile.colorSecondary != null) MapEntry('สีรอง', profile.colorSecondary!),
      if (profile.furLength != null) MapEntry('ความยาวขน', profile.furLength!),
      if (profile.eyeColor != null) MapEntry('สีตา', profile.eyeColor!),
      if (profile.microchipNumber != null) MapEntry('ไมโครชิป', profile.microchipNumber!),
    ];

    if (details.isEmpty) {
      return Text(
        'ยังไม่ได้เพิ่มข้อมูลลักษณะทางกายภาพ',
        style: TextStyle(color: Colors.grey[500], fontSize: 14),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                entry.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _sizeLabel(String? size) {
    switch (size) {
      case 'small':
        return 'เล็ก';
      case 'medium':
        return 'กลาง';
      case 'large':
        return 'ใหญ่';
      default:
        return '-';
    }
  }

  IconData _recordTypeIcon(String type) {
    switch (type) {
      case 'vaccination':
        return Icons.vaccines;
      case 'vet_visit':
        return Icons.local_hospital;
      case 'medication':
        return Icons.medication;
      case 'weight_log':
        return Icons.monitor_weight;
      case 'note':
        return Icons.note_alt;
      default:
        return Icons.description;
    }
  }

  Color _recordTypeColor(String type) {
    switch (type) {
      case 'vaccination':
        return Colors.blue;
      case 'vet_visit':
        return Colors.green;
      case 'medication':
        return Colors.purple;
      case 'weight_log':
        return Colors.teal;
      case 'note':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _navigateToAddMedicalRecord(PetProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetMedicalScreen(petProfileId: profile.id, petName: profile.name),
      ),
    ).then((_) {
      ref.invalidate(medicalRecordsProvider(profile.id));
    });
  }

  void _showFullScreenImage(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

// ═══════════════════════════════════════
// FULL SCREEN GALLERY
// ═══════════════════════════════════════
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
