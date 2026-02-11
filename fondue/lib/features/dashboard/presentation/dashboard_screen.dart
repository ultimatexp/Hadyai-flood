import 'package:flutter/material.dart';
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
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
      // Chat Tab Login Check (Index 2)
      if (index == 2) {
         final user = Supabase.instance.client.auth.currentUser;
         if (user == null || user.isAnonymous) {
           _showLoginScreen();
           return;
         }
      }

      // Profile Tab Login Check (Index 3)
      if (index == 3) {
         // Profile might be accessible but maybe restricted features? 
         // For now, allow profile access to let them login/logout.
      }

      ref.read(dashboardTabIndexProvider.notifier).setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(dashboardTabIndexProvider);
    final unreadChatCountAsync = ref.watch(unreadMessagesCountProvider);
    final unreadChatCount = unreadChatCountAsync.asData?.value ?? 0;

    final pages = [
      const OverviewScreen(),
      const PetFeedScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
             final user = Supabase.instance.client.auth.currentUser;
             if (user == null || user.isAnonymous) {
               _showLoginScreen();
             } else {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportScreen()),
              );
             }
        },
        elevation: 4.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        height: 60, 
        color: const Color(0xFFFF9800), // Orange background
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home, color: currentIndex == 0 ? Colors.white : Colors.white70),
              onPressed: () => _onItemTapped(0),
              tooltip: 'Home',
            ),
            IconButton(
              icon: Icon(Icons.list, color: currentIndex == 1 ? Colors.white : Colors.white70),
              onPressed: () => _onItemTapped(1),
              tooltip: 'List',
            ),
            const SizedBox(width: 48), // Space for FAB
            
            // Chat Icon with Badge
            IconButton(
              icon: kIsUnreadCountVisible(unreadChatCount) 
                  ? Badge(
                      label: Text('$unreadChatCount'),
                      backgroundColor: Colors.red,
                      child: Icon(Icons.chat_bubble, color: currentIndex == 2 ? Colors.white : Colors.white70),
                    )
                  : Icon(Icons.chat_bubble, color: currentIndex == 2 ? Colors.white : Colors.white70),
              onPressed: () => _onItemTapped(2),
              tooltip: 'Chat',
            ),
            
            IconButton(
              icon: Icon(Icons.person, color: currentIndex == 3 ? Colors.white : Colors.white70),
              onPressed: () => _onItemTapped(3),
              tooltip: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  bool kIsUnreadCountVisible(int count) => count > 0;

  void _showLoginScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ).then((loggedIn) {
      if (loggedIn == true) {
        setState(() {}); // Refresh state to update UI if needed
        _checkOnboarding();
        // If they logged in to chat, auto-switch to chat? Maybe.
      }
    });
  }
}
