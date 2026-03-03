import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';
import '../../connections/repositories/connection_service.dart';
import '../../chat/screens/chat_detail_screen.dart';
import '../models/profile_model.dart';
import '../repositories/user_repository.dart';

/// Profile View Screen - View another user's profile with message option
class ProfileViewScreen extends StatefulWidget {
  final ProfileModel profile;

  const ProfileViewScreen({required this.profile, super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLiked = false;
  final ConnectionService _connectionService = Get.find<ConnectionService>();
  final UserRepository _userRepo = UserRepository.instance;

  // Interest emojis map
  final Map<String, String> interestEmojis = {
    'Coding': '💻',
    'Gaming': '🎮',
    'Music': '🎵',
    'Photography': '📸',
    'Travel': '✈️',
    'Reading': '📚',
    'Movies': '🎬',
    'Fitness': '🏃',
    'Art': '🎨',
    'Coffee': '☕',
    'Cooking': '🍳',
    'Pets': '🐕',
    'Theater': '🎭',
    'Sports': '⚽',
    'Yoga': '🧘',
    'Nature': '🌱',
    'Singing': '🎤',
    'Dancing': '💃',
    'Instruments': '🎸',
    'Board Games': '🎲',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _isLiked = widget.profile.likedBy.contains(_userRepo.currentUserId);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openChat() {
    Get.to(
      () => ChatDetailScreen(
        name: widget.profile.name,
        avatar: widget.profile.avatar,
        participantId: widget.profile.id,
      ),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _toggleLike() async {
    final targetId = widget.profile.id;
    await _userRepo.toggleProfileLike(targetId);

    setState(() {
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      Get.snackbar(
        'Liked! ✨',
        'You liked ${widget.profile.displayName}\'s profile!',
        backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
        icon: const Icon(Icons.favorite, color: Colors.white),
      );
    }
  }

  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NexoraColors.midnightPurple.withOpacity(0.98),
              NexoraColors.midnightDark.withOpacity(0.98),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.3),
            width: 1.w,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.share_outlined,
                label: 'Share Profile',
                color: NexoraColors.accentCyan,
                onTap: () {
                  Get.back();
                  Get.snackbar(
                    'Share',
                    'Profile link copied!',
                    backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.block_outlined,
                label: 'Block User',
                color: NexoraColors.warning,
                onTap: () {},
              ),
              _buildOptionTile(
                icon: Icons.report_outlined,
                label: 'Report Profile',
                color: NexoraColors.error,
                onTap: () {
                  Get.back();
                  _showReportDialog();
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color, size: 22.r),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: NexoraColors.textPrimary,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showReportDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          borderRadius: 24.r,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NexoraColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report,
                  color: NexoraColors.error,
                  size: 40.r,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Report Profile',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              ...[
                'Inappropriate content',
                'Fake profile',
                'Harassment',
                'Spam',
              ].map((reason) => _buildReportOption(reason)),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.snackbar(
          'Report Submitted',
          'Thank you for keeping Nexora safe',
          backgroundColor: NexoraColors.success.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: NexoraColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: NexoraColors.cardBorder, width: 1.w),
        ),
        child: Text(
          reason,
          style: TextStyle(color: NexoraColors.textPrimary, fontSize: 15.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background gradients
            Positioned(
              top: -100.h,
              right: -100.w,
              child: Container(
                width: 300.r,
                height: 300.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      NexoraColors.primaryOrange.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 150.h,
              left: -80.w,
              child: Container(
                width: 250.r,
                height: 250.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      NexoraColors.deepOrange.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // App Bar
                  _buildAppBar(),

                  // Scrollable content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            children: [
                              SizedBox(height: 20.h),

                              // Profile Header
                              _buildProfileHeader(),

                              SizedBox(height: 24.h),

                              // Bio Section
                              if (widget.profile.bio.isNotEmpty)
                                _buildBioSection(),

                              SizedBox(height: 20.h),

                              // Interests Section
                              _buildInterestsSection(),

                              SizedBox(height: 20.h),

                              // Looking For Section
                              if (widget.profile.lookingFor != null &&
                                  widget.profile.lookingFor!.isNotEmpty)
                                _buildLookingForSection(),

                              SizedBox(height: 20.h),

                              // Social Links
                              if (widget.profile.instagram != null)
                                _buildSocialLinks(),

                              SizedBox(
                                height: 120.h,
                              ), // Space for bottom buttons
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: NexoraColors.glassBorder, width: 1.w),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: NexoraColors.textPrimary,
                size: 18.r,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: NexoraColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: NexoraColors.glassBorder, width: 1.w),
              ),
              child: Icon(
                Icons.more_vert,
                color: NexoraColors.textPrimary,
                size: 18.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return StreamBuilder<ProfileModel?>(
      stream: _userRepo.getUserStream(widget.profile.id),
      initialData: widget.profile,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? widget.profile;

        return StreamBuilder<bool>(
          stream: _userRepo.getUserPresenceStream(widget.profile.id),
          initialData: profile.isOnline,
          builder: (context, presenceSnapshot) {
            final isOnline = presenceSnapshot.data ?? false;
            final status = _connectionService.getStatus(widget.profile.id);
            final isConnected = status == ConnectionStatus.connected;

            return Column(
              children: [
                if (isConnected)
                  // Artistic Overlapping Avatars Header
                  SizedBox(
                    height: 180.h,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow behind everything
                        Container(
                          width: 220.r,
                          height: 220.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                NexoraColors.primaryOrange.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // My Avatar (Background)
                        Positioned(
                          left: 60.w,
                          child: Transform.translate(
                            offset: Offset(-20.w, -10.h),
                            child: _buildOverlappingAvatar(
                              _userRepo.currentUser.avatar,
                              110.r,
                              Border.all(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.5,
                                ),
                                width: 2.w,
                              ),
                            ),
                          ),
                        ),
                        // Their Avatar (Foreground)
                        Positioned(
                          right: 60.w,
                          child: Transform.translate(
                            offset: Offset(20.w, 10.h),
                            child: _buildOverlappingAvatar(
                              profile.avatar,
                              130.r,
                              Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 3.w,
                              ),
                              showOnline: isOnline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Original Single Avatar with Glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 145.r,
                        height: 145.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: NexoraColors.primaryPurple.withOpacity(
                                0.4,
                              ),
                              blurRadius: 35.r,
                              spreadRadius: 8.r,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 130.r,
                        height: 130.r,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              NexoraColors.primaryPurple.withOpacity(0.3),
                              NexoraColors.romanticPink.withOpacity(0.2),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NexoraColors.primaryPurple.withOpacity(0.6),
                            width: 3.w,
                          ),
                        ),
                        child: ClipOval(
                          child: profile.avatar.startsWith('http')
                              ? Image.network(
                                  profile.avatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          profile.name.isNotEmpty
                                              ? profile.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 50.sp,
                                            color: NexoraColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                )
                              : Center(
                                  child: Text(
                                    profile.name.isNotEmpty
                                        ? profile.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 50.sp,
                                      color: NexoraColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 8.h,
                          right: 8.w,
                          child: Container(
                            width: 24.r,
                            height: 24.r,
                            decoration: BoxDecoration(
                              color: NexoraColors.online,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: NexoraColors.midnightDark,
                                width: 3.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: NexoraColors.online.withOpacity(0.5),
                                  blurRadius: 8.r,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                SizedBox(height: 20.h),

                // Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.displayName,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: NexoraColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        gradient: NexoraGradients.cyanAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 12.r),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Major
                if (profile.major.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          NexoraColors.primaryPurple.withOpacity(0.2),
                          NexoraColors.romanticPink.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: NexoraColors.primaryPurple.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      profile.major,
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                SizedBox(height: 24.h),

                // Stats Section
                GlassContainer(
                  borderRadius: 24.r,
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Likes',
                        '${profile.profileLikes}',
                        NexoraColors.romanticPink,
                        Icons.favorite,
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        'Connections',
                        '${profile.connections}',
                        NexoraColors.accentCyan,
                        Icons.people,
                      ),
                    ],
                  ),
                ),

                // Online status
                if (isOnline)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            color: NexoraColors.online,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Online now',
                          style: TextStyle(
                            color: NexoraColors.online,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About', Icons.person_outline),
        SizedBox(height: 12.h),
        GlassContainer(
          borderRadius: 20.r,
          padding: EdgeInsets.all(16.w),
          child: Text(
            widget.profile.bio,
            style: TextStyle(
              color: NexoraColors.textPrimary,
              fontSize: 15.sp,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Interests', Icons.favorite_outline),
        SizedBox(height: 12.h),
        if (widget.profile.interests.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'No interests added yet',
                style: TextStyle(
                  color: NexoraColors.textMuted,
                  fontSize: 13.sp,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: widget.profile.interests.map((interest) {
              final emoji = interestEmojis[interest] ?? '✨';
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: NexoraGradients.glassyGradient,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: NexoraColors.primaryPurple.withOpacity(0.15),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 6.w),
                    Text(
                      interest,
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildLookingForSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Looking For', Icons.search_outlined),
        SizedBox(height: 12.h),
        GlassContainer(
          borderRadius: 20.r,
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: NexoraGradients.glassyGradient,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: NexoraColors.primaryPurple.withOpacity(0.1),
                    width: 1.w,
                  ),
                ),
                child: Icon(Icons.favorite, color: Colors.white, size: 20.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  widget.profile.lookingFor!,
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Socials', Icons.link),
        SizedBox(height: 12.h),
        GlassContainer(
          borderRadius: 20.r,
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              if (widget.profile.instagram != null &&
                  widget.profile.instagram!.isNotEmpty)
                _buildSocialRow(
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  value: '@${widget.profile.instagram}',
                  color: const Color(0xFFE4405F),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 20.r),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 12.sp),
            ),
            Text(
              value,
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: NexoraColors.primaryPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: NexoraColors.primaryPurple, size: 18.r),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            color: NexoraColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            NexoraColors.midnightDark.withOpacity(0.8),
            NexoraColors.midnightDark,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Like and Connect
            Row(
              children: [
                // Like Button
                GestureDetector(
                  onTap: _toggleLike,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 200),
                    tween: Tween(begin: 1.0, end: 1.0),
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56.r,
                        height: 56.r,
                        decoration: BoxDecoration(
                          gradient: _isLiked
                              ? NexoraGradients.glassyGradient
                              : null,
                          color: _isLiked ? null : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(18.r),
                          border: Border.all(
                            color: _isLiked
                                ? NexoraColors.primaryPurple.withOpacity(0.3)
                                : NexoraColors.primaryPurple.withOpacity(0.1),
                            width: 1.5.w,
                          ),
                          boxShadow: [
                            if (_isLiked)
                              BoxShadow(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 10.r,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked
                                ? Colors.white
                                : NexoraColors.primaryOrange,
                            size: 26.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Connect Button
                Expanded(child: _buildConnectionButton()),
              ],
            ),

            SizedBox(height: 12.h),

            // Row 2: Message Button
            GestureDetector(
              onTap: _openChat,
              child: Container(
                height: 56.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: NexoraGradients.glassyGradient,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: NexoraColors.primaryPurple.withOpacity(0.2),
                    width: 1.w,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 20.r,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Talk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton() {
    return Obx(() {
      final status = _connectionService.getStatus(widget.profile.id);

      IconData icon;
      String label;
      Color bgColor;
      Color borderColor;
      Color contentColor;
      VoidCallback? onTap;

      switch (status) {
        case ConnectionStatus.connected:
          icon = Icons.check_circle_rounded;
          label = 'Connected';
          bgColor = NexoraColors.success;
          borderColor = NexoraColors.success;
          contentColor = NexoraColors.success;
          onTap = () {
            _showDisconnectDialog();
          };
          break;
        case ConnectionStatus.pending:
          icon = Icons.schedule_rounded;
          label = 'Pending';
          bgColor = NexoraColors.textMuted;
          borderColor = NexoraColors.textMuted;
          contentColor = NexoraColors.textSecondary;
          onTap = () {
            _connectionService.cancelRequest(widget.profile.id);
            Get.snackbar(
              'Request Cancelled',
              'Connection request to ${widget.profile.displayName} cancelled',
              backgroundColor: NexoraColors.glassBackground,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: EdgeInsets.all(16.w),
              borderRadius: 12.r,
            );
          };
          break;
        case ConnectionStatus.incoming:
          icon = Icons.person_add_alt_1_rounded;
          label = 'Accept';
          bgColor = NexoraColors.success;
          borderColor = NexoraColors.success;
          contentColor = NexoraColors.success;
          onTap = () {
            _connectionService.acceptRequest(widget.profile.id);
            Get.snackbar(
              'Connected!',
              'You are now connected with ${widget.profile.displayName}',
              backgroundColor: NexoraColors.success.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
              margin: EdgeInsets.all(16.w),
              borderRadius: 12.r,
            );
          };
          break;
        default: // ConnectionStatus.none
          icon = Icons.person_add_rounded;
          label = 'Connect';
          bgColor = NexoraColors.accentCyan;
          borderColor = NexoraColors.accentCyan;
          contentColor = Colors.white;
          onTap = () {
            _connectionService.sendRequest(
              userId: widget.profile.id,
              name: widget.profile.displayName,
              avatar: widget.profile.avatar,
              major: widget.profile.major,
              year: widget.profile.year,
            );

            // Also trigger a profile like (engagement benefit)
            _toggleLike();

            Get.snackbar(
              'Request Sent!',
              'Connection request sent to ${widget.profile.displayName}',
              backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
              margin: EdgeInsets.all(16.w),
              borderRadius: 12.r,
            );
          };
      }

      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56.h,
            decoration: BoxDecoration(
              color: status == ConnectionStatus.none
                  ? null
                  : bgColor.withOpacity(0.12),
              gradient: status == ConnectionStatus.none
                  ? NexoraGradients.glassyGradient
                  : null,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: borderColor.withOpacity(0.5),
                width: 1.w,
              ),
              boxShadow: [
                if (status == ConnectionStatus.none)
                  BoxShadow(
                    color: NexoraColors.primaryOrange.withOpacity(0.35),
                    blurRadius: 15.r,
                    offset: Offset(0, 8.h),
                  ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: status == ConnectionStatus.none
                        ? Colors.white
                        : contentColor,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: status == ConnectionStatus.none
                          ? Colors.white
                          : contentColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showDisconnectDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: NexoraColors.midnightDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text(
          'Remove Connection',
          style: TextStyle(color: NexoraColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${widget.profile.name} from your connections?',
          style: const TextStyle(color: NexoraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: NexoraColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              _connectionService.removeConnection(widget.profile.id);
              Get.back();
              Get.snackbar(
                'Connection Removed',
                '${widget.profile.name} has been removed from your connections',
                backgroundColor: NexoraColors.glassBackground,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 2),
                margin: EdgeInsets.all(16.w),
                borderRadius: 12.r,
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: NexoraColors.romanticPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingAvatar(
    String url,
    double size,
    BoxBorder border, {
    bool showOnline = false,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: ClipOval(
            child: url.startsWith('http')
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: NexoraColors.primaryPurple,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: size * 0.5,
                      ),
                    ),
                  )
                : Container(
                    color: NexoraColors.primaryPurple,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: size * 0.5,
                    ),
                  ),
          ),
        ),
        if (showOnline)
          Positioned(
            bottom: 5.h,
            right: 5.w,
            child: Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                color: NexoraColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NexoraColors.midnightDark,
                  width: 2.w,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14.r),
            SizedBox(width: 4.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: NexoraColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: NexoraColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30.h,
      width: 1.w,
      color: Colors.white.withOpacity(0.1),
    );
  }
}
