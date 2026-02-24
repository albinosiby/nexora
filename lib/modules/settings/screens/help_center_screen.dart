import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Help Center', style: NexoraTextStyles.headline2),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: NexoraColors.textPrimary,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildFAQItem(
                  'How do I change my profile picture?',
                  'Go to Settings > Edit Profile to update your avatar.',
                ),
                _buildFAQItem(
                  'How do I match with someone?',
                  'Use the Discover screen and swipe right on profiles you like.',
                ),
                _buildFAQItem(
                  'What are feed notifications?',
                  'These are alerts for new posts and activities in your social feed.',
                ),
                _buildFAQItem(
                  'How do I report a user?',
                  'You can report an individual from their profile page under more options.',
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GlassContainer(
        borderRadius: 16.r,
        padding: EdgeInsets.all(16.w),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              question,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: NexoraColors.textPrimary,
              ),
            ),
            iconColor: NexoraColors.primaryPurple,
            collapsedIconColor: NexoraColors.textMuted,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: NexoraColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
