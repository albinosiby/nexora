import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/nexora_theme.dart';
import 'widgets/dark_background.dart';
import 'widgets/glass_container.dart';
import '../modules/discover/screens/match_screen.dart';
import '../modules/chat/screens/chat_list_screen.dart';
import '../modules/feed/screens/broadcast_screen.dart';
import '../modules/profile/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                  navIcon(Icons.chat, 1, 'Chats'),
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

  Widget navIcon(IconData icon, int index, String label) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? NexoraColors.primaryPurple
                : NexoraColors.textSecondary,
            size: 24.r,
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
