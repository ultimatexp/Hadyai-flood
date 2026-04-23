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
import 'pet_search_navigation.dart';

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
        const SnackBar(content: Text('📍 อัปเดตตำแหน่งปัจจุบันแล้ว!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ไม่สามารถระบุตำแหน่ง: $e")));
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
        const SnackBar(content: Text('📍 เลือกตำแหน่งจากแผนที่แล้ว!')),
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

      if (data['analysis_unavailable'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI ช่วยกรอกข้อมูลชั่วคราวไม่พร้อมใช้งาน กรุณากรอกข้อมูลด้วยตนเอง'),
            ),
          );
        }
        return;
      }

      if (data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      if (mounted) {
        setState(() {
          final rawSpecies = data['species']?.toString().toLowerCase();
          if (rawSpecies == 'dog') _species = 'Dog';
          if (rawSpecies == 'cat') _species = 'Cat';
          if (data['pet_name'] != null) _nameController.text = data['pet_name'].toString();
          final coat = data['color_main'] ?? data['color'];
          if (coat != null) _colorController.text = coat.toString();
          if (data['description'] != null) _descController.text = data['description'].toString();
          final sx = data['sex']?.toString().toLowerCase();
          if (sx == 'male') _sex = 'Male';
          if (sx == 'female') _sex = 'Female';
          if (data['contact_info'] != null) _contactController.text = data['contact_info'];
          if (data['reward'] != null) _rewardController.text = data['reward'].toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ วิเคราะห์ข้อมูลจากรูปเรียบร้อย!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('วิเคราะห์ไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัพโหลดรูปสัตว์เลี้ยงอย่างน้อย 1 รูป')),
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
          SnackBar(content: Text('ส่งรายงานสำเร็จ! +$pointsAwarded แต้ม 🎉')),
        );
        // Refresh both providers: map/legacy views still use lostPetsProvider,
        // while pet feed list now uses paginatedLostPetsProvider.
        ref.invalidate(lostPetsProvider);
        ref.invalidate(paginatedLostPetsProvider);

        // If image provided, ask to search
        if (_imageFiles.isNotEmpty) {
          final shouldSearch = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('ค้นหาสัตว์เลี้ยงที่คล้ายกัน?'),
              content: const Text('ต้องการค้นหาสัตว์เลี้ยงที่คล้ายกับตัวที่เพิ่งรายงานหรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ไม่ ขอบคุณ'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.accentOrange),
                  child: const Text('ค้นหาเลย'),
                ),
              ],
            ),
          );

          if (shouldSearch == true && mounted) {
            switchToHomePetSearch(
              ref,
              context,
              initialImage: _imageFiles.first,
            );
            return;
          }
        }
        
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายงานสัตว์เลี้ยง')),
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
                  ButtonSegment(value: 'LOST', label: Text('สัตว์เลี้ยงหาย'), icon: Icon(Icons.search)),
                  ButtonSegment(value: 'FOUND', label: Text('พบสัตว์เลี้ยง'), icon: Icon(Icons.pets)),
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
                                Text('แตะเพื่ออัพโหลดรูป (สูงสุด 5 รูป)', style: TextStyle(color: Colors.grey)),
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
                "เคล็ดลับ: รูปแรกควรเป็นรูปที่ชัดที่สุด! ✨",
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
                      label: const Text('ตำแหน่งปัจจุบัน'),
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
                      label: const Text('เลือกจากแผนที่'),
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
                    'ตำแหน่ง: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
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
                  labelText: 'วันที่และเวลาที่พบ', 
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),

                // Contact Info
                if (_status == 'FOUND')
                  CheckboxListTile(
                    title: const Text('แชร์ข้อมูลติดต่อ'),
                    subtitle: const Text('อนุญาตให้ผู้อื่นเห็นข้อมูลติดต่อของคุณ'),
                    value: _shareContactInfo, 
                    onChanged: (val) => setState(() => _shareContactInfo = val ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                if (_status == 'LOST' || _shareContactInfo)
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'ข้อมูลติดต่อ (โทรศัพท์, Line, Facebook)', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined)
                    ),
                    validator: (value) {
                      if (_status == 'LOST') {
                         if (value == null || value.trim().isEmpty) return 'กรุณากรอกข้อมูลติดต่อ';
                      }
                      
                      if (_status == 'FOUND' && _shareContactInfo) {
                        if (value == null || value.trim().isEmpty) return 'กรุณากรอกข้อมูลติดต่อ';
                      }
                      
                      return null;
                    },
                  ),

              

              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสัตว์เลี้ยง (ถ้าทราบ)',
                  hintText: 'เช่น Charlotte',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Sex
              DropdownButtonFormField<String>(
                value: _sex,
                decoration: const InputDecoration(labelText: 'เพศ', border: OutlineInputBorder()),
                items: ['Unknown', 'Male', 'Female'].map((s) {
                  final thLabel = s == 'Unknown' ? 'ไม่ทราบ' : s == 'Male' ? 'ผู้' : 'เมีย';
                  return DropdownMenuItem(value: s, child: Text(thLabel));
                }).toList(),
                onChanged: (v) => setState(() => _sex = v!),
              ),
              const SizedBox(height: 16),

              // Basic Info Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _species,
                      decoration: const InputDecoration(labelText: 'ประเภท', border: OutlineInputBorder()),
                      items: ['Cat', 'Dog'].map((s) {
                        final thLabel = s == 'Cat' ? 'แมว' : 'สุนัข';
                        return DropdownMenuItem(value: s, child: Text(thLabel));
                      }).toList(),
                      onChanged: (v) => setState(() => _species = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(labelText: 'สี', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reward Field (only for LOST pets)
              if (_status == 'LOST') ...[
                TextFormField(
                  controller: _rewardController,
                  decoration: const InputDecoration(
                    labelText: 'ค่าตอบแทน (ไม่บังคับ)', 
                    hintText: 'เช่น 5,000 บาท',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'รายละเอียดเพิ่มเติม (ปลอกคอ, ลักษณะเด่น ฯลฯ)', border: OutlineInputBorder()),
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
                  : Text(
                      _status == 'LOST' ? 'ส่งรายงานสัตว์หาย' : 'ส่งรายงานสัตว์ที่พบ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
