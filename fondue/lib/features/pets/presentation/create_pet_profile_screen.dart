import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import 'pet_profile_providers.dart';

class CreatePetProfileScreen extends ConsumerStatefulWidget {
  const CreatePetProfileScreen({super.key});

  @override
  ConsumerState<CreatePetProfileScreen> createState() => _CreatePetProfileScreenState();
}

class _CreatePetProfileScreenState extends ConsumerState<CreatePetProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  String _species = 'Dog';
  final _breedController = TextEditingController();
  String _sex = 'unknown';

  // Step 2: Physical Details
  DateTime? _birthday;
  final _weightController = TextEditingController();
  String? _bodySize;
  String? _furLength;
  final _colorMainController = TextEditingController();
  final _colorSecondaryController = TextEditingController();
  final _eyeColorController = TextEditingController();
  final _microchipController = TextEditingController();

  // Step 3: Photos
  final List<XFile> _selectedImages = [];
  final _picker = ImagePicker();

  // Step 4: Personality & Bio
  final _bioController = TextEditingController();
  final List<String> _selectedTraits = [];
  bool _isNeutered = false;
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  final _traitOptions = [
    'เป็นมิตร', 'ขี้เล่น', 'สงบ', 'ขี้อาย', 'กระฉับกระเฉง',
    'ฉลาด', 'ซื่อสัตย์', 'ดุ', 'อ่อนโยน', 'ชอบกอด',
    'ขี้สงสัย', 'อิสระ', 'ร่าเริง', 'ป้องกันเจ้าของ',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _colorMainController.dispose();
    _colorSecondaryController.dispose();
    _eyeColorController.dispose();
    _microchipController.dispose();
    _bioController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        title: const Text('สร้างโปรไฟล์สัตว์เลี้ยง'),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(isDark),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(isDark),
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final steps = ['ข้อมูลพื้นฐาน', 'รายละเอียด', 'รูปภาพ', 'บุคลิก & สุขภาพ'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                // Circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppTheme.primaryGreen
                        : (isActive ? AppTheme.accentOrange : Colors.grey[300]),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                // Line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppTheme.primaryGreen : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo(isDark);
      case 1:
        return _buildStep2PhysicalDetails(isDark);
      case 2:
        return _buildStep3Photos(isDark);
      case 3:
        return _buildStep4PersonalityBio(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Basic Info ────────────────────────────────────────
  Widget _buildStep1BasicInfo(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ชื่อสัตว์เลี้ยง *', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'เช่น บุดดี้, มิโกะ, ลัคกี้',
              prefixIcon: Icon(Icons.pets),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาใส่ชื่อ' : null,
          ),

          const SizedBox(height: 20),

          _sectionLabel('ประเภท *', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'].map((species) {
              final selected = _species == species;
              return ChoiceChip(
                label: Text(_speciesLabel(species)),
                selected: selected,
                selectedColor: AppTheme.accentOrange.withOpacity(0.2),
                onSelected: (_) => setState(() => _species = species),
                avatar: Icon(_speciesIcon(species), size: 18),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          _sectionLabel('สายพันธุ์', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _breedController,
            decoration: const InputDecoration(
              hintText: 'เช่น ปอมเมอเรเนียน, สก็อตติชโฟลด์',
              prefixIcon: Icon(Icons.category),
            ),
          ),

          const SizedBox(height: 20),

          _sectionLabel('เพศ *', isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSexOption('male', 'ผู้', Icons.male, Colors.blue, isDark),
              const SizedBox(width: 12),
              _buildSexOption('female', 'เมีย', Icons.female, Colors.pink, isDark),
              const SizedBox(width: 12),
              _buildSexOption('unknown', 'ไม่ทราบ', Icons.help_outline, Colors.grey, isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Physical Details ──────────────────────────────────
  Widget _buildStep2PhysicalDetails(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('วันเกิด', isDark),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthday ?? DateTime.now().subtract(const Duration(days: 365)),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _birthday = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake, color: AppTheme.accentOrange),
                  const SizedBox(width: 12),
                  Text(
                    _birthday != null
                        ? '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}'
                        : 'เลือกวันเกิด',
                    style: TextStyle(
                      color: _birthday != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('น้ำหนัก (kg)', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'เช่น 5.5',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('ขนาดตัว', isDark),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _bodySize,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'small', child: Text('เล็ก')),
                        DropdownMenuItem(value: 'medium', child: Text('กลาง')),
                        DropdownMenuItem(value: 'large', child: Text('ใหญ่')),
                      ],
                      onChanged: (v) => setState(() => _bodySize = v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _sectionLabel('สีหลัก', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _colorMainController,
            decoration: const InputDecoration(
              hintText: 'เช่น น้ำตาล, ขาว, ดำ',
              prefixIcon: Icon(Icons.palette_outlined),
            ),
          ),

          const SizedBox(height: 16),

          _sectionLabel('สีรอง', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _colorSecondaryController,
            decoration: const InputDecoration(
              hintText: 'เช่น ครีม, ส้ม',
              prefixIcon: Icon(Icons.palette),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('ความยาวขน', isDark),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _furLength,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.grass)),
                      items: const [
                        DropdownMenuItem(value: 'short', child: Text('สั้น')),
                        DropdownMenuItem(value: 'medium', child: Text('กลาง')),
                        DropdownMenuItem(value: 'long', child: Text('ยาว')),
                        DropdownMenuItem(value: 'hairless', child: Text('ไม่มีขน')),
                      ],
                      onChanged: (v) => setState(() => _furLength = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('สีตา', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _eyeColorController,
                      decoration: const InputDecoration(
                        hintText: 'เช่น น้ำตาล',
                        prefixIcon: Icon(Icons.remove_red_eye_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _sectionLabel('เลขไมโครชิป', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _microchipController,
            decoration: const InputDecoration(
              hintText: 'เลข 15 หลัก (ถ้ามี)',
              prefixIcon: Icon(Icons.qr_code),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Photos ────────────────────────────────────────────
  Widget _buildStep3Photos(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('รูปภาพสัตว์เลี้ยง', isDark),
          const SizedBox(height: 4),
          Text(
            'เพิ่มรูปภาพของสัตว์เลี้ยง รูปแรกจะเป็นรูปโปรไฟล์',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),

          // Image grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // Add button
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentOrange.withOpacity(0.4),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 28, color: AppTheme.accentOrange),
                        const SizedBox(height: 4),
                        Text(
                          'เพิ่ม',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Image tile
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder(
                      future: _selectedImages[index].readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        }
                        return Container(color: Colors.grey[300]);
                      },
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'หลัก',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedImages.removeAt(index));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Personality & Bio ─────────────────────────────────
  Widget _buildStep4PersonalityBio(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('เกี่ยวกับสัตว์เลี้ยง', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'เล่าเรื่องราวของสัตว์เลี้ยงของคุณ...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.auto_awesome),
              ),
            ),
          ),

          const SizedBox(height: 20),

          _sectionLabel('บุคลิกภาพ', isDark),
          const SizedBox(height: 4),
          Text(
            'เลือกได้หลายอย่าง',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _traitOptions.map((trait) {
              final selected = _selectedTraits.contains(trait);
              return FilterChip(
                label: Text(trait),
                selected: selected,
                selectedColor: AppTheme.accentOrange.withOpacity(0.2),
                checkmarkColor: AppTheme.accentOrange,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedTraits.add(trait);
                    } else {
                      _selectedTraits.remove(trait);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Neutered toggle
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ทำหมันแล้ว',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'สัตว์เลี้ยงผ่านการทำหมันแล้วหรือไม่',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isNeutered,
                  onChanged: (v) => setState(() => _isNeutered = v),
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _sectionLabel('อาการแพ้ (ถ้ามี)', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _allergiesController,
            decoration: const InputDecoration(
              hintText: 'คั่นด้วยจุลภาค เช่น อาหารทะเล, ลิ้นจี่',
              prefixIcon: Icon(Icons.warning_amber),
            ),
          ),

          const SizedBox(height: 16),

          _sectionLabel('โรคประจำตัว (ถ้ามี)', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _conditionsController,
            decoration: const InputDecoration(
              hintText: 'คั่นด้วยจุลภาค เช่น โรคหัวใจ, ข้อเสื่อม',
              prefixIcon: Icon(Icons.medical_information),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Navigation Buttons ────────────────────────────────────────
  Widget _buildNavigationButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ย้อนกลับ'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 3 ? AppTheme.primaryGreen : AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_currentStep == 3 ? 'สร้างโปรไฟล์' : 'ถัดไป'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() != true) return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(petProfileRepositoryProvider);

      await repo.createPetProfile(
        name: _nameController.text.trim(),
        species: _species,
        breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        sex: _sex,
        birthday: _birthday,
        weightKg: _weightController.text.trim().isEmpty
            ? null
            : double.tryParse(_weightController.text.trim()),
        bodySize: _bodySize,
        furLength: _furLength,
        colorMain: _colorMainController.text.trim().isEmpty ? null : _colorMainController.text.trim(),
        colorSecondary: _colorSecondaryController.text.trim().isEmpty ? null : _colorSecondaryController.text.trim(),
        eyeColor: _eyeColorController.text.trim().isEmpty ? null : _eyeColorController.text.trim(),
        microchipNumber: _microchipController.text.trim().isEmpty ? null : _microchipController.text.trim(),
        personalityTraits: _selectedTraits.isEmpty ? null : _selectedTraits,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        isNeutered: _isNeutered,
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        conditions: _conditionsController.text.trim().isEmpty
            ? null
            : _conditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        imageFiles: _selectedImages.isEmpty ? null : _selectedImages,
      );

      // Refresh the profiles list
      ref.invalidate(myPetProfilesProvider);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 สร้างโปรไฟล์สำเร็จ!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildSexOption(String value, String label, IconData icon, Color color, bool isDark) {
    final selected = _sex == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sex = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : (isDark ? AppTheme.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Colors.grey[600],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _speciesLabel(String species) {
    switch (species) {
      case 'Dog':
        return '🐕 สุนัข';
      case 'Cat':
        return '🐈 แมว';
      case 'Bird':
        return '🐦 นก';
      case 'Rabbit':
        return '🐰 กระต่าย';
      default:
        return '🐾 อื่นๆ';
    }
  }

  IconData _speciesIcon(String species) {
    switch (species) {
      case 'Dog':
        return Icons.pets;
      case 'Cat':
        return Icons.pets;
      case 'Bird':
        return Icons.flutter_dash;
      case 'Rabbit':
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }
}
