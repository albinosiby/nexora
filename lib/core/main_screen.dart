import 'package:flutter/material.dart';
import 'theme/nexora_theme.dart';
import 'widgets/dark_background.dart';
import 'widgets/glass_container.dart';
import '../modules/discover/screens/match_screen.dart';
import '../modules/chat/screens/chat_list_screen.dart';
import '../modules/stories/screens/broadcast_screen.dart';
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
          padding: const EdgeInsets.all(20),
          child: GlassContainer(
            borderRadius: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
