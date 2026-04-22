import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fondue/l10n/app_localizations.dart';
import 'package:fondue/l10n/app_localizations_context.dart';
import '../../social/presentation/user_profile_page.dart';
import '../../pets/presentation/report_screen.dart';
import '../../pets/presentation/semantic_search_screen.dart';
import '../../pets/presentation/map_view_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../chat/data/chat_providers.dart';
import '../../social/presentation/feed_screen.dart';
import '../../social/presentation/create_post_screen.dart';
import '../../social/data/social_providers.dart';
import '../data/dashboard_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/onboarding_screen.dart';
import '../../auth/presentation/terms_gate_screen.dart';
import '../../auth/data/user_profile_repository.dart';
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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Rebuild tabs (IndexedStack) when auth changes — e.g. login from Profile tab
    // does not go through _showLoginScreen's .then(setState).
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userUpdated:
        case AuthChangeEvent.initialSession:
          if (mounted) setState(() {});
        default:
          break;
      }
    });
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
    _authSubscription?.cancel();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      final user = response.user;
      
      if (user != null && !user.isAnonymous) {
        final onboardingCompleted = user.userMetadata?['onboarding_completed'] == true;
        final termsAccepted = user.userMetadata?['terms_accepted'] == true;
        final termsVersion = user.userMetadata?['terms_version'] as String?;

        if (!termsAccepted || termsVersion != UserProfileRepository.currentTermsVersion) {
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsGateScreen()),
            );
          }
          return;
        }
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
    final l10n = context.l10n;
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
          // Pet map — only on home tab (nested Scaffold FAB would sit under the center + FAB)
          if (currentIndex == 0)
            Positioned(
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 78,
              child: FloatingActionButton.extended(
                heroTag: 'dashboard_pet_map_fab',
                elevation: 5,
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MapViewScreen()),
                  );
                },
                icon: const Icon(Icons.map_rounded, size: 22),
                label: Text(l10n.mapFabLabel),
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
        l10n: l10n,
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
    final l10n = context.l10n;
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
                title: Text(l10n.createSheetReportPetTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  l10n.createSheetReportPetSubtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
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
                title: Text(l10n.createSheetNewPostTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  l10n.createSheetNewPostSubtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
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
  final AppLocalizations l10n;

  const _FrostedBottomNav({
    required this.currentIndex,
    required this.unreadChatCount,
    required this.badgeBounce,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Same vertical inset above icons and above home indicator (inset excludes system bar).
    const verticalInset = 10.0;

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
            padding: EdgeInsets.fromLTRB(
              0,
              verticalInset,
              0,
              verticalInset + bottomInset,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(0, Icons.search_rounded, l10n.navSearch),
                _buildNavItem(1, Icons.dynamic_feed_rounded, l10n.navFeed),
                const SizedBox(width: 56), // Space for FAB
                _buildChatNavItem(),
                _buildNavItem(4, Icons.person_rounded, l10n.navProfile),
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
          mainAxisSize: MainAxisSize.min,
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
          mainAxisSize: MainAxisSize.min,
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
              l10n.navChat,
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
