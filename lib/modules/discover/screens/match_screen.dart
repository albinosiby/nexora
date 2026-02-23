import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/services/dummy_database.dart' hide ConnectionStatus;
import '../../connections/repositories/connection_service.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  int _selectedFilter = 0;
  String _searchQuery = '';
  final ConnectionService _connectionService = Get.find<ConnectionService>();
  final DummyDatabase _db = DummyDatabase.instance;

  final List<String> _filters = ['All', 'Online', 'New', 'Verified'];

  List<Map<String, dynamic>> get users {
    return _db.users
        .map((user) {
          return {
            'id': user.id,
            'name': user.displayName,
            'age': user.age,
            'year': user.year,
            'major': user.major,
            'bio': user.bio,
            'interests': user.interests,
            'image': user.avatar,
            'connections': user.connections,
            'isOnline': user.isOnline,
            'isVerified': user.isVerified,
            'lastActive': _formatLastActive(user.lastActive),
            'photos': user.photos ?? [user.avatar],
          };
        })
        .where((user) {
          // Apply filter
          switch (_selectedFilter) {
            case 1: // Online
              if (user['isOnline'] != true) return false;
              break;
            case 2: // New (less than 50 connections)
              if ((user['connections'] as int) >= 50) return false;
              break;
            case 3: // Verified
              if (user['isVerified'] != true) return false;
              break;
            default:
              break;
          }
          // Apply search
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final name = (user['name'] ?? '').toString().toLowerCase();
            final major = (user['major'] ?? '').toString().toLowerCase();
            final interests = (user['interests'] ?? '')
                .toString()
                .toLowerCase();
            final bio = (user['bio'] ?? '').toString().toLowerCase();
            if (!(name.contains(query) ||
                major.contains(query) ||
                interests.contains(query) ||
                bio.contains(query))) {
              return false;
            }
          }
          return true;
        })
        .toList();
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(lastActive);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 60,
            title: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      NexoraColors.primaryPurple,
                      NexoraColors.romanticPink,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Kootu',
                    style: NexoraTextStyles.headline2.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                _buildHeaderIcon(
                  Icons.notifications_outlined,
                  3,
                  onTap: () => Get.to(() => const NotificationScreen()),
                ),
                const SizedBox(width: 12),
                _buildHeaderIcon(
                  Icons.settings_outlined,
                  0,
                  onTap: () => Get.to(() => const SettingsScreen()),
                ),
              ],
            ),
          ),

          // Greeting Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover New People',
                    style: NexoraTextStyles.headline1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: NexoraColors.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 18),
                    const Icon(
                      Icons.search_rounded,
                      color: NexoraColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search by name, major, interests...',
                          hintStyle: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Filter Chips with horizontal scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildFilterChip(_filters[index], index),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Discover Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NexoraColors.accentCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      color: NexoraColors.accentCyan,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Discover People',
                    style: TextStyle(
                      color: NexoraColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: NexoraColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: NexoraColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${users.where((u) => u['isOnline'] == true).length} online',
                          style: const TextStyle(
                            color: NexoraColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content - Grid View
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildModernCard(users[index]),
                childCount: users.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    final IconData? icon = index == 1
        ? Icons.circle
        : index == 2
        ? Icons.fiber_new_rounded
        : index == 3
        ? Icons.verified_rounded
        : null;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? NexoraGradients.primaryButton : null,
          color: isSelected ? null : NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : NexoraColors.glassBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: NexoraColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: index == 1 ? 8 : 14,
                color: isSelected
                    ? Colors.white
                    : index == 1
                    ? NexoraColors.success
                    : NexoraColors.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : NexoraColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(Map<String, dynamic> user) {
    Get.to(
      () => ProfileViewScreen(
        userId: user['id']?.toString() ?? '${user['name']?.hashCode ?? 0}',
        name: user['name'],
        avatar:
            user['image'] ??
            'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(user['name'] as String)}&backgroundColor=transparent',
        bio: user['bio'] ?? '',
        year: user['year'] ?? '',
        major: user['major'] ?? '',
        isOnline: user['isOnline'] ?? false,
      ),
      transition: Transition.rightToLeftWithFade,
    );
  }

  Widget _buildHeaderIcon(IconData icon, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NexoraColors.glassBackground,
              shape: BoxShape.circle,
              border: Border.all(color: NexoraColors.glassBorder),
            ),
            child: Icon(icon, color: NexoraColors.textPrimary, size: 20),
          ),
          if (count > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: NexoraColors.romanticPink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showConnectSnackbar(String name) {
    Get.snackbar(
      'Connection Request Sent',
      'You sent a connection request to $name',
      backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () => _navigateToProfile(user),
      child: Container(
        decoration: BoxDecoration(
          color: NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: NexoraColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image with Online Indicator
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          NexoraColors.primaryPurple.withOpacity(0.7),
                          NexoraColors.romanticPink.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Image.network(
                        user['image'] ??
                            'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(user['name'] as String)}&backgroundColor=transparent',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            (user['name'] as String).isNotEmpty
                                ? (user['name'] as String)[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Online indicator
                  if (user['isOnline'])
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: NexoraColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NexoraColors.midnightDark,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NexoraColors.success.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action buttons
                ],
              ),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name and Age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user['name']}, ${user['age']}',
                            style: const TextStyle(
                              color: NexoraColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          color: NexoraColors.accentCyan,
                          size: 14,
                        ),
                      ],
                    ),

                    // Major and Year
                    Text(
                      '${user['year']} • ${user['major']}',
                      style: const TextStyle(
                        color: NexoraColors.textMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Connections count and Connect button
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 12,
                          color: NexoraColors.primaryPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user['connections']}',
                          style: const TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _buildConnectionButton(user),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton(Map<String, dynamic> user) {
    final userId = '${user['name']?.hashCode ?? 0}';
    return Obx(() {
      final status = _connectionService.getStatus(userId);

      IconData icon;
      String label;
      Gradient? gradient;
      Color? bgColor;
      Color textColor = Colors.white;
      VoidCallback? onTap;

      switch (status) {
        case ConnectionStatus.connected:
          icon = Icons.check_circle_rounded;
          label = 'Connected';
          bgColor = NexoraColors.success.withOpacity(0.2);
          textColor = NexoraColors.success;
          gradient = null;
          onTap = null;
          break;
        case ConnectionStatus.pending:
          icon = Icons.schedule_rounded;
          label = 'Pending';
          bgColor = NexoraColors.textMuted.withOpacity(0.2);
          textColor = NexoraColors.textSecondary;
          gradient = null;
          onTap = () {
            _connectionService.cancelRequest(userId);
            Get.snackbar(
              'Request Cancelled',
              'Connection request to ${user['name']} cancelled',
              backgroundColor: NexoraColors.glassBackground,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          };
          break;
        case ConnectionStatus.incoming:
          icon = Icons.person_add_alt_1_rounded;
          label = 'Accept';
          gradient = const LinearGradient(
            colors: [NexoraColors.accentCyan, NexoraColors.success],
          );
          onTap = () {
            _connectionService.acceptRequest(userId);
            Get.snackbar(
              'Connected!',
              'You are now connected with ${user['name']}',
              backgroundColor: NexoraColors.success.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              icon: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.check_circle_rounded, color: Colors.white),
              ),
            );
          };
          break;
        case ConnectionStatus.none:
          icon = Icons.person_add_rounded;
          label = 'Connect';
          gradient = NexoraGradients.primaryButton;
          onTap = () {
            _connectionService.sendRequest(
              userId: userId,
              name: user['name'] ?? '',
              avatar: user['image'] ?? '',
              major: user['major'] ?? '',
              year: user['year'] ?? '',
            );
            _showConnectSnackbar(user['name']);
          };
      }

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: gradient,
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: gradient != null
                ? [
                    BoxShadow(
                      color: NexoraColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
