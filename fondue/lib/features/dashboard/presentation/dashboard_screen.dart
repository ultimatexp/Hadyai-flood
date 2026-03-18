import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../social/presentation/user_profile_page.dart';
import '../../pets/presentation/report_screen.dart';
import '../../pets/presentation/semantic_search_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../chat/data/chat_providers.dart';
import '../../social/presentation/feed_screen.dart';
import '../../social/presentation/create_post_screen.dart';
import '../../social/data/social_providers.dart';
import '../../fuel/presentation/fuel_map_screen.dart';
import '../data/dashboard_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/onboarding_screen.dart';
import '../../../shared/page_transitions.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _badgeBounce;
  late AnimationController _fuelPulseController;
  late Animation<double> _fuelPulse;
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _badgeBounce = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );
    _fuelPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fuelPulse = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _fuelPulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _fuelPulseController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      final user = response.user;
      
      if (user != null && !user.isAnonymous) {
        final onboardingCompleted = user.userMetadata?['onboarding_completed'] == true;
        if (!onboardingCompleted) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking onboarding: $e");
    }
  }

  void _onItemTapped(int index) {
      HapticFeedback.selectionClick();

      // Chat Tab Login Check (Index 3)
      if (index == 3) {
         final user = Supabase.instance.client.auth.currentUser;
         if (user == null || user.isAnonymous) {
           _showLoginScreen();
           return;
         }
      }

      ref.read(dashboardTabIndexProvider.notifier).setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(dashboardTabIndexProvider);
    final unreadChatCountAsync = ref.watch(unreadMessagesCountProvider);
    final unreadChatCount = unreadChatCountAsync.asData?.value ?? 0;

    // Bounce badge when count changes
    if (unreadChatCount > _previousUnreadCount && unreadChatCount > 0) {
      _badgeController.forward(from: 0.0);
    }
    _previousUnreadCount = unreadChatCount;

    final pages = [
      const SemanticSearchScreen(asHomeTab: true),  // 0: Pet Search (Home)
      const FeedScreen(),        // 1: Feed
      const SizedBox(),          // 2: Placeholder (FAB position)
      const ChatListScreen(),    // 3: Chat
      const UserProfilePage(),   // 4: Profile
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: pages,
          ),
          // Fuel Quick Access — animated floating button
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 8,
            child: ScaleTransition(
              scale: _fuelPulse,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FuelMapScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/fuel.png', width: 28, height: 28),
                      const SizedBox(width: 6),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'เช็คน้ำมัน',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'สถานีใกล้คุณ',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Alert dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
             HapticFeedback.mediumImpact();
             final user = Supabase.instance.client.auth.currentUser;
             if (user == null || user.isAnonymous) {
               _showLoginScreen();
             } else {
               _showCreateOptions(context);
             }
        },
        elevation: 8.0,
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFFFF9800),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _FrostedBottomNav(
        currentIndex: currentIndex,
        unreadChatCount: unreadChatCount,
        badgeBounce: _badgeBounce,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showLoginScreen() {
    Navigator.push(
      context,
      SlideUpPageRoute(page: const LoginScreen()),
    ).then((loggedIn) {
      if (loggedIn == true) {
        setState(() {});
        _checkOnboarding();
      }
    });
  }

  void _showCreateOptions(BuildContext context) {
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets, color: Color(0xFFFF9800)),
                ),
                title: const Text('รายงานสัตว์เลี้ยง', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('แจ้งพบ / หาสัตว์หาย', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, SlideUpPageRoute(page: const ReportScreen()));
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_square, color: Color(0xFF4CAF50)),
                ),
                title: const Text('สร้างโพสต์', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('แชร์เรื่องราว ข่าวสาร ภาพ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    SlideUpPageRoute(page: const CreatePostScreen()),
                  ).then((result) {
                    if (result == true) {
                      ref.read(dashboardTabIndexProvider.notifier).setTab(0);
                      ref.invalidate(feedPostsProvider);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted glass bottom navigation bar with 5 tabs + center FAB
class _FrostedBottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadChatCount;
  final Animation<double> badgeBounce;
  final ValueChanged<int> onTap;

  const _FrostedBottomNav({
    required this.currentIndex,
    required this.unreadChatCount,
    required this.badgeBounce,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.search_rounded, 'ค้นหา'),
                _buildNavItem(1, Icons.dynamic_feed_rounded, 'ฟีด'),
                const SizedBox(width: 56), // Space for FAB
                _buildChatNavItem(),
                _buildNavItem(4, Icons.person_rounded, 'โปรไฟล์'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFF9800).withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFFFF9800) : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFFFF9800) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatNavItem() {
    final isActive = currentIndex == 3;
    return GestureDetector(
      onTap: () => onTap(3),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFF9800).withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: unreadChatCount > 0
                  ? ScaleTransition(
                      scale: badgeBounce,
                      child: Badge(
                        label: Text('$unreadChatCount',
                            style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          color: isActive
                              ? const Color(0xFFFF9800)
                              : Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.chat_bubble_rounded,
                      color: isActive
                          ? const Color(0xFFFF9800)
                          : Colors.grey[400],
                      size: 24,
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              'แชท',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFFFF9800) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
