import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/pet_repository.dart';
import 'pet_providers.dart';
import 'gemini_provider.dart';
import 'location_picker_screen.dart';
import '../../points/points_provider.dart';
import 'semantic_search_screen.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String? initialStatus;
  const ReportScreen({super.key, this.initialStatus});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _status;
  String _species = 'Cat';
  String _sex = 'Unknown';

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ?? 'LOST';
    _dateController.text = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}, ${_selectedDate.hour}:${_selectedDate.minute}";
  }

  // Form Controllers
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  final _rewardController = TextEditingController();
  
  // Location & Date
  double? _lat;
  double? _lng;
  DateTime _selectedDate = DateTime.now();
  final _dateController = TextEditingController();
  bool _useCurrentLocation = false;


  List<XFile> _imageFiles = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _shareContactInfo = true;



  Future<void> _pickLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _useCurrentLocation = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location updated to current position!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error getting location: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocationFromMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: _lat ?? 7.005,
          initialLng: _lng ?? 100.476,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _useCurrentLocation = false; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location selected from map!')),
      );
    }
  }
  
  Future<void> _pickDate() async {
     final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
     if (picked != null) {
       final TimeOfDay? time = await showTimePicker(
         context: context, 
         initialTime: TimeOfDay.fromDateTime(_selectedDate)
       );
       if (time != null) {
         setState(() {
           _selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
           _dateController.text = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}, ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}";
         });
       }
     }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // imageQuality: 50 forces conversion to JPEG, preventing HEIC crashes on iOS
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
      requestFullMetadata: false, // Avoids HEIC metadata loading crash
    );
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles);
      });
      // Analyze the first image for now
      if (_imageFiles.isNotEmpty) {
        _analyzeImage(_imageFiles.first);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _analyzeImage(XFile image) async {
    setState(() => _isAnalyzing = true);
    try {
      final gemini = ref.read(geminiServiceProvider);
      final data = await gemini.analyzePetImage(image);
      
      if (mounted) {
        setState(() {
          if (data['species'] != null) {
            final s = data['species'].toString();
            if (['Cat', 'Dog', 'Bird'].contains(s)) _species = s;
            else _species = 'Other';
          }
          if (data['pet_name'] != null) _nameController.text = data['pet_name'];
          if (data['color'] != null) _colorController.text = data['color'];
          if (data['description'] != null) _descController.text = data['description'];
          if (data['sex'] != null && ['Male', 'Female'].contains(data['sex'])) {
             _sex = data['sex'];
          }
          if (data['contact_info'] != null) _contactController.text = data['contact_info'];
          if (data['reward'] != null) _rewardController.text = data['reward'].toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Extracted data from image!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Analysis failed: $e')));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image of the pet.')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(petRepositoryProvider);
      
      await repo.reportPet(
        status: _status,
        species: _species,
        color: _colorController.text,
        petName: _nameController.text.isNotEmpty ? _nameController.text : null,
        description: _descController.text,
        sex: _sex,
        lat: _lat ?? 7.005, 
        lng: _lng ?? 100.476,
        contactInfo: (_status == 'LOST' || _shareContactInfo) ? _contactController.text : null,
        reward: _rewardController.text.isNotEmpty ? _rewardController.text : null,
        lastSeenDate: _selectedDate,
        imageFiles: _imageFiles,
      );

      if (mounted) {
        // Award points based on report type
        final pointsNotifier = ref.read(pointsProvider.notifier);
        int pointsAwarded = 0;
        if (_status == 'FOUND') {
          await pointsNotifier.awardFoundPetPoints();
          pointsAwarded = PointsService.reportFoundPetPoints;
        } else {
          await pointsNotifier.awardLostPetPoints();
          pointsAwarded = PointsService.reportLostPetPoints;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted! +$pointsAwarded points earned 🎉')),
        );
        ref.refresh(lostPetsProvider);

        // If image provided, ask to search
        if (_imageFiles.isNotEmpty) {
          final shouldSearch = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Start Semantic Search?'),
              content: const Text('Would you like to search for other pets that look similar to the one you just reported?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('No, thanks'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.accentOrange),
                  child: const Text('Yes, Search Now'),
                ),
              ],
            ),
          );

          if (shouldSearch == true && mounted) {
             Navigator.pop(context); // Close report screen
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SemanticSearchScreen(initialImage: _imageFiles.first),
              ),
            );
            return;
          }
        }
        
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // Toggle
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'LOST', label: Text('Lost Pet'), icon: Icon(Icons.search)),
                  ButtonSegment(value: 'FOUND', label: Text('Found Pet'), icon: Icon(Icons.pets)),
                ],
                selected: {_status},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _status = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              
              // Image Picker
              if (_imageFiles.isEmpty)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                    ),
                    child: _isAnalyzing 
                        ? const Center(child: CircularProgressIndicator())
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: AppTheme.primaryGreen),
                                Text('Tap to Upload Photos (Max 5)', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageFiles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _imageFiles.length) {
                         return GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: const Icon(Icons.add, size: 40, color: Colors.grey),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(_imageFiles[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                "Tip: Make sure your first photo is the clearest one! ✨",
                style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Location Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Current Loc'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: _useCurrentLocation ? AppTheme.primaryGreen : Colors.grey),
                        backgroundColor: _useCurrentLocation ? AppTheme.primaryGreen.withOpacity(0.1) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickLocationFromMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Pick on Map'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_lat != null && _lng != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selected: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),

              // Date
               TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Date and Time Found', 
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),

                // Contact Info
                if (_status == 'FOUND')
                  CheckboxListTile(
                    title: const Text("Share Contact Info"),
                    subtitle: const Text("Allow others to see your contact details"),
                    value: _shareContactInfo, 
                    onChanged: (val) => setState(() => _shareContactInfo = val ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                if (_status == 'LOST' || _shareContactInfo)
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact (Phone, Line ID, Facebook)', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined)
                    ),
                    validator: (value) {
                      if (_status == 'LOST') {
                         if (value == null || value.trim().isEmpty) return 'Contact information is required for lost pets';
                      }
                      
                      if (_status == 'FOUND' && _shareContactInfo) {
                        if (value == null || value.trim().isEmpty) return 'Contact information is required if shared';
                      }
                      
                      return null;
                    },
                  ),

              

              const SizedBox(height: 8),

              // Sex
              DropdownButtonFormField<String>(
                value: _sex,
                decoration: const InputDecoration(labelText: 'Sex', border: OutlineInputBorder()),
                items: ['Unknown', 'Male', 'Female'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _sex = v!),
              ),
              const SizedBox(height: 16),

              // Basic Info Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _species,
                      decoration: const InputDecoration(labelText: 'Species', border: OutlineInputBorder()),
                      items: ['Cat', 'Dog', 'Bird', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _species = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reward Field
              TextFormField(
                controller: _rewardController,
                decoration: const InputDecoration(
                  labelText: 'Reward (Optional)', 
                  hintText: 'e.g., 5,000 THB',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Additional Details (Collar, etc.)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading || _isAnalyzing ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _status == 'LOST' ? Colors.red : AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('SUBMIT REPORT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
