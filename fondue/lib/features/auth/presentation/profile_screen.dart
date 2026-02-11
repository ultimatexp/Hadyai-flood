import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../points/points_provider.dart';
import '../../pets/presentation/my_reports_screen.dart';
import '../../pets/presentation/potential_matches_screen.dart';
import '../../pets/presentation/pet_providers.dart';
import '../../settings/presentation/privacy_policy_screen.dart';
import '../../settings/presentation/terms_conditions_screen.dart';
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
    // Mock user data if null/anon
    final email = user?.email ?? 'guest@fondue.app';
    final name = user?.userMetadata?['full_name'] ?? 'Guest User';
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Profile Section
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFF9800), // Orange theme
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.orange)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Text Info
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Edit Button
                  if (user != null && !user.isAnonymous) // Only show Edit if logged in
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    },
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        "Reports", 
                        myReportsAsync.when(
                          data: (reports) => reports.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.white30),
                      _buildStatItem(
                        "Helping", 
                        myReportsAsync.when(
                          data: (reports) => reports.where((p) => p.status == 'FOUND').length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.white30),
                      _buildStatItem(
                        "Points", 
                        pointsAsync.when(
                          data: (pts) => pts.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Menu Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   _buildMenuCard([
                    _buildMenuItem(Icons.pets, "My Reports", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()));
                    }),
                    _buildMenuItem(Icons.saved_search, "My Potential Matches", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PotentialMatchesScreen()));
                    }),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  _buildMenuCard([
                    _buildMenuItem(Icons.notifications_outlined, "Notifications", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
                    }, hasBadge: true),
                    _buildMenuItem(Icons.settings_outlined, "Settings", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                    _buildMenuItem(Icons.language, "Language", () {}, trailing: "English"),
                  ]),

                  const SizedBox(height: 20),

                  _buildMenuCard([
                    _buildMenuItem(Icons.help_outline, "Help & Support", () {
                      launchUrl(Uri.parse('https://lin.ee/dLvcA22'), mode: LaunchMode.externalApplication);
                    }),
                    _buildMenuItem(Icons.info_outline, "About Us", () {}),
                    _buildMenuItem(Icons.privacy_tip_outlined, "Privacy Policy", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                    }),
                    _buildMenuItem(Icons.description_outlined, "Terms & Conditions", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen()));
                    }),
                  ]),
                  
                  const SizedBox(height: 30),
                  
                  // Log In / Sign Out Button
                  if (user == null || user.isAnonymous)
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                      child: const Text(
                        "Log In / Sign Up",
                        style: TextStyle(color: AppTheme.accentOrange, fontSize: 16),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () async {
                        final repo = AuthRepository(Supabase.instance.client);
                        await repo.signOut();
                        // Restart app to Dashboard (Guest Mode)
                        if (context.mounted) {
                           Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const DashboardScreen()),
                            (route) => false,
                           );
                        }
                      },
                      child: const Text(
                        "Sign Out",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  
                  const SizedBox(height: 40),
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

  Widget _buildStatItem(String label, String value) {
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
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool hasBadge = false, String? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    trailing,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              if (hasBadge)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
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
