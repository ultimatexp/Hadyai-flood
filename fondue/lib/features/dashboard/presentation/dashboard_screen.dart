import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pets/presentation/pet_feed_screen.dart';
import '../../pets/presentation/map_view_screen.dart';
import '../../auth/presentation/profile_screen.dart';
import '../../pets/presentation/report_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../chat/data/chat_providers.dart';
import '../data/dashboard_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/onboarding_screen.dart';
import 'overview_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  @override
  void dispose() {
    _badgeController.dispose();
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

      // Chat Tab Login Check (Index 2)
      if (index == 2) {
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
      const OverviewScreen(),
      const PetFeedScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
             HapticFeedback.mediumImpact();
             final user = Supabase.instance.client.auth.currentUser;
             if (user == null || user.isAnonymous) {
               _showLoginScreen();
             } else {
               Navigator.push(
                context,
                SlideUpPageRoute(page: const ReportScreen()),
              );
             }
        },
        elevation: 6.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
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
}

/// Frosted glass bottom navigation bar with animated indicator
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
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.pets_rounded, 'Pets'),
                const SizedBox(width: 56), // Space for FAB
                _buildChatNavItem(),
                _buildNavItem(3, Icons.person_rounded, 'Profile'),
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
    final isActive = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
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
              'Chat',
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
