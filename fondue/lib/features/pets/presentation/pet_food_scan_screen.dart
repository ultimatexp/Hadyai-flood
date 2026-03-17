import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/pet_profile.dart';
import '../domain/food_scan_result.dart';
import 'pet_profile_providers.dart';
import 'food_scan_providers.dart';
import 'food_analysis_result_screen.dart';
import 'food_scan_history_screen.dart';

class PetFoodScanScreen extends ConsumerStatefulWidget {
  final String? preSelectedPetId;

  const PetFoodScanScreen({super.key, this.preSelectedPetId});

  @override
  ConsumerState<PetFoodScanScreen> createState() => _PetFoodScanScreenState();
}

class _PetFoodScanScreenState extends ConsumerState<PetFoodScanScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedPetId;
  bool _isAnalyzing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.preSelectedPetId;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petProfilesAsync = ref.watch(myPetProfilesProvider);
    final analysisState = ref.watch(foodAnalysisProvider);

    // Listen for result → navigate
    ref.listen<FoodAnalysisState>(foodAnalysisProvider, (prev, next) {
      if (next.status == FoodAnalysisStatus.result && next.result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodAnalysisResultScreen(result: next.result!),
          ),
        );
        ref.read(foodAnalysisProvider.notifier).reset();
        setState(() => _isAnalyzing = false);
      } else if (next.status == FoodAnalysisStatus.error) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Analysis failed'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(foodAnalysisProvider.notifier).reset();
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Pet Selector
                  petProfilesAsync.when(
                    data: (pets) {
                      if (pets.isEmpty) return _buildNoPetsCard();
                      // Auto-select first pet if none selected
                      if (_selectedPetId == null && pets.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => _selectedPetId = pets.first.id);
                        });
                      }
                      return _buildPetSelector(pets);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 24),

                  // Scan Area
                  _buildScanArea(analysisState),
                  const SizedBox(height: 28),

                  // Recent Scans Section
                  if (_selectedPetId != null) _buildRecentScansSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Food Scanner',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan a pet food label to check if it\'s safe',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_selectedPetId != null)
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Scan History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodScanHistoryScreen(
                    petProfileId: _selectedPetId!,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPetSelector(List<PetProfile> pets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Pet',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final pet = pets[index];
              final isSelected = _selectedPetId == pet.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPetId = pet.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E7D32).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: pet.avatarUrl != null
                            ? NetworkImage(pet.avatarUrl!)
                            : null,
                        child: pet.avatarUrl == null
                            ? Icon(
                                pet.species == 'Cat'
                                    ? Icons.catching_pokemon
                                    : Icons.pets,
                                color: Colors.grey[500],
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isSelected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            '${pet.species} ${pet.breed != null ? "• ${pet.breed}" : ""}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoPetsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.pets, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          Text(
            'No pet profiles yet',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a pet profile first to analyze food suitability',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea(FoodAnalysisState analysisState) {
    final isScanning = analysisState.status == FoodAnalysisStatus.scanning ||
        _isAnalyzing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan Food Label',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: isScanning || _selectedPetId == null
              ? null
              : () => _showCaptureOptions(),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isScanning ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: isScanning
                    ? const Color(0xFF2E7D32).withOpacity(0.05)
                    : _selectedPetId == null
                        ? Colors.grey[100]
                        : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isScanning
                      ? const Color(0xFF2E7D32)
                      : _selectedPetId == null
                          ? Colors.grey[300]!
                          : const Color(0xFF2E7D32).withOpacity(0.3),
                  width: isScanning ? 2 : 1.5,
                  // dashed border effect through custom paint
                ),
              ),
              child: isScanning
                  ? _buildScanningState()
                  : _buildIdleState(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState() {
    final isEnabled = _selectedPetId != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF2E7D32).withOpacity(0.08)
                : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.camera_alt_rounded,
            size: 40,
            color: isEnabled
                ? const Color(0xFF2E7D32)
                : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isEnabled ? 'Tap to scan food label' : 'Select a pet first',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.black87 : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEnabled
              ? 'Take a photo or pick from gallery'
              : 'You need to select a pet to analyze food for',
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildScanningState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF2E7D32).withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Analyzing ingredients...',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI is checking food safety for your pet',
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showCaptureOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                ),
                title: Text('Take Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('Capture food label with camera', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAnalyze(ImageSource.camera);
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFFFF9800)),
                ),
                title: Text('Choose from Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                subtitle: Text('Pick a food label photo', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAnalyze(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // Get pet profile
      final petProfile =
          await ref.read(petProfileProvider(_selectedPetId!).future);
      if (petProfile == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      // Upload image
      final repo = ref.read(foodScanRepositoryProvider);
      final imageUrl = await repo.uploadFoodImage(pickedFile);

      // Read bytes
      final imageBytes = await pickedFile.readAsBytes();

      // Analyze
      ref.read(foodAnalysisProvider.notifier).analyzeFood(
            imageBytes: imageBytes,
            petProfileId: petProfile.id,
            species: petProfile.species,
            breed: petProfile.breed,
            ageText: petProfile.ageText,
            weightKg: petProfile.weightKg,
            allergies: petProfile.allergies,
            conditions: petProfile.conditions,
            imageUrl: imageUrl,
          );
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildRecentScansSection() {
    final recentScansAsync = ref.watch(foodScanHistoryProvider(_selectedPetId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Scans',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodScanHistoryScreen(
                      petProfileId: _selectedPetId!,
                    ),
                  ),
                );
              },
              child: Text(
                'See All',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        recentScansAsync.when(
          data: (scans) {
            if (scans.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 36, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'No scans yet for this pet',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final displayScans = scans.take(5).toList();
            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayScans.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                    _buildRecentScanCard(displayScans[index]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildRecentScanCard(FoodScanResult scan) {
    Color verdictColor;
    IconData verdictIcon;
    switch (scan.verdict) {
      case 'SUITABLE':
        verdictColor = const Color(0xFF4CAF50);
        verdictIcon = Icons.check_circle;
        break;
      case 'NOT_RECOMMENDED':
        verdictColor = const Color(0xFFEF5350);
        verdictIcon = Icons.cancel;
        break;
      default:
        verdictColor = const Color(0xFFFFC107);
        verdictIcon = Icons.warning_rounded;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodAnalysisResultScreen(result: scan),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: verdictColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: verdictColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(verdictIcon, size: 18, color: verdictColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scan.verdict.replaceAll('_', ' '),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: verdictColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scan.productName ?? 'Unknown Food',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: verdictColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${scan.score}/10',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: verdictColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
