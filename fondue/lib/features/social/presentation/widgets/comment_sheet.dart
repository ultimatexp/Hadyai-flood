import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/social_providers.dart';

/// A single comment
class FeedComment {
  final String id;
  final String postId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;

  FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.body,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) => FeedComment(
    id: json['id'] as String,
    postId: json['post_id'] as String,
    userId: json['user_id'] as String,
    userName: json['user_name'] as String?,
    userAvatar: json['user_avatar'] as String?,
    body: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
  );
}

/// Instagram-style comment bottom sheet
class CommentSheet extends StatefulWidget {
  final String postId;
  final int initialCount;

  const CommentSheet({
    super.key,
    required this.postId,
    this.initialCount = 0,
  });

  /// Show the comment sheet
  static Future<int?> show(BuildContext context, {required String postId, int initialCount = 0}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(postId: postId, initialCount: initialCount),
    );
  }

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  List<FeedComment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _totalCount = widget.initialCount;
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final rows = await Supabase.instance.client
          .from('feed_comments')
          .select('*')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _comments = rows.map<FeedComment>((r) => FeedComment.fromJson(r)).toList();
          _totalCount = _comments.length;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendComment() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    setState(() => _isSending = true);
    _controller.clear();

    try {
      final userName = user.userMetadata?['full_name'] as String?;
      final userAvatar = user.userMetadata?['avatar_url'] as String?;

      await Supabase.instance.client.from('feed_comments').insert({
        'post_id': widget.postId,
        'user_id': user.id,
        'user_name': userName,
        'user_avatar': userAvatar,
        'content': body,
      });

      // Update comment count on feed post
      await Supabase.instance.client.rpc('increment_comment_count', params: {
        'p_post_id': widget.postId,
      }).catchError((_) async {
        // Fallback: manual increment
        final current = await Supabase.instance.client
            .from('feed_posts')
            .select('comment_count')
            .eq('id', widget.postId)
            .single();
        final count = ((current['comment_count'] as num?) ?? 0).toInt() + 1;
        await Supabase.instance.client
            .from('feed_posts')
            .update({'comment_count': count})
            .eq('id', widget.postId);
      });

      // Award points
      try { await incrementStat('total_points', amount: 5); } catch (_) {}

      HapticFeedback.lightImpact();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ═══════ HANDLE + HEADER ═══════
          _buildHeader(),

          const Divider(height: 1),

          // ═══════ COMMENTS LIST ═══════
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) => _CommentTile(
                          comment: _comments[index],
                        ),
                      ),
          ),

          const Divider(height: 1),

          // ═══════ INPUT BAR ═══════
          _buildInputBar(bottomInset),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'ความคิดเห็น',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_totalCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_totalCount',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context, _totalCount),
                child: Icon(Icons.close, color: Colors.grey[400], size: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: 4,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200])),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 6),
                  Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 4),
                  Container(width: 150, height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีความคิดเห็น',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            'เริ่มสนทนากันเลย!',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(double bottomInset) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + bottomInset),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? Icon(Icons.person, size: 18, color: Colors.grey[400]) : null,
            ),
            const SizedBox(width: 10),
            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(fontSize: 14),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                  decoration: InputDecoration(
                    hintText: 'เพิ่มความคิดเห็น...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Send button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, __) {
                final hasText = value.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: hasText && !_isSending ? _sendComment : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasText ? const Color(0xFFFF9800) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9800)),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: hasText ? Colors.white : Colors.grey[400],
                            size: 22,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMMENT TILE
// ============================================================

class _CommentTile extends StatelessWidget {
  final FeedComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            backgroundImage: comment.userAvatar != null
                ? NetworkImage(comment.userAvatar!)
                : null,
            child: comment.userAvatar == null
                ? Icon(Icons.person, size: 16, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    children: [
                      TextSpan(
                        text: comment.userName ?? 'ผู้ใช้',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(text: comment.body),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    if (comment.likeCount > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${comment.likeCount} ถูกใจ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                      ),
                    ],
                    const SizedBox(width: 16),
                    Text(
                      'ตอบกลับ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Like
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: GestureDetector(
              onTap: () => HapticFeedback.selectionClick(),
              child: Icon(
                comment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: comment.isLikedByMe ? Colors.red : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
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
