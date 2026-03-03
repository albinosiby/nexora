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
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Artistic Animated Background
          _buildBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 40.h),

                // Overlapping Avatars Section
                _buildOverlappingAvatars(),

                const Spacer(),

                // Text Content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      children: [
                        Text(
                          'Let\'s ask about her hobbies and something interesting or you must say "Hello" for personal meet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: NexoraColors.textPrimary.withOpacity(0.8),
                            fontSize: 16.sp,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 40.h),

                        // Action Button
                        _buildActionBtn(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 60.h),
              ],
            ),
          ),

          // Close Button
          Positioned(
            top: 20.h,
            right: 20.w,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 28.r,
              ),
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
                const Color(0xFFFFF1F1), // Soft highlight
                const Color(0xFFFFB7B7), // Peach pink
                NexoraColors.romanticPink.withOpacity(0.5),
              ],
              stops: [0.0, 0.3 + (0.2 * _bgController.value), 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlappingAvatars() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: SizedBox(
          height: 450.h,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Top Left Avatar (My Avatar)
              Positioned(
                top: 20.h,
                left: 30.w,
                child: _buildArtisticAvatar(widget.myAvatar, 180.r),
              ),

              // Bottom Right Avatar (Other User)
              Positioned(
                bottom: 20.h,
                right: 30.w,
                child: _buildArtisticAvatar(widget.otherUserAvatar, 200.r),
              ),

              // Names Overlay
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNameText(widget.myName, Colors.white),
                      SizedBox(height: 10.h),
                      _buildNameText('&', Colors.black87),
                      SizedBox(height: 10.h),
                      _buildNameText(widget.otherUserName, Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtisticAvatar(String url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: NexoraColors.primaryPurple,
            child: Icon(Icons.person, color: Colors.white, size: size * 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNameText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 56.sp,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -1,
        shadows: [
          if (color == Colors.white)
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
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
        height: 64.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9A9E), Color(0xFFF6416C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF6416C).withOpacity(0.4),
              blurRadius: 15.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Say "Hello!"',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
