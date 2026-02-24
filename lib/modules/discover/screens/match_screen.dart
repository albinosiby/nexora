import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../connections/repositories/connection_service.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/match_user_model.dart';
import '../controllers/match_controller.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final ConnectionService _connectionService = Get.find<ConnectionService>();
  final MatchController _controller = MatchController.to;
  final NotificationController _notificationController = Get.put(
    NotificationController(),
  );

  final List<String> _filters = ['All', 'Online', 'New', 'Verified'];

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
            expandedHeight: 60.h,
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
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5.w,
                    ),
                  ),
                ),
                const Spacer(),
                Obx(
                  () => _buildHeaderIcon(
                    Icons.notifications_outlined,
                    _notificationController.unreadCount,
                    onTap: () => Get.to(() => const NotificationScreen()),
                  ),
                ),
                SizedBox(width: 12.w),
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
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover New People',
                    style: NexoraTextStyles.headline1.copyWith(
                      fontSize: 28.sp,
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
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 54.h,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(27.r),
                  border: Border.all(color: NexoraColors.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 18.w),
                    Icon(
                      Icons.search_rounded,
                      color: NexoraColors.textMuted,
                      size: 22.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 15.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name, major, interests...',
                          hintStyle: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => _controller.setSearchQuery(value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // Filter Chips with horizontal scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Obx(() => _buildFilterChip(_filters[index], index)),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 24.h)),

          // Discover Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: NexoraColors.accentCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      color: NexoraColors.accentCyan,
                      size: 18.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Discover People',
                    style: TextStyle(
                      color: NexoraColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: NexoraColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: const BoxDecoration(
                              color: NexoraColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${_controller.onlineCount} online',
                            style: TextStyle(
                              color: NexoraColors.success,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content - Realtime Grid View
          Obx(() {
            if (_controller.isLoading.value) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.r),
                    child: const CircularProgressIndicator(
                      color: NexoraColors.primaryPurple,
                    ),
                  ),
                ),
              );
            }

            final filteredUsers = _controller.filteredUsers;

            if (filteredUsers.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.r),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48.r,
                          color: NexoraColors.textMuted.withOpacity(0.5),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No people found',
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.all(20.r),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 16.w,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildModernCard(filteredUsers[index]),
                  childCount: filteredUsers.length,
                ),
              ),
            );
          }),

          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _controller.selectedFilter.value == index;
    final IconData? icon = index == 1
        ? Icons.circle
        : index == 2
        ? Icons.fiber_new_rounded
        : index == 3
        ? Icons.verified_rounded
        : null;

    return GestureDetector(
      onTap: () {
        _controller.setFilter(index);
        _animationController.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected ? NexoraGradients.primaryButton : null,
          color: isSelected ? null : NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : NexoraColors.glassBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: NexoraColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
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
                size: index == 1 ? 8.r : 14.r,
                color: isSelected
                    ? Colors.white
                    : index == 1
                    ? NexoraColors.success
                    : NexoraColors.textMuted,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : NexoraColors.textSecondary,
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(MatchUserModel user) {
    Get.to(
      () => ProfileViewScreen(profile: user.toProfileModel()),
      transition: Transition.rightToLeftWithFade,
    );
  }

  Widget _buildHeaderIcon(IconData icon, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: NexoraColors.glassBackground,
              shape: BoxShape.circle,
              border: Border.all(color: NexoraColors.glassBorder),
            ),
            child: Icon(icon, color: NexoraColors.textPrimary, size: 20.r),
          ),
          if (count > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: const BoxDecoration(
                  color: NexoraColors.romanticPink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 8.sp,
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
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      icon: Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildModernCard(MatchUserModel user) {
    return GestureDetector(
      onTap: () => _navigateToProfile(user),
      child: Container(
        decoration: BoxDecoration(
          color: NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: NexoraColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                      child: Image.network(
                        user.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 40.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Online indicator
                  if (user.isOnline)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 14.r,
                        height: 14.r,
                        decoration: BoxDecoration(
                          color: NexoraColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NexoraColors.midnightDark,
                            width: 2.5.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NexoraColors.success.withOpacity(0.5),
                              blurRadius: 6.r,
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
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name and Age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user.name}, ${user.age}',
                            style: TextStyle(
                              color: NexoraColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified)
                          Icon(
                            Icons.verified_rounded,
                            color: NexoraColors.accentCyan,
                            size: 14.r,
                          ),
                      ],
                    ),

                    // Major and Year
                    Text(
                      '${user.year} • ${user.major}',
                      style: TextStyle(
                        color: NexoraColors.textMuted,
                        fontSize: 10.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Connections count and Connect button
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 12.r,
                          color: NexoraColors.primaryPurple,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${user.connections}',
                          style: TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 10.sp,
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

  Widget _buildConnectionButton(MatchUserModel user) {
    final userId = user.id;
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
              'Connection request to ${user.name} cancelled',
              backgroundColor: NexoraColors.glassBackground,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: EdgeInsets.all(16.r),
              borderRadius: 12.r,
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
              'You are now connected with ${user.name}',
              backgroundColor: NexoraColors.success.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: EdgeInsets.all(16.r),
              borderRadius: 12.r,
              icon: Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
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
              name: user.name,
              avatar: user.avatar,
              major: user.major,
              year: user.year,
            );
            _showConnectSnackbar(user.name);
          };
      }

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: gradient,
            color: bgColor,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: gradient != null
                ? [
                    BoxShadow(
                      color: NexoraColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10.r, color: textColor),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 9.sp,
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
