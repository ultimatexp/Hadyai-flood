import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../pets/presentation/location_picker_screen.dart';
import '../domain/feed_post.dart';
import '../domain/user_stats.dart';
import '../data/social_providers.dart';
import '../../moderation/domain/content_filter.dart';

/// Instagram-style Create Post screen
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  static const FeedPostType _postType = FeedPostType.petReport;
  File? _selectedImage;
  LatLng? _pickedLocation;
  bool _isPosting = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.selectionClick();
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเลือกรูปภาพ: $e')),
        );
      }
    }
  }

  /// Opens map picker; seeds center from saved pin, else current GPS (if allowed), else Hat Yai.
  Future<void> _openLocationPicker() async {
    HapticFeedback.mediumImpact();
    var initialLat = 7.005;
    var initialLng = 100.476;
    if (_pickedLocation != null) {
      initialLat = _pickedLocation!.latitude;
      initialLng = _pickedLocation!.longitude;
    } else {
      try {
        if (await Geolocator.isLocationServiceEnabled()) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition();
            initialLat = pos.latitude;
            initialLng = pos.longitude;
          }
        }
      } catch (_) {
        // Keep Hat Yai default
      }
    }

    if (!mounted) return;
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() => _pickedLocation = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แนบตำแหน่งกับโพสต์แล้ว')),
      );
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? 'anon';
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'feed_posts/$fileName';

      await supabase.storage.from('pet-photos').upload(path, image);
      return supabase.storage.from('pet-photos').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  Future<void> _submitPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImage == null && _pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเขียนข้อความ เลือกรูปภาพ หรือระบุสถานที่')),
      );
      return;
    }

    final filterResult = ContentFilter.checkText(caption);
    if (!filterResult.isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถโพสต์ได้: ตรวจพบข้อความไม่เหมาะสม'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      // Create the feed post
      final supabase = Supabase.instance.client;
      final userName = user.userMetadata?['full_name'] as String?;

      final metadata = <String, dynamic>{};
      if (_pickedLocation != null) {
        metadata['lat'] = _pickedLocation!.latitude;
        metadata['lng'] = _pickedLocation!.longitude;
      }

      await supabase.from('feed_posts').insert({
        'post_type': _postType.value,
        'title': _buildTitle(userName),
        'body': caption.isNotEmpty ? caption : null,
        'image_url': imageUrl,
        'user_id': user.id,
        'author_name': userName,
        'author_avatar': user.userMetadata?['avatar_url'],
        'metadata': metadata,
      });

      // Award points
      await incrementStat('total_points', amount: 10).catchError((_) => <BadgeType>[]);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('โพสต์สำเร็จ! +10 แต้ม'),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true); // Return true to refresh feed
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  String _buildTitle(String? userName) {
    final name = userName ?? 'ผู้ใช้';
    return '$name รายงานสัตว์เลี้ยง';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างโพสต์'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isPosting ? null : _submitPost,
              child: _isPosting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9800)),
                    )
                  : const Text(
                      'โพสต์',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════ CAPTION INPUT ═══════
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _captionController,
                maxLines: 6,
                minLines: 3,
                maxLength: 500,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'เขียนอะไรบางอย่าง...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),

            // ═══════ SELECTED IMAGE PREVIEW ═══════
            if (_selectedImage != null)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),

            // ═══════ MEDIA BUTTONS ═══════
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    _MediaButton(
                      icon: Icons.photo_library_outlined,
                      label: 'แกลเลอรี่',
                      color: const Color(0xFF4CAF50),
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    Container(width: 1, height: 32, color: Colors.grey[200]),
                    _MediaButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'กล้อง',
                      color: const Color(0xFF2196F3),
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    Container(width: 1, height: 32, color: Colors.grey[200]),
                    _MediaButton(
                      icon: Icons.location_on_outlined,
                      label: 'สถานที่',
                      color: const Color(0xFFFF9800),
                      onTap: _openLocationPicker,
                    ),
                  ],
                ),
              ),
            ),

            if (_pickedLocation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Material(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: const Icon(Icons.place, color: Color(0xFFFF9800)),
                    title: Text(
                      '${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('ตำแหน่งจะถูกบันทึกกับโพสต์'),
                    trailing: IconButton(
                      tooltip: 'ลบตำแหน่ง',
                      onPressed: () => setState(() => _pickedLocation = null),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ),

            // ═══════ TIPS ═══════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'โพสต์ที่มีรูปภาพจะได้รับ Reaction มากกว่า 3 เท่า! 📸',
                        style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
