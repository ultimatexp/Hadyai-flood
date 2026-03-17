import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/feed_post.dart';
import '../domain/user_stats.dart';
import '../data/social_providers.dart';

/// Instagram-style Create Post screen
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  FeedPostType _selectedType = FeedPostType.petReport;
  File? _selectedImage;
  bool _isPosting = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
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
    if (caption.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเขียนข้อความหรือเลือกรูปภาพ')),
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

      await supabase.from('feed_posts').insert({
        'post_type': _selectedType.value,
        'title': _buildTitle(userName),
        'body': caption.isNotEmpty ? caption : null,
        'image_url': imageUrl,
        'user_id': user.id,
        'author_name': userName,
        'author_avatar': user.userMetadata?['avatar_url'],
        'metadata': {},
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
    return switch (_selectedType) {
      FeedPostType.petReport => '$name รายงานสัตว์เลี้ยง',
      FeedPostType.reunion => '$name พบสัตว์เลี้ยงแล้ว! 🎉',
      FeedPostType.shelterUpdate => '$name อัพเดทจากสถานสงเคราะห์',
      FeedPostType.milestone => '$name ปลดล็อกเป้าหมาย!',
      FeedPostType.story => '$name แชร์เรื่องราว',
    };
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
            // ═══════ POST TYPE SELECTOR ═══════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ประเภทโพสต์',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: FeedPostType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedType = type);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF9800) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(color: const Color(0xFFFF9800), width: 1.5)
                                    : Border.all(color: Colors.grey[300]!, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(type.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

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
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('เร็วๆ นี้!')),
                        );
                      },
                    ),
                  ],
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
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
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
