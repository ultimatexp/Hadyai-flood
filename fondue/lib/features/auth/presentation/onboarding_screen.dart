import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/user_profile_repository.dart';
import '../../settings/presentation/privacy_policy_screen.dart';
import '../../settings/presentation/terms_conditions_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  File? _selectedImage;
  String? _uploadedAvatarUrl;

  @override
  void initState() {
    super.initState();
    // Pre-fill name if available (e.g. from social login)
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.userMetadata?['full_name'] != null) {
      _nameController.text = user!.userMetadata!['full_name'];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _selectedImage!.readAsBytes();

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Failed to upload avatar: $e');
      return null;
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      // Upload avatar if selected
      if (_selectedImage != null) {
        _uploadedAvatarUrl = await _uploadImage();
      }

      final repo = UserProfileRepository(Supabase.instance.client);
      
      // Update profile info
      await repo.updateProfile(
        name: _nameController.text.trim(),
        contactInfo: _contactController.text.trim().isNotEmpty 
            ? _contactController.text.trim() 
            : null,
        avatarUrl: _uploadedAvatarUrl,
      );
      
      // Mark onboarding as complete
      await repo.completeOnboarding();

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate completion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(),
                  _buildContactStep(),
                  _buildThankYouStep(),
                ],
              ),
            ),
            
            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index 
                        ? AppTheme.primaryGreen 
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange, width: 3),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Icon(Icons.person, size: 60, color: Colors.orange)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add photo',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 24),
          Text(
            "Hi there! I'm Fondue.",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "What should I call you?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Your Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                _nextPage();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your name')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contact_phone, size: 80, color: Colors.blue),
          const SizedBox(height: 32),
          Text(
            "Stay Connected",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "How can people reach you if you find their lost pet?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _contactController,
            decoration: InputDecoration(
              hintText: 'Phone, Line ID, or Email (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: _nextPage,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Next'),
          ),
          TextButton(
            onPressed: _nextPage,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie Animation
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/lottie/ck pets world.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Thank You!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Welcome to the Fondue community.\n\nWe hope you find your lost pet or help others reunite with their families.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          
          // Terms and Privacy Checkbox
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _acceptedTerms ? AppTheme.primaryGreen : Colors.grey[300]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                    activeColor: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                      children: [
                        const TextSpan(text: 'I have read and agree to the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen()));
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isLoading || !_acceptedTerms ? null : _finishOnboarding,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text("Let's Get Started"),
          ),
          if (!_acceptedTerms)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Please accept the terms to continue',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }
}
