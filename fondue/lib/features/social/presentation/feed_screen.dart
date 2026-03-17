import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/feed_post.dart';
import '../domain/reaction.dart';
import '../data/social_providers.dart';
import 'widgets/reaction_widgets.dart';
import 'widgets/stories_bar.dart';
import 'widgets/comment_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_post_screen.dart';
import '../../pets/presentation/semantic_search_screen.dart';
import '../../pets/presentation/pet_food_scan_screen.dart';
import '../../../shared/page_transitions.dart';
import 'user_profile_page.dart';
import '../../fuel/presentation/fuel_map_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// Instagram-style community feed screen
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedPostsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedPostsProvider);
        ref.invalidate(activeStoriesProvider);
      },
      color: const Color(0xFFFF9800),
      child: CustomScrollView(
        slivers: [
          // ═══════ APP NAME BAR ═══════
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            primary: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            toolbarHeight: 48,
            title: Row(
              children: [
                const Text(
                  '🐾 Fondue',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF9800),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                // ⛽ Fuel Tracker shortcut
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FuelMapScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_gas_station, color: Colors.white, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          'น้ำมัน',
                          style: GoogleFonts.prompt(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Food Scanner shortcut
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PetFoodScanScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
                  ),
                ),
                // Create post
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final result = await Navigator.push(
                      context,
                      SlideUpPageRoute(page: const CreatePostScreen()),
                    );
                    if (result == true) {
                      ref.invalidate(feedPostsProvider);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ═══════ HERO SEARCH BANNER ═══════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SemanticSearchScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF9800),
                        Color(0xFFFF6D00),
                        Color(0xFFE65100),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Camera icon with glow
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ค้นหาสัตว์เลี้ยงด้วย AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'ถ่ายรูปหรือเลือกภาพ เพื่อค้นหาสัตว์ที่คล้ายกัน',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Arrow
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stories bar
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: 8),
              child: StoriesBar(),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Divider(height: 1, color: Colors.grey[200]),
          ),

          // Feed posts
          feedAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyFeed(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= posts.length) return null;
                    return _FeedCard(
                      post: posts[index],
                      onReactionChanged: () => ref.invalidate(feedPostsProvider),
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _FeedCardSkeleton(),
                childCount: 3,
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('เกิดข้อผิดพลาด', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),

          // Bottom padding for nav bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dynamic_feed, size: 48, color: Color(0xFFFF9800)),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีโพสต์ในฟีด',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เริ่มรายงานสัตว์ที่พบเพื่อสร้างชุมชน!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FEED CARD
// ============================================================

class _FeedCard extends StatefulWidget {
  final FeedPost post;
  final VoidCallback onReactionChanged;

  const _FeedCard({required this.post, required this.onReactionChanged});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  late Set<ReactionType> _myReactions;
  late ReactionCounts _counts;
  late int _commentCount;
  bool _isBookmarked = false;
  bool _isLikeAnimating = false;
  List<FeedComment> _previewComments = [];
  String? _editedBody;

  @override
  void initState() {
    super.initState();
    _myReactions = Set.from(widget.post.myReactions);
    _counts = widget.post.reactionCounts;
    _commentCount = widget.post.commentCount;
    _loadPreviewComments();
  }

  Future<void> _loadPreviewComments() async {
    try {
      final rows = await Supabase.instance.client
          .from('feed_comments')
          .select('*')
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: false)
          .limit(2);
      if (mounted) {
        setState(() {
          _previewComments = rows.map<FeedComment>((r) => FeedComment.fromJson(r)).toList().reversed.toList();
        });
      }
    } catch (_) {}
  }

  void _onReacted() {
    widget.onReactionChanged();
  }

  void _onHeartTap() async {
    HapticFeedback.lightImpact();
    final hasHeart = _myReactions.contains(ReactionType.heart);
    setState(() {
      if (hasHeart) {
        _myReactions.remove(ReactionType.heart);
      } else {
        _myReactions.add(ReactionType.heart);
        _isLikeAnimating = true;
      }
    });
    // Reset animation
    if (!hasHeart) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _isLikeAnimating = false);
      });
    }
    try {
      await toggleReaction(
        entityType: ReactableEntityType.feedPost,
        entityId: widget.post.id,
        reactionType: ReactionType.heart,
      );
      widget.onReactionChanged();
    } catch (_) {}
  }

  void _onCommentTap() async {
    final result = await CommentSheet.show(
      context,
      postId: widget.post.id,
      initialCount: _commentCount,
    );
    if (result != null && mounted) {
      setState(() => _commentCount = result);
      _loadPreviewComments();
      widget.onReactionChanged();
    }
  }

  void _onShareTap() {
    HapticFeedback.mediumImpact();
    final post = widget.post;
    final text = '${post.title}\n${post.body ?? ""}\n\nดูเพิ่มเติมที่ Fondue App 🐾';
    // Use a simple share dialog
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.copy_rounded,
                    label: 'คัดลอก',
                    color: Colors.grey[700]!,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('คัดลอกแล้ว! 📋')),
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.chat_rounded,
                    label: 'ส่งแชท',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เร็วๆ นี้!')),
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.flag_rounded,
                    label: 'รายงาน',
                    color: Colors.red[400]!,
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ขอบคุณ ส่งรายงานแล้ว')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _onBookmarkTap() {
    HapticFeedback.selectionClick();
    setState(() => _isBookmarked = !_isBookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'บันทึกแล้ว 🔖' : 'นำออกจากที่บันทึกแล้ว'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool get _isOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null && uid == widget.post.userId;
  }

  void _showPostOptions() {
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
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              if (_isOwner) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF2196F3)),
                  ),
                  title: const Text('แก้ไขโพสต์', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('เปลี่ยนข้อความ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editPost();
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('ลบโพสต์', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  subtitle: Text('ลบถาวร ไม่สามารถกู้คืนได้', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deletePost();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flag_outlined, color: Colors.red),
                  ),
                  title: const Text('รายงานโพสต์', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ขอบคุณ ส่งรายงานแล้ว')),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _editPost() {
    final controller = TextEditingController(text: _editedBody ?? widget.post.body ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Text('แก้ไขโพสต์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 2,
                maxLength: 500,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'เขียนอะไรบางอย่าง...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF9800)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final newBody = controller.text.trim();
                    Navigator.pop(ctx);
                    try {
                      await Supabase.instance.client
                          .from('feed_posts')
                          .update({'body': newBody})
                          .eq('id', widget.post.id);
                      if (mounted) {
                        setState(() => _editedBody = newBody);
                        widget.onReactionChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('แก้ไขแล้ว ✅')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบโพสต์?'),
        content: const Text('โพสต์นี้จะถูกลบถาวร ไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client
                    .from('feed_posts')
                    .delete()
                    .eq('id', widget.post.id);
                if (mounted) {
                  HapticFeedback.mediumImpact();
                  widget.onReactionChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลบโพสต์แล้ว')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                  );
                }
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (post.userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(userId: post.userId),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _typeColor(post.postType).withOpacity(0.12),
                  ),
                  child: Center(
                    child: post.authorAvatar != null
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(post.authorAvatar!),
                          )
                        : Text(post.postType.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _timeAgo(post.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor(post.postType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.postType.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _typeColor(post.postType),
                  ),
                ),
              ),
              // Three-dot menu
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showPostOptions,
                child: Icon(Icons.more_horiz, color: Colors.grey[600], size: 22),
              ),
            ],
          ),
        ),

        // Image
        if (post.imageUrl != null)
          DoubleTapReaction(
            entityType: ReactableEntityType.feedPost,
            entityId: post.id,
            onReacted: _onReacted,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.width,
              ),
              child: ClipRect(
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 48),
                  ),
                ),
              ),
            ),
          ),

        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Heart
              GestureDetector(
                onTap: _onHeartTap,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: _isLikeAnimating ? 1.3 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Icon(
                    _myReactions.contains(ReactionType.heart)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 28,
                    color: _myReactions.contains(ReactionType.heart)
                        ? Colors.red
                        : Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Comment
              GestureDetector(
                onTap: _onCommentTap,
                child: Icon(Icons.chat_bubble_outline, size: 26, color: Colors.grey[800]),
              ),
              const SizedBox(width: 16),
              // Share
              GestureDetector(
                onTap: _onShareTap,
                child: Icon(Icons.send_outlined, size: 26, color: Colors.grey[800]),
              ),
              const Spacer(),
              // Bookmark
              GestureDetector(
                onTap: _onBookmarkTap,
                child: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 28,
                  color: _isBookmarked ? const Color(0xFFFF9800) : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),

        // Reaction counts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ReactionCountBar(
            counts: _counts,
            myReactions: _myReactions,
            commentCount: _commentCount,
          ),
        ),

        // Body text
        if (post.body != null && post.body!.isNotEmpty || _editedBody != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                children: [
                  if (post.authorName != null)
                    TextSpan(
                      text: '${post.authorName} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  TextSpan(text: _editedBody ?? post.body),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // "View all comments" link
        if (_commentCount > 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _onCommentTap,
              child: Text(
                'ดูความคิดเห็นทั้งหมด $_commentCount รายการ',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
          ),

        // Preview comments (latest 2)
        if (_previewComments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _previewComments.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    children: [
                      TextSpan(
                        text: '${c.userName ?? "ผู้ใช้"} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: c.body),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),

        // Add comment shortcut
        if (_commentCount == 0 && _previewComments.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GestureDetector(
              onTap: _onCommentTap,
              child: Text(
                'เพิ่มความคิดเห็น...',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ),
          ),

        const SizedBox(height: 10),
        Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Color _typeColor(FeedPostType type) {
    return switch (type) {
      FeedPostType.petReport => const Color(0xFFFF9800),
      FeedPostType.reunion => const Color(0xFF4CAF50),
      FeedPostType.shelterUpdate => const Color(0xFF2196F3),
      FeedPostType.milestone => const Color(0xFFFFD700),
      FeedPostType.story => const Color(0xFF9C27B0),
    };
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'ตอนนี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาที';
    if (diff.inHours < 24) return '${diff.inHours} ชม.';
    if (diff.inDays < 7) return '${diff.inDays} วัน';
    return '${diff.inDays ~/ 7} สัปดาห์';
  }
}

// ============================================================
// SKELETON LOADER
// ============================================================

class _FeedCardSkeleton extends StatelessWidget {
  const _FeedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200])),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(7))),
                    const SizedBox(height: 4),
                    Container(width: 60, height: 10, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))),
                  ],
                ),
              ),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Container(color: Colors.grey[200]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200])),
              const SizedBox(width: 12),
              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200])),
              const SizedBox(width: 12),
              Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200])),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
