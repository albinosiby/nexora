import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../../connections/repositories/connection_service.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../profile/repositories/user_repository.dart';
import '../../chat/screens/chat_detail_screen.dart';
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
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  final List<String> _filters = ['All', 'Online', 'New'];

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

  void _openChat(MatchUserModel user) {
    Get.to(
      () => ChatDetailScreen(
        name: user.displayName,
        avatar: user.avatar,
        chatId: '', // Will be resolved by repository
        participantId: user.id,
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            CustomScrollView(
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
                          'Koottu',
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
                              onChanged: (value) =>
                                  _controller.setSearchQuery(value),
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
                          child: Obx(
                            () => _buildFilterChip(_filters[index], index),
                          ),
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
                        crossAxisCount: 3,
                        mainAxisSpacing: 12.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildModernCard(filteredUsers[index]),
                        childCount: filteredUsers.length,
                      ),
                    ),
                  );
                }),

                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),
          ],
        ),
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
          gradient: isSelected ? NexoraGradients.glassyGradient : null,
          color: isSelected ? null : NexoraColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? NexoraColors.primaryPurple.withOpacity(0.5)
                : const Color(0xFF2A1A00), // Dark brown border
            width: 1.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: NexoraColors.primaryPurple.withOpacity(0.2),
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

  Widget _buildModernCard(MatchUserModel user) {
    return GestureDetector(
      onTap: () => _navigateToProfile(user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // Full-bleed Profile Image
              Positioned.fill(
                child: Image.network(
                  user.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(user.displayName)}&backgroundColor=transparent&size=200',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Bottom Gradient Overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // Info & Action Section
              Positioned(
                bottom: 12.r,
                left: 12.r,
                right: 12.r,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      user.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: const Offset(0, 1),
                            blurRadius: 4.r,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),

                    // Modern Footer Buttons
                    Container(
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Message Button
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openChat(user),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(16.r),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                    size: 14.r,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Chat/Connect Button
                          Expanded(child: _buildGlassyActionButton(user)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Online indicator (real-time from RTDB)
              Positioned(
                top: 10,
                right: 10,
                child: StreamBuilder<bool>(
                  stream: UserRepository.instance.getUserPresenceStream(
                    user.id,
                  ),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data ?? user.isOnline;
                    if (!isOnline) return const SizedBox.shrink();
                    return Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: BoxDecoration(
                        color: NexoraColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: NexoraColors.success.withOpacity(0.5),
                            blurRadius: 4.r,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassyActionButton(MatchUserModel user) {
    final userId = user.id;
    return Obx(() {
      final status = _connectionService.getStatus(userId);

      bool isConnected = status == ConnectionStatus.connected;
      bool isPending = status == ConnectionStatus.pending;

      return GestureDetector(
        onTap: () async {
          if (isConnected) return;
          if (isPending) {
            _connectionService.cancelRequest(userId);
            return;
          }
          // 1. Trigger Like (Artistic engagement)
          await UserRepository.instance.toggleProfileLike(userId);

          // 2. Send Connection Request
          await _connectionService.sendRequest(
            userId: userId,
            name: user.displayName,
            avatar: user.avatar,
            major: user.major,
            year: user.year,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: NexoraGradients.primaryButton,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(16.r)),
            border: Border.all(
              color: NexoraColors.primaryPurple.withOpacity(0.2),
              width: 1.w,
            ),
          ),
          child: Center(
            child: Icon(
              isPending
                  ? Icons.hourglass_empty_rounded
                  : isConnected
                  ? Icons.check_circle_rounded
                  : Icons.person_add_rounded,
              color: Colors.white,
              size: 14.r,
            ),
          ),
        ),
      );
    });
  }
}
