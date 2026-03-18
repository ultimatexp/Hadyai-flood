import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/search_match.dart';
import '../data/gemini_service.dart';
import 'pet_detail_screen.dart';

class SemanticSearchScreen extends StatefulWidget {
  final XFile? initialImage;
  final bool asHomeTab;
  const SemanticSearchScreen({super.key, this.initialImage, this.asHomeTab = false});

  @override
  State<SemanticSearchScreen> createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen>
    with SingleTickerProviderStateMixin {
  final List<XFile> _selectedImages = [];
  bool _isSearching = false;
  List<SearchMatch> _allSearchResults = [];
  List<SearchMatch> _filteredResults = [];
  String? _errorMessage;
  String? _statusMessage;

  // Filter state
  double _radiusKm = 50;
  String? _selectedSex;

  final GeminiService _gemini = GeminiService();

  // Social proof: recent pets
  List<Map<String, dynamic>> _recentPets = [];
  bool _loadingRecentPets = false;

  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fetchRecentPets();
    if (widget.initialImage != null) {
      _selectedImages.add(widget.initialImage!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecentPets() async {
    setState(() => _loadingRecentPets = true);
    try {
      final response = await Supabase.instance.client
          .from('pets')
          .select('id, name, species, image_url, status, created_at')
          .order('created_at', ascending: false)
          .limit(6);
      setState(() {
        _recentPets = List<Map<String, dynamic>>.from(response);
        _loadingRecentPets = false;
      });
    } catch (e) {
      print('Failed to fetch recent pets: $e');
      setState(() => _loadingRecentPets = false);
    }
  }

  Future<void> _pickImages({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
        requestFullMetadata: false,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image picker error: $e')),
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _allSearchResults = [];
      _filteredResults = [];
      _statusMessage = "Step 1/2: Analyzing image with AI...";
    });

    try {
      List<SearchMatch> allMatches = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        setState(() => _statusMessage = "Step 1/2: Extracting features from image ${i + 1}...");

        Map<String, dynamic> features = {};
        try {
          features = await _gemini.analyzePetImage(image);
          print("Gemini extracted: $features");
        } catch (e) {
          print("Gemini analysis failed: $e");
        }

        setState(() => _statusMessage = "Step 2/2: Searching database...");

        final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/pet/search');
        print('🚀 Sending search request to: $uri');
        final request = http.MultipartRequest('POST', uri);

        request.files.add(await http.MultipartFile.fromPath('image', image.path));
        request.fields['type'] = 'lost';

        if (features['species'] != null) {
          request.fields['species'] = features['species'].toString().toLowerCase();
        }
        if (features['color'] != null) {
          request.fields['color_main'] = features['color'].toString().toLowerCase();
        }
        if (features['color_pattern'] != null) {
          request.fields['color_pattern'] = features['color_pattern'].toString().toLowerCase();
        }
        if (features['fur_length'] != null) {
          request.fields['fur_length'] = features['fur_length'].toString().toLowerCase();
        }
        if (_selectedSex == null && features['sex'] != null && features['sex'] != 'Unknown') {
          request.fields['sex'] = features['sex'].toString().toLowerCase();
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ API Response: ${data['matches']?.length ?? 0} matches found');
          if (data['success'] == true) {
            final matches = (data['matches'] as List).map((m) => SearchMatch.fromJson(m)).toList();
            allMatches.addAll(matches);
          }
        } else {
          print("❌ API Error (${response.statusCode}): ${response.body}");
          _errorMessage = "API Error: ${response.statusCode}";
        }
      }

      final Map<String, SearchMatch> uniqueMatches = {};
      for (var match in allMatches) {
        final existing = uniqueMatches[match.pet.id];
        if (existing == null || match.combinedScore > existing.combinedScore) {
          uniqueMatches[match.pet.id] = match;
        }
      }

      final sortedMatches = uniqueMatches.values.toList()
        ..sort((a, b) => b.combinedScore.compareTo(a.combinedScore));

      setState(() {
        _allSearchResults = sortedMatches;
        _applyFilters();
        _statusMessage = null;
        if (_allSearchResults.isEmpty && _errorMessage == null) {
          _errorMessage = "No matching pets found (Try adjusting filters).";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Search failed: $e";
        _statusMessage = null;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _applyFilters() {
    _filteredResults = _allSearchResults.where((match) {
      if (_selectedSex != null) {
        final petSex = match.pet.sex?.toLowerCase();
        if (petSex != _selectedSex) return false;
      }
      return true;
    }).toList();
  }

  void _onFilterChanged() {
    setState(() {
      _applyFilters();
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  // Whether to show filters bottom sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.tune, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  const Text('ตัวกรอง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              // Radius
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('รัศมี: ', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  Text('${_radiusKm.round()} km',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              StatefulBuilder(
                builder: (context, setSheetState) => Slider(
                  value: _radiusKm,
                  min: 5,
                  max: 200,
                  divisions: 39,
                  activeColor: AppTheme.accentOrange,
                  onChanged: (value) {
                    setSheetState(() {});
                    setState(() => _radiusKm = value);
                    _onFilterChanged();
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Sex
              Row(
                children: [
                  const Icon(Icons.pets, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('เพศ: ', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  _buildSexChip('ทั้งหมด', null),
                  _buildSexChip('ผู้', 'male'),
                  _buildSexChip('เมีย', 'female'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasResults = _allSearchResults.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.asHomeTab,
        title: Text(widget.asHomeTab ? '🐾 ค้นหาสัตว์เลี้ยง' : 'Smart Pet Search'),
        // Algorithm pills hidden
      ),
      body: Column(
        children: [
          // 1. Upload: full when no results, compact when results exist
          if (hasResults)
            _buildCompactUploadBar()
          else
            _buildUploadSection(),

          // 2. Results header with count + filter
          if (hasResults) _buildResultsHeader(),

          // 3. Results / Empty State
          Expanded(
            child: _isSearching
                ? _buildSearchingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _allSearchResults.isEmpty
                        ? _buildEmptyState()
                        : _filteredResults.isEmpty
                            ? _buildNoFilterResultsState()
                            : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  // ── Compact Upload Bar (shown after search) ────────────────
  Widget _buildCompactUploadBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnails of uploaded images
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_selectedImages[i].path),
                  width: 40, height: 40, fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Add more photos
          IconButton(
            icon: Icon(Icons.add_photo_alternate_rounded, color: AppTheme.accentOrange),
            onPressed: () => _pickImages(),
            visualDensity: VisualDensity.compact,
          ),
          // Re-search button
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _performSearch,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('ค้นหาใหม่', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results Header ─────────────────────────────────────────
  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            'พบ ${_filteredResults.length} รายการ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          if (_filteredResults.length != _allSearchResults.length)
            Text(
              ' (จาก ${_allSearchResults.length})',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          const Spacer(),
          Material(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _showFilterSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('ตัวกรอง', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Algorithm Pill Chips ─────────────────────────────────
  Widget _buildAlgorithmPills() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _algorithmPill('🧠', 'AI Vision', '40%', const Color(0xFF9C27B0)),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.grey[300]),
          const SizedBox(width: 8),
          _algorithmPill('🎨', 'Color', '30%', AppTheme.accentOrange),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.grey[300]),
          const SizedBox(width: 8),
          _algorithmPill('📐', 'Features', '30%', const Color(0xFF42A5F5)),
        ],
      ),
    );
  }

  Widget _algorithmPill(String emoji, String label, String percent, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$label $percent',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Upload Section ──────────────────────────────────────
  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.orange.withOpacity(0.03)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with camera button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "อัพโหลดรูปสัตว์เลี้ยง",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "รูปหลายรูป = ค้นหาแม่นยำขึ้น 📸",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Camera quick-action button
              Material(
                color: AppTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pickImages(source: ImageSource.camera),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.accentOrange,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Upload area
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return GestureDetector(
                      onTap: () => _pickImages(),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: AppTheme.accentOrange, size: 28),
                            const SizedBox(height: 4),
                            Text('เพิ่มรูป',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            GestureDetector(
              onTap: () => _pickImages(),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentOrange.withOpacity(0.05),
                      AppTheme.primaryGreen.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.accentOrange.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        size: 32,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'แตะเพื่ออัพโหลดรูปภาพ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'หรือถ่ายรูปจากกล้อง 📷',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Search Button - Full width, bold orange
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _selectedImages.isNotEmpty && !_isSearching
                  ? 1.0 + (_pulseController.value * 0.015)
                  : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSearching || _selectedImages.isEmpty ? null : _performSearch,
                icon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search_rounded, size: 22),
                label: Text(
                  _isSearching ? 'กำลังค้นหา...' : 'ค้นหาสัตว์เลี้ยง',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: _selectedImages.isNotEmpty ? 4 : 0,
                  shadowColor: AppTheme.accentOrange.withOpacity(0.4),
                ),
              ),
            ),
          ),

          // Filters moved to bottom sheet
        ],
      ),
    );
  }

  // ── 3. Empty State with Step Indicators + Social Proof ────
  Widget _buildEmptyState() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 90;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
      child: Column(
        children: [
          // Colorful Lottie
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset('assets/lottie/ck pets world.json'),
          ),
          const SizedBox(height: 12),
          const Text(
            'ค้นหาสัตว์เลี้ยงด้วย AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'อัพโหลดรูปสัตว์เลี้ยงเพื่อค้นหาสัตว์ที่คล้ายกัน',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),
          // Step Indicators
          _buildStepIndicators(),

          // Social Proof Section
          if (_recentPets.isNotEmpty || _loadingRecentPets) ...[
            const SizedBox(height: 20),
            _buildSocialProofSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepPill('①', 'อัพโหลด', AppTheme.accentOrange),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[400]),
        ),
        _stepPill('②', 'วิเคราะห์', const Color(0xFF9C27B0)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[400]),
        ),
        _stepPill('③', 'จับคู่', AppTheme.primaryGreen),
      ],
    );
  }

  Widget _stepPill(String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(number, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ── 6. Social Proof Section ────────────────────────────────
  Widget _buildSocialProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 6),
            Text(
              'สัตว์เลี้ยงที่ลงทะเบียนล่าสุด',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingRecentPets)
          const Center(child: CircularProgressIndicator(strokeWidth: 2))
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentPets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final pet = _recentPets[index];
                return _buildRecentPetCard(pet);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentPetCard(Map<String, dynamic> pet) {
    final imageUrl = pet['image_url'] as String?;
    final name = pet['name'] as String? ?? pet['species'] as String? ?? 'Pet';
    final species = pet['species'] as String? ?? '';
    final status = pet['status'] as String? ?? '';
    final isLost = status.toUpperCase() == 'LOST';

    return Container(
      width: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 85,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[200], child: const Icon(Icons.pets, size: 24)),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.pets, size: 24, color: Colors.grey),
                    ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isLost ? Colors.red.withOpacity(0.05) : AppTheme.primaryGreen.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (species.isNotEmpty)
                  Text(
                    species,
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Searching State ────────────────────────────────────────
  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset('assets/lottie/Dog Paw Loading.json'),
          ),
          const SizedBox(height: 24),
          _buildSearchStep(
            'Analyzing Image',
            Icons.camera_alt,
            _statusMessage?.contains('1/2') ?? false,
            _statusMessage?.contains('2/2') ?? false,
          ),
          const SizedBox(height: 12),
          _buildSearchStep(
            'Searching Database',
            Icons.search,
            _statusMessage?.contains('2/2') ?? false,
            false,
          ),
        ],
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_errorMessage!,
            style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      ),
    );
  }

  // ── No Filter Results ──────────────────────────────────────
  Widget _buildNoFilterResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text("No results match your filters", style: TextStyle(color: Colors.grey[600])),
          Text("Found ${_allSearchResults.length} results before filtering",
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  // ── Results List ───────────────────────────────────────────
  Widget _buildResultsList() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 90;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      itemCount: _filteredResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final match = _filteredResults[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey(match.pet.id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 600)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _buildMatchCard(context, match),
        );
      },
    );
  }

  // ── Match Card (Option A: Hero Image) ─────────────────────
  Widget _buildMatchCard(BuildContext context, SearchMatch match) {
    final scoreColor = _getScoreColor(match.combinedScore);
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailScreen(pet: match.pet)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Image with overlay badges ──
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: match.pet.imageUrl != null
                      ? Image.network(
                          match.pet.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.pets, size: 60, color: Colors.grey)),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.pets, size: 60, color: Colors.grey)),
                        ),
                ),
                // Gradient overlay at bottom for readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                      ),
                    ),
                  ),
                ),
                // Status badge (top-left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: match.pet.status == 'LOST'
                          ? Colors.red.withOpacity(0.9)
                          : AppTheme.primaryGreen.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.pet.status == 'LOST' ? '🔴 หาย' : '🟢 พบ',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Match score ring (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildScoreRing(match.matchPercent, scoreColor),
                ),
                // Pet name overlay (bottom-left)
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.pet.name ?? match.pet.species,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                        ),
                      ),
                      Text(
                        '${match.pet.species} • ${match.pet.colorMain ?? ""}'.trim(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── Score breakdown bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  _buildScoreBar('🧠 AI', match.embeddingPercent, const Color(0xFF9C27B0)),
                  const SizedBox(width: 8),
                  _buildScoreBar('🎨 สี', match.colorPercent, AppTheme.accentOrange),
                  const SizedBox(width: 8),
                  _buildScoreBar('📐 ลักษณะ', match.featurePercent, const Color(0xFF42A5F5)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Circular Score Ring ─────────────────────────────────────
  Widget _buildScoreRing(int percent, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: percent / 100.0,
              strokeWidth: 3.5,
              backgroundColor: Colors.grey[200],
              color: color,
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Score Bar (compact) ────────────────────────────────────
  Widget _buildScoreBar(String label, int percent, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(width: 3),
          Text('$percent%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.85) return AppTheme.primaryGreen;
    if (score >= 0.8) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSexChip(String label, String? value) {
    final isSelected = _selectedSex == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSex = value);
        _onFilterChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchStep(String label, IconData icon, bool isActive, bool isCompleted) {
    final color = isCompleted
        ? AppTheme.primaryGreen
        : isActive
            ? AppTheme.accentOrange
            : Colors.grey[400]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted || isActive ? color.withOpacity(0.15) : Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted ? Colors.black87 : Colors.grey[500],
          ),
        ),
        if (isActive && !isCompleted) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accentOrange,
            ),
          ),
        ],
      ],
    );
  }
}
