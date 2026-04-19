import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fondue/l10n/app_localizations_context.dart';
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
import '../../settings/presentation/language_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../donate/top_donors_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final l10n = context.l10n;
        final useThai = Localizations.localeOf(context).languageCode == 'th';
        final user = Supabase.instance.client.auth.currentUser;
        final pointsAsync = ref.watch(pointsProvider);
        final myReportsAsync = ref.watch(myReportsProvider);
        final statsAsync = ref.watch(currentUserStatsProvider);
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
                                  l10n.profileStatsReports,
                                ),
                                _buildStatColumn(
                                  myReportsAsync.when(
                                    data: (r) => r.where((p) => p.status == 'FOUND').length.toString(),
                                    loading: () => '...',
                                    error: (_, __) => '0',
                                  ),
                                  l10n.profileStatsHelped,
                                ),
                                _buildStatColumn(
                                  pointsAsync.when(
                                    data: (pts) => pts.toString(),
                                    loading: () => '...',
                                    error: (_, __) => '0',
                                  ),
                                  l10n.profileStatsPoints,
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
                                          useThai ? stats.level.thaiLabel : stats.level.englishLabel,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (stats.currentStreak > 0) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.profileStreakDays(stats.currentStreak),
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
                              child: Text(l10n.profileEdit, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                                      l10n.profilePointsLabel(stats.totalPoints),
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                    ),
                                    Text(
                                      l10n.profileNextLevelPrefix(_nextLevelLabel(context, stats.level)),
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
                          Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                l10n.profileBadgesTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                  useThai: useThai,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.storeTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.storeSubtitle,
                                  style: const TextStyle(
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
                        _buildMenuItem(Icons.favorite_border, l10n.profileMenuMyPets, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPetProfilesScreen()));
                        }),
                        _buildMenuItem(Icons.pets, l10n.profileMenuMyReports, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()));
                        }),
                        _buildMenuItem(Icons.saved_search, l10n.profileMenuPotentialMatches, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PotentialMatchesScreen()));
                        }),
                        _buildMenuItem(Icons.timeline, l10n.profileMenuActivity, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityFeedScreen()));
                        }),
                        _buildMenuItem(Icons.emoji_events_outlined, l10n.profileMenuTopDonors, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TopDonorsScreen()));
                        }),
                      ]),

                      const SizedBox(height: 16),

                      _buildMenuCard([
                        _buildMenuItem(Icons.notifications_outlined, l10n.profileMenuNotifications, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
                        }, hasBadge: true),
                        _buildMenuItem(Icons.settings_outlined, l10n.profileMenuSettings, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        }),
                        _buildMenuItem(
                          Icons.language,
                          l10n.profileMenuLanguage,
                          () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
                          },
                          trailing: Localizations.localeOf(context).languageCode == 'th'
                              ? l10n.profileLanguageDisplayThai
                              : l10n.profileLanguageDisplayEnglish,
                        ),
                      ]),

                      const SizedBox(height: 16),

                      _buildMenuCard([
                        _buildMenuItem(Icons.help_outline, l10n.profileMenuHelp, () {
                          launchUrl(Uri.parse('https://lin.ee/dLvcA22'), mode: LaunchMode.externalApplication);
                        }),
                        _buildMenuItem(Icons.privacy_tip_outlined, l10n.profileMenuPrivacy, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                        }),
                        _buildMenuItem(Icons.description_outlined, l10n.profileMenuTerms, () {
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
                            child: Text(l10n.profileLoginSignup, style: const TextStyle(fontSize: 16)),
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
                          child: Text(
                            l10n.profileSignOut,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
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

  String _nextLevelLabel(BuildContext context, UserLevel level) {
    final useThai = Localizations.localeOf(context).languageCode == 'th';
    final idx = UserLevel.values.indexOf(level) + 1;
    if (idx >= UserLevel.values.length) return context.l10n.profileMaxLevel;
    final next = UserLevel.values[idx];
    return useThai ? next.thaiLabel : next.englishLabel;
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
  final bool useThai;

  const _BadgeItem({required this.badgeType, required this.earned, required this.useThai});

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
            builder: (sheetContext) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(badgeType.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    useThai ? badgeType.thaiLabel : badgeType.englishLabel,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    useThai ? badgeType.description : badgeType.englishDescription,
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
                      earned ? sheetContext.l10n.profileBadgeUnlocked : sheetContext.l10n.profileBadgeLocked,
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
              useThai ? badgeType.thaiLabel : badgeType.englishLabel,
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
