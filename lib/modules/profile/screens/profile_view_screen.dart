import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';
import '../../connections/repositories/connection_service.dart';
import '../../chat/screens/chat_detail_screen.dart';
import '../models/profile_model.dart';

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

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      Get.snackbar(
        'Liked! 💜',
        'You liked ${widget.profile.name}\'s profile',
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
                      NexoraColors.primaryPurple.withOpacity(0.2),
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
                      NexoraColors.romanticPink.withOpacity(0.12),
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

                              // Spotify Anthem Section
                              _buildSpotifySection(),

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
                              if (widget.profile.instagram != null ||
                                  widget.profile.spotify != null)
                                _buildSocialLinks(),

                              SizedBox(
                                height: 100.h,
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
    return Column(
      children: [
        // Avatar with online indicator
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 145.r,
              height: 145.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NexoraColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 35.r,
                    spreadRadius: 8.r,
                  ),
                ],
              ),
            ),
            // Avatar
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
                child: widget.profile.avatar.startsWith('http')
                    ? Image.network(
                        widget.profile.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            widget.profile.name.isNotEmpty
                                ? widget.profile.name[0].toUpperCase()
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
                          widget.profile.name.isNotEmpty
                              ? widget.profile.name[0].toUpperCase()
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
            // Online indicator
            if (widget.profile.isOnline)
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
              widget.profile.displayName,
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

        // Year & Major
        if (widget.profile.year.isNotEmpty || widget.profile.major.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
              [
                widget.profile.year,
                widget.profile.major,
              ].where((s) => s.isNotEmpty).join(' • '),
              style: TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Online status
        if (widget.profile.isOnline)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
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

  Widget _buildSpotifySection() {
    final trackName = (widget.profile.spotifyTrackName ?? '').isNotEmpty
        ? widget.profile.spotifyTrackName!
        : 'No track set';
    final artist = (widget.profile.spotifyArtist ?? '').isNotEmpty
        ? widget.profile.spotifyArtist!
        : 'Add your anthem';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('On Repeat', Icons.music_note_rounded),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1DB954).withOpacity(0.15),
                NexoraColors.glassBackground,
                NexoraColors.primaryPurple.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF1DB954).withOpacity(0.2),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1DB954).withOpacity(0.1),
                blurRadius: 20.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Stack(
              children: [
                // Background blur effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                          Colors.white.withOpacity(0.03),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(14.r),
                  child: Row(
                    children: [
                      // Album art with glass frame
                      Container(
                        padding: EdgeInsets.all(3.r),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 52.r,
                              height: 52.r,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11.r),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1DB954),
                                        Color(0xFF169C46),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white,
                                    size: 24.r,
                                  ),
                                ),
                              ),
                            ),
                            // Frosted play button
                            Container(
                              width: 26.r,
                              height: 26.r,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5.w,
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 16.r,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 14.w),
                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trackName,
                              style: TextStyle(
                                color: NexoraColors.textPrimary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  width: 14.r,
                                  height: 14.r,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1DB954),
                                    borderRadius: BorderRadius.circular(3.r),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 10.r,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    artist,
                                    style: TextStyle(
                                      color: NexoraColors.textMuted,
                                      fontSize: 13.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Animated bars indicator
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMusicBar(8.h),
                            SizedBox(width: 2.w),
                            _buildMusicBar(14.h),
                            SizedBox(width: 2.w),
                            _buildMusicBar(10.h),
                            SizedBox(width: 2.w),
                            _buildMusicBar(16.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicBar(double height) {
    return Container(
      width: 3.w,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954),
        borderRadius: BorderRadius.circular(2.r),
      ),
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
                  gradient: LinearGradient(
                    colors: [
                      NexoraColors.glassBackground,
                      NexoraColors.primaryPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: NexoraColors.glassBorder,
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
                  gradient: NexoraGradients.romanticGlow,
                  borderRadius: BorderRadius.circular(12.r),
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
              if (widget.profile.instagram != null &&
                  widget.profile.instagram!.isNotEmpty &&
                  widget.profile.spotify != null &&
                  widget.profile.spotify!.isNotEmpty)
                SizedBox(height: 12.h),
              if (widget.profile.spotify != null &&
                  widget.profile.spotify!.isNotEmpty)
                _buildSocialRow(
                  icon: Icons.music_note,
                  label: 'Spotify',
                  value: widget.profile.spotify!,
                  color: const Color(0xFF1DB954),
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
        child: Row(
          children: [
            // Like Button - Redesigned
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
                      gradient: _isLiked ? NexoraGradients.romanticGlow : null,
                      color: _isLiked ? null : NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: _isLiked
                            ? Colors.white.withOpacity(0.2)
                            : NexoraColors.romanticPink.withOpacity(0.3),
                        width: 1.5.w,
                      ),
                      boxShadow: [
                        if (_isLiked)
                          BoxShadow(
                            color: NexoraColors.romanticPink.withOpacity(0.4),
                            blurRadius: 20.r,
                            spreadRadius: 2.r,
                          ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked
                            ? Colors.white
                            : NexoraColors.romanticPink,
                        size: 26.r,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Connect Button
            _buildConnectionButton(),

            SizedBox(width: 12.w),

            // Message Button - Redesigned
            Expanded(
              child: GestureDetector(
                onTap: _openChat,
                child: Container(
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NexoraColors.primaryPurple,
                        NexoraColors.primaryPurple.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.primaryPurple.withOpacity(0.4),
                        blurRadius: 15.r,
                        offset: Offset(0, 8.h),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 8.r,
                        offset: Offset(-2.w, -2.h),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Glossy overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18.r),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),
                      ),
                      Center(
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
                              'Message',
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
              duration: const Duration(seconds: 2),
              margin: EdgeInsets.all(16.w),
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
          bgColor = NexoraColors.accentCyan;
          borderColor = NexoraColors.accentCyan;
          contentColor = NexoraColors.accentCyan;
          onTap = () {
            _connectionService.sendRequest(
              userId: widget.profile.id,
              name: widget.profile.displayName,
              avatar: widget.profile.avatar,
              major: widget.profile.major,
              year: widget.profile.year,
            );
            Get.snackbar(
              'Connection Request Sent',
              'You sent a connection request to ${widget.profile.displayName}',
              backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: EdgeInsets.all(16.w),
              borderRadius: 12.r,
              icon: Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                ),
              ),
            );
          };
      }

      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: borderColor.withOpacity(0.2),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: contentColor, size: 20.r),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: contentColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
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
}
