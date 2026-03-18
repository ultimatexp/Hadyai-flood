import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
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

class _SemanticSearchScreenState extends State<SemanticSearchScreen> {
  final List<XFile> _selectedImages = [];
  bool _isSearching = false;
  List<SearchMatch> _allSearchResults = []; // Original unfiltered results
  List<SearchMatch> _filteredResults = [];  // Filtered results to display
  String? _errorMessage;
  String? _statusMessage;
  
  // Filter state
  double _radiusKm = 50; // Default 50km
  String? _selectedSex; // null = Any, 'male', 'female'
  
  final GeminiService _gemini = GeminiService();

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImages.add(widget.initialImage!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
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
        
        // Step 1: Analyze with Gemini to get features
        setState(() => _statusMessage = "Step 1/2: Extracting features from image ${i+1}...");
        
        Map<String, dynamic> features = {};
        try {
          features = await _gemini.analyzePetImage(image);
          print("Gemini extracted: $features");
        } catch (e) {
          print("Gemini analysis failed: $e");
          // Continue without features
        }
        
        // Step 2: Send to search API with features
        setState(() => _statusMessage = "Step 2/2: Searching database...");
        
        final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/pet/search');
        print('🚀 Sending search request to: $uri');
        final request = http.MultipartRequest(
          'POST', 
          uri
        );
        
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
        request.fields['type'] = 'lost';
        
        // Add extracted features to improve matching
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
        // Only override sex from Gemini if user didn't explicitly select one
        if (_selectedSex == null && features['sex'] != null && features['sex'] != 'Unknown') {
          request.fields['sex'] = features['sex'].toString().toLowerCase();
        }
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ API Response: ${data['matches']?.length ?? 0} matches found');
          if (data['success'] == true) {
            final matches = (data['matches'] as List)
                .map((m) => SearchMatch.fromJson(m))
                .toList();
            allMatches.addAll(matches);
          }
        } else {
           print("❌ API Error (${response.statusCode}): ${response.body}");
           _errorMessage = "API Error: ${response.statusCode}";
        }
      }

      // Deduplicate by pet ID, keeping highest score
      final Map<String, SearchMatch> uniqueMatches = {};
      for (var match in allMatches) {
        final existing = uniqueMatches[match.pet.id];
        if (existing == null || match.combinedScore > existing.combinedScore) {
          uniqueMatches[match.pet.id] = match;
        }
      }

      // Sort by combined score descending
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
      // Sex filter
      if (_selectedSex != null) {
        final petSex = match.pet.sex?.toLowerCase();
        if (petSex != _selectedSex) return false;
      }
      // Note: Radius filtering would require pet location data
      // For now, we filter only by sex client-side
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.asHomeTab,
        title: Text(widget.asHomeTab ? '🐾 ค้นหาสัตว์เลี้ยง' : 'Smart Pet Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Algorithm: 40% AI Vision + 30% Color + 30% Features',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Image Selection Area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Upload photos of your lost pet",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "Tap multiple times to add more photos",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
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
                            onTap: _pickImages,
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_a_photo, color: Colors.grey),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 40, color: AppTheme.primaryGreen),
                          SizedBox(height: 8),
                          Text("Tap to upload photos"),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                
                const SizedBox(height: 16),
                
                // Search Button (Always visible)
                ElevatedButton.icon(
                  onPressed: _isSearching || _selectedImages.isEmpty ? null : _performSearch,
                  icon: _isSearching 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? "SEARCHING..." : "FIND MATCHES"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                
                // Filter Section (Only visible after search)
                if (_allSearchResults.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text("Filters", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Radius Filter
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text("Radius: ", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            Text("${_radiusKm.round()} km", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Slider(
                          value: _radiusKm,
                          min: 5,
                          max: 200,
                          divisions: 39,
                          activeColor: AppTheme.accentOrange,
                          onChanged: (value) {
                            setState(() => _radiusKm = value);
                            _onFilterChanged();
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Sex Filter
                        Row(
                          children: [
                            const Icon(Icons.pets, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text("Sex: ", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  _buildSexChip("Any", null),
                                  _buildSexChip("Male", "male"),
                                  _buildSexChip("Female", "female"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Results Area
          Expanded(
            child: _isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Lottie.asset('assets/lottie/Dog Paw Loading.json'),
                        ),
                        const SizedBox(height: 24),
                        // Animated Step Indicators
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
                  )
                : _errorMessage != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ))
                    : _allSearchResults.isEmpty
                        ? Center(
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
                                  'Upload photos to start searching',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Our AI will find potential matches',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : _filteredResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text("No results match your filters", style: TextStyle(color: Colors.grey[600])),
                                    Text("Found ${_allSearchResults.length} results before filtering", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredResults.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final match = _filteredResults[index];
                                  // Staggered entrance animation per card
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey(match.pet.id),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 600)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 30 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildMatchCard(context, match),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, SearchMatch match) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailScreen(pet: match.pet)));
        },
        child: Column(
          children: [
            Row(
              children: [
                // Image
                SizedBox(
                  width: 110,
                  height: 110,
                  child: match.pet.imageUrl != null 
                      ? Image.network(match.pet.imageUrl!, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300], child: const Icon(Icons.pets, color: Colors.grey, size: 40)),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: match.pet.status == 'LOST' ? Colors.red : AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(match.pet.status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getScoreColor(match.combinedScore),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${match.matchPercent}% Match",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.pet.name ?? match.pet.species,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          match.pet.colorMain ?? "Unknown color",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Algorithm Breakdown
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreChip("🧠 AI", match.embeddingPercent, Colors.purple),
                  _buildScoreChip("🎨 Color", match.colorPercent, Colors.orange),
                  _buildScoreChip("📝 Features", match.featurePercent, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(String label, int percent, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text("$percent%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
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
