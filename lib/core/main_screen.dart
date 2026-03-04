import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/nexora_theme.dart';
import 'widgets/dark_background.dart';
import 'widgets/glass_container.dart';
import '../modules/discover/screens/match_screen.dart';
import '../modules/chat/screens/chat_list_screen.dart';
import '../modules/feed/screens/broadcast_screen.dart';
import '../modules/profile/screens/profile_screen.dart';
import '../modules/chat/providers/chat_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: selectedIndex,
          children: const [
            MatchScreen(),
            ChatListScreen(),
            BroadcastScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.all(20.w),
          child: GlassContainer(
            borderRadius: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  navIcon(Icons.explore, 0, 'Discover'),
                  navIcon(Icons.chat, 1, 'Chats', badgeCount: unreadCount),
                  navIcon(Icons.campaign, 2, 'Feed'),
                  navIcon(Icons.person, 3, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navIcon(IconData icon, int index, String label, {int badgeCount = 0}) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isActive
                    ? NexoraColors.primaryPurple
                    : NexoraColors.textSecondary,
                size: 24.r,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -6.w,
                  top: -6.h,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(
                      color: NexoraColors.romanticPink,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.w,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isActive
                  ? NexoraColors.primaryPurple
                  : NexoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
