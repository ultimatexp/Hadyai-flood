import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../inbox/presentation/inbox_screen.dart';
import '../../points/points_provider.dart';
import '../../pets/presentation/my_reports_screen.dart';
import '../../pets/presentation/my_pet_profiles_screen.dart';
import '../../pets/presentation/potential_matches_screen.dart';
import '../../pets/presentation/pet_providers.dart';
import '../../settings/presentation/privacy_policy_screen.dart';
import '../../settings/presentation/terms_conditions_screen.dart';
import '../../social/data/social_providers.dart';
import '../../social/domain/user_stats.dart';
import '../../social/presentation/activity_feed_screen.dart';
import '../../store/presentation/store_screen.dart';
import 'edit_profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;
        final pointsAsync = ref.watch(pointsProvider);
        final myReportsAsync = ref.watch(myReportsProvider);
        final statsAsync = ref.watch(currentUserStatsProvider);
        final email = user?.email ?? 'guest@fondue.app';
        final name = user?.userMetadata?['full_name'] ?? 'Guest User';
        final avatarUrl = user?.userMetadata?['avatar_url'];

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ═══════════════════════════════
                // 1. HEADER (Instagram-style)
                // ═══════════════════════════════
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 24, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null
                                  ? const Icon(Icons.person, size: 42, color: Colors.orange)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Stats columns (Instagram-style)
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(
                                  myReportsAsync.when(
                                    data: (r) => r.length.toString(),
                                    loading: () => '...',
                                    error: (_, __) => '0',
                                  ),
                                  'รายงาน',
                                ),
                                _buildStatColumn(
                                  myReportsAsync.when(
                                    data: (r) => r.where((p) => p.status == 'FOUND').length.toString(),
                                    loading: () => '...',
                                    error: (_, __) => '0',
                                  ),
                                  'ช่วยเหลือ',
                                ),
                                _buildStatColumn(
                                  pointsAsync.when(
                                    data: (pts) => pts.toString(),
                                    loading: () => '...',
                                    error: (_, __) => '0',
                                  ),
                                  'แต้ม',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Name + Level badge
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Level badge
                                statsAsync.when(
                                  data: (stats) {
                                    if (stats == null) return const SizedBox.shrink();
                                    return Row(
                                      children: [
                                        Text(stats.level.emoji, style: const TextStyle(fontSize: 14)),
                                        const SizedBox(width: 4),
                                        Text(
                                          stats.level.thaiLabel,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (stats.currentStreak > 0) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '🔥 ${stats.currentStreak} วันติด',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.85),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                          if (user != null && !user.isAnonymous)
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('แก้ไข', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                        ],
                      ),

                      // Level progress bar
                      statsAsync.when(
                        data: (stats) {
                          if (stats == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: stats.progressToNextLevel,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${stats.totalPoints} pts',
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                    ),
                                    Text(
                                      'ถัดไป: ${_nextLevelLabel(stats.level)}',
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════
                // 2. BADGES SECTION
                // ═══════════════════════════════
                statsAsync.when(
                  data: (stats) {
                    if (stats == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('🏆', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text(
                                'เหรียญรางวัล',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: BadgeType.values.length,
                              itemBuilder: (context, index) {
                                final badgeType = BadgeType.values[index];
                                final earned = stats.badges.any((b) => b.badgeType == badgeType);
                                return _BadgeItem(
                                  badgeType: badgeType,
                                  earned: earned,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // ═══════════════════════════════
                // 3. STORE SECTION
                // ═══════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ร้านค้า',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'อาหาร • อุปกรณ์ • ของเล่นสัตว์เลี้ยง',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ═══════════════════════════════
                // 4. MENU OPTIONS
                // ═══════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildMenuCard([
                        _buildMenuItem(Icons.favorite_border, "สัตว์เลี้ยงของฉัน", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPetProfilesScreen()));
                        }),
                        _buildMenuItem(Icons.pets, "My Reports", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()));
                        }),
                        _buildMenuItem(Icons.saved_search, "My Potential Matches", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PotentialMatchesScreen()));
                        }),
                        _buildMenuItem(Icons.timeline, "กิจกรรม", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityFeedScreen()));
                        }),
                      ]),

                      const SizedBox(height: 16),

                      _buildMenuCard([
                        _buildMenuItem(Icons.notifications_outlined, "แจ้งเตือน", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
                        }, hasBadge: true),
                        _buildMenuItem(Icons.settings_outlined, "ตั้งค่า", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        }),
                        _buildMenuItem(Icons.language, "ภาษา", () {}, trailing: "ไทย"),
                      ]),

                      const SizedBox(height: 16),

                      _buildMenuCard([
                        _buildMenuItem(Icons.help_outline, "ช่วยเหลือ", () {
                          launchUrl(Uri.parse('https://lin.ee/dLvcA22'), mode: LaunchMode.externalApplication);
                        }),
                        _buildMenuItem(Icons.privacy_tip_outlined, "นโยบายความเป็นส่วนตัว", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                        }),
                        _buildMenuItem(Icons.description_outlined, "ข้อกำหนดการใช้งาน", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen()));
                        }),
                      ]),

                      const SizedBox(height: 24),

                      // Log In / Sign Out
                      if (user == null || user.isAnonymous)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('เข้าสู่ระบบ / สมัครสมาชิก', style: TextStyle(fontSize: 16)),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () async {
                            final repo = AuthRepository(Supabase.instance.client);
                            await repo.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            "ออกจากระบบ",
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _nextLevelLabel(UserLevel level) {
    final idx = UserLevel.values.indexOf(level) + 1;
    if (idx >= UserLevel.values.length) return 'สูงสุดแล้ว!';
    return UserLevel.values[idx].thaiLabel;
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool hasBadge = false, String? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(trailing, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ),
              if (hasBadge)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// BADGE ITEM
// ═══════════════════════════════════════
class _BadgeItem extends StatelessWidget {
  final BadgeType badgeType;
  final bool earned;

  const _BadgeItem({required this.badgeType, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
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
                  Text(badgeType.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    badgeType.thaiLabel,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badgeType.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: earned ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
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
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
                border: Border.all(
                  color: earned ? const Color(0xFFFF9800) : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: earned ? 1.0 : 0.35,
                  child: Text(badgeType.emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badgeType.thaiLabel,
              style: TextStyle(
                fontSize: 10,
                color: earned ? Colors.black87 : Colors.grey,
                fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
