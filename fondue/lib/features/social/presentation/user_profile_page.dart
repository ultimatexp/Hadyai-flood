import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/edit_profile_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/profile_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../points/points_provider.dart';
import '../../pets/presentation/pet_providers.dart';
import '../data/social_providers.dart';
import '../domain/feed_post.dart';
import '../domain/reaction.dart';
import '../domain/user_stats.dart';
import 'widgets/reaction_widgets.dart';
import 'widgets/comment_sheet.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

/// Instagram-style user profile page.
/// Pass [userId] to view another user's profile, or leave null for own profile.
class UserProfilePage extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfilePage({super.key, this.userId});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? get _resolvedUserId =>
      widget.userId ?? Supabase.instance.client.auth.currentUser?.id;

  bool get _isOwnProfile =>
      widget.userId == null ||
      widget.userId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _resolvedUserId;

    // Not logged in — show login prompt
    if (userId == null) {
      return _buildLoginPrompt(context);
    }

    final statsAsync = ref.watch(userStatsProvider(userId));
    final postsAsync = ref.watch(userPostsProvider(userId));
    final reportsAsync = _isOwnProfile ? ref.watch(myReportsProvider) : null;
    final pointsAsync = _isOwnProfile ? ref.watch(pointsProvider) : null;

    // Resolve user display data
    final currentUser = Supabase.instance.client.auth.currentUser;
    final name = _isOwnProfile
        ? (currentUser?.userMetadata?['full_name'] as String?) ?? 'Guest User'
        : null; // will get from posts
    final String? avatarUrl = _isOwnProfile
        ? (currentUser?.userMetadata?['avatar_url'] as String?)
        : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          // ─── APP BAR ───
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: !_isOwnProfile,
            foregroundColor: Colors.grey[900],
            title: Text(
              _isOwnProfile ? (name ?? 'โปรไฟล์') : 'โปรไฟล์',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: _isOwnProfile
                ? [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                      },
                      icon: const Icon(Icons.menu_rounded, size: 26),
                    ),
                  ]
                : null,
          ),

          // ─── PROFILE HEADER ───
          SliverToBoxAdapter(
            child: _ProfileHeader(
              isOwn: _isOwnProfile,
              avatarUrl: _isOwnProfile ? avatarUrl : _getOtherAvatar(postsAsync),
              statsAsync: statsAsync,
              reportsAsync: reportsAsync,
              pointsAsync: pointsAsync,
              postsAsync: postsAsync,
            ),
          ),

          // ─── BIO SECTION ───
          SliverToBoxAdapter(
            child: _BioSection(
              isOwn: _isOwnProfile,
              name: _isOwnProfile
                  ? name ?? 'Guest User'
                  : _getOtherName(postsAsync) ?? 'ผู้ใช้',
              statsAsync: statsAsync,
            ),
          ),

          // ─── ACTION BUTTONS ───
          if (_isOwnProfile)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'แก้ไขโปรไฟล์',
                        icon: Icons.edit_outlined,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'แชร์โปรไฟล์',
                        icon: Icons.share_outlined,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('คัดลอกลิงก์โปรไฟล์แล้ว 🔗')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── BADGE HIGHLIGHTS ───
          SliverToBoxAdapter(
            child: _HighlightCircles(statsAsync: statsAsync),
          ),

          // ─── DIVIDER ───
          SliverToBoxAdapter(
            child: Divider(height: 1, color: Colors.grey[200]),
          ),

          // ─── STICKY TAB BAR ───
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF9800),
                indicatorWeight: 2,
                labelColor: const Color(0xFFFF9800),
                unselectedLabelColor: Colors.grey[400],
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on_rounded, size: 24)),
                  Tab(icon: Icon(Icons.view_list_rounded, size: 24)),
                  Tab(icon: Icon(Icons.bookmark_border_rounded, size: 24)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Grid
            _PostsGridTab(postsAsync: postsAsync, userId: userId, ref: ref),
            // Tab 2: List
            _PostsListTab(postsAsync: postsAsync, userId: userId, ref: ref),
            // Tab 3: Bookmarks
            const _BookmarksTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
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
              child: const Icon(Icons.person_outline, size: 48,
                  color: Color(0xFFFF9800)),
            ),
            const SizedBox(height: 20),
            Text(
              'เข้าสู่ระบบเพื่อดูโปรไฟล์',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'สร้างโปรไฟล์ รายงานสัตว์ สะสมเหรียญรางวัล!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final loggedIn = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (loggedIn == true && context.mounted) {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('เข้าสู่ระบบ',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String? _getOtherAvatar(AsyncValue<List<FeedPost>>? postsAsync) {
    return postsAsync?.asData?.value.firstOrNull?.authorAvatar;
  }

  String? _getOtherName(AsyncValue<List<FeedPost>>? postsAsync) {
    return postsAsync?.asData?.value.firstOrNull?.authorName;
  }
}

// ════════════════════════════════════════════════════════════
// PROFILE HEADER — Avatar + Stats
// ════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final bool isOwn;
  final String? avatarUrl;
  final AsyncValue<UserStats> statsAsync;
  final AsyncValue? reportsAsync;
  final AsyncValue<int>? pointsAsync;
  final AsyncValue<List<FeedPost>>? postsAsync;

  const _ProfileHeader({
    required this.isOwn,
    this.avatarUrl,
    required this.statsAsync,
    this.reportsAsync,
    this.pointsAsync,
    this.postsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // ── Avatar with gradient ring ──
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF6D00), Color(0xFFFFD54F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 42, color: Colors.orange)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // ── Stats columns ──
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  value: _getPostCount(),
                  label: 'โพสต์',
                ),
                _StatColumn(
                  value: statsAsync.when(
                    data: (s) => s.petsHelped.toString(),
                    loading: () => '·',
                    error: (_, __) => '0',
                  ),
                  label: 'ช่วยเหลือ',
                ),
                _StatColumn(
                  value: statsAsync.when(
                    data: (s) => s.totalPoints.toString(),
                    loading: () => '·',
                    error: (_, __) => '0',
                  ),
                  label: 'แต้ม',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPostCount() {
    if (postsAsync != null) {
      return postsAsync!.when(
        data: (posts) => posts.length.toString(),
        loading: () => '·',
        error: (_, __) => '0',
      );
    }
    return '0';
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// BIO SECTION — Name + Level + Streak
// ════════════════════════════════════════════════════════════

class _BioSection extends StatelessWidget {
  final bool isOwn;
  final String name;
  final AsyncValue<UserStats> statsAsync;

  const _BioSection({
    required this.isOwn,
    required this.name,
    required this.statsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          statsAsync.when(
            data: (stats) {
              return Wrap(
                spacing: 8,
                children: [
                  _LevelBadge(level: stats.level),
                  if (stats.currentStreak > 0)
                    Text(
                      '🔥 ${stats.currentStreak} วันติด',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  Text(
                    '· 🐾 รายงาน ${stats.petsReported}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 16),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Level progress bar (own profile only)
          if (isOwn)
            statsAsync.when(
              data: (stats) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stats.progressToNextLevel,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFFF9800)),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${stats.totalPoints} pts',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                        Text(_nextLabel(stats.level),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  String _nextLabel(UserLevel level) {
    final idx = UserLevel.values.indexOf(level) + 1;
    if (idx >= UserLevel.values.length) return 'สูงสุดแล้ว! 🏆';
    return 'ถัดไป: ${UserLevel.values[idx].thaiLabel}';
  }
}

class _LevelBadge extends StatelessWidget {
  final UserLevel level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${level.emoji} ${level.thaiLabel}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _levelColor,
        ),
      ),
    );
  }

  Color get _levelColor {
    return switch (level) {
      UserLevel.beginner => Colors.green,
      UserLevel.bronze => const Color(0xFFCD7F32),
      UserLevel.silver => Colors.blueGrey,
      UserLevel.gold => const Color(0xFFFFD700),
      UserLevel.legend => const Color(0xFF9C27B0),
    };
  }
}

// ════════════════════════════════════════════════════════════
// ACTION BUTTON
// ════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HIGHLIGHT CIRCLES (Badges as IG Highlights)
// ════════════════════════════════════════════════════════════

class _HighlightCircles extends StatelessWidget {
  final AsyncValue<UserStats> statsAsync;

  const _HighlightCircles({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      data: (stats) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: BadgeType.values.length,
              itemBuilder: (context, index) {
                final badge = BadgeType.values[index];
                final earned =
                    stats.badges.any((b) => b.badgeType == badge);
                return _HighlightItem(badge: badge, earned: earned);
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 90),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final BadgeType badge;
  final bool earned;

  const _HighlightItem({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _showBadgeDetail(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: earned
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFFF9800),
                          Color(0xFFFF6D00),
                          Color(0xFFFFD54F)
                        ],
                      )
                    : null,
                border: earned
                    ? null
                    : Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      earned ? Colors.orange.withOpacity(0.08) : Colors.grey[100],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Opacity(
                    opacity: earned ? 1.0 : 0.3,
                    child: Text(badge.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                badge.thaiLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: earned ? Colors.grey[800] : Colors.grey[400],
                  fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(badge.thaiLabel,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(badge.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: earned
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                earned ? '✅ ได้รับแล้ว' : '🔒 ยังไม่ปลดล็อก',
                style: TextStyle(
                  color: earned ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STICKY TAB BAR DELEGATE
// ════════════════════════════════════════════════════════════

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════
// TAB 1: POSTS GRID
// ════════════════════════════════════════════════════════════

class _PostsGridTab extends StatelessWidget {
  final AsyncValue<List<FeedPost>> postsAsync;
  final String userId;
  final WidgetRef ref;

  const _PostsGridTab({
    required this.postsAsync,
    required this.userId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) return _buildEmpty('ยังไม่มีโพสต์', Icons.grid_off_rounded);

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _GridThumbnail(post: post);
          },
        );
      },
      loading: () => _buildGridSkeleton(),
      error: (_, __) => _buildEmpty('เกิดข้อผิดพลาด', Icons.error_outline),
    );
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => Container(color: Colors.grey[200]),
    );
  }

  Widget _buildEmpty(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 15, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

class _GridThumbnail extends StatelessWidget {
  final FeedPost post;

  const _GridThumbnail({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPostDetail(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),
          // Type indicator
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                post.postType.icon,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          // Comment count
          if (post.commentCount > 0)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('${post.commentCount}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(post.postType.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              post.title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Post image
              if (post.imageUrl != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.width,
                  ),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(post.postType.icon,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.postType.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (post.body != null && post.body!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(post.body!,
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey[700])),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      _timeAgo(post.createdAt),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

// ════════════════════════════════════════════════════════════
// TAB 2: POSTS LIST (feed-card style)
// ════════════════════════════════════════════════════════════

class _PostsListTab extends StatelessWidget {
  final AsyncValue<List<FeedPost>> postsAsync;
  final String userId;
  final WidgetRef ref;

  const _PostsListTab({
    required this.postsAsync,
    required this.userId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.article_outlined,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('ยังไม่มีโพสต์',
                    style: TextStyle(fontSize: 15, color: Colors.grey[400])),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: posts.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey[200]),
          itemBuilder: (context, index) {
            final post = posts[index];
            return _ListFeedCard(post: post);
          },
        );
      },
      loading: () => ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => const _ListCardSkeleton(),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('เกิดข้อผิดพลาด',
                style: TextStyle(fontSize: 15, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

class _ListFeedCard extends StatelessWidget {
  final FeedPost post;

  const _ListFeedCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9800).withOpacity(0.12),
                ),
                child: Center(
                  child: Text(post.postType.icon,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(_timeAgo(post.createdAt),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.postType.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Image
        if (post.imageUrl != null)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.width,
            ),
            child: Image.network(
              post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported,
                    color: Colors.grey[400], size: 48),
              ),
            ),
          ),
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                post.myReactions.contains(ReactionType.heart)
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 24,
                color: post.myReactions.contains(ReactionType.heart)
                    ? Colors.red
                    : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text('${post.reactionCounts.heart}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(width: 20),
              Icon(Icons.chat_bubble_outline,
                  size: 22, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text('${post.commentCount}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
        // Body text
        if (post.body != null && post.body!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              post.body!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
      ],
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

class _ListCardSkeleton extends StatelessWidget {
  const _ListCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.grey[200])),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(7))),
                    const SizedBox(height: 4),
                    Container(
                        width: 60,
                        height: 10,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(5))),
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
              Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.grey[200])),
              const SizedBox(width: 12),
              Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.grey[200])),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 3: BOOKMARKS (placeholder)
// ════════════════════════════════════════════════════════════

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_border_rounded,
                size: 40, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีรายการที่บันทึก',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            'กดบันทึกบนโพสต์ที่สนใจ\nเพื่อเก็บไว้ดูทีหลัง',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
