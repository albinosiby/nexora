import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../chat/screens/chat_detail_screen.dart';

class MatchSuccessScreen extends StatefulWidget {
  final String otherUserName;
  final String otherUserAvatar;
  final String myName;
  final String myAvatar;
  final String otherUserId;

  const MatchSuccessScreen({
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.myName,
    required this.myAvatar,
    required this.otherUserId,
    super.key,
  });

  @override
  State<MatchSuccessScreen> createState() => _MatchSuccessScreenState();
}

class _MatchSuccessScreenState extends State<MatchSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          _buildBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(12.r),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                // Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        "🎉 It's a Match!",
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8.r,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'You and ${widget.otherUserName} connected!',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // Avatars side-by-side
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildAvatarRow(),
                ),

                const Spacer(),

                // Bottom content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            'Start a conversation — ask about hobbies or just say "Hello!" 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14.sp,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        _buildActionBtn(),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Text(
                            'Maybe later',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0800),
                NexoraColors.primaryOrange.withOpacity(
                  0.25 + (0.12 * _bgController.value),
                ),
                NexoraColors.midnightDark,
              ],
              stops: [0.0, 0.45 + (0.1 * _bgController.value), 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // My Avatar
          _buildAvatarCard(widget.myAvatar, widget.myName, isLeft: true),

          // Center Heart / &
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    gradient: NexoraGradients.primaryButton,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.primaryOrange.withOpacity(0.5),
                        blurRadius: 16.r,
                        spreadRadius: 2.r,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text('❤️', style: TextStyle(fontSize: 22.sp)),
                  ),
                ),
              );
            },
          ),

          // Other Avatar
          _buildAvatarCard(
            widget.otherUserAvatar,
            widget.otherUserName,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(String url, String name, {required bool isLeft}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 140.r,
            width: 140.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: NexoraGradients.primaryButton,
              border: Border.all(
                color: NexoraColors.primaryOrange.withOpacity(0.6),
                width: 3.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: NexoraColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 20.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(Icons.person, color: Colors.white, size: 60.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
              letterSpacing: 0.3,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 4.r),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn() {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.to(
          () => ChatDetailScreen(
            name: widget.otherUserName,
            avatar: widget.otherUserAvatar,
            participantId: widget.otherUserId,
          ),
          transition: Transition.rightToLeftWithFade,
        );
      },
      child: Container(
        width: double.infinity,
        height: 58.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          gradient: NexoraGradients.primaryButton,
          boxShadow: [
            BoxShadow(
              color: NexoraColors.primaryOrange.withOpacity(0.45),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Say "Hello!" 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
