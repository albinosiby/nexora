import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Privacy Policy', style: NexoraTextStyles.headline2),
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
                _buildUpdateCard(),
                SizedBox(height: 24.h),
                _buildPolicySection(
                  'Information Collection',
                  'We collect information you provide directly to us when you create an account, update your profile, and use the interactive features of Nexora. This includes your name, email, profile photos, and campus affiliation.',
                ),
                _buildPolicySection(
                  'How We Use Your Data',
                  'Your information is used to personalize your experience, facilitate connections between students, and improve our services. We do not sell your personal data to third parties.',
                ),
                _buildPolicySection(
                  'Data Security',
                  'We use industry-standard security measures to protect your personal information from unauthorized access, disclosure, or destruction.',
                ),
                _buildPolicySection(
                  'Your Choices',
                  'You can update your account information at any time through the profile settings. You may also request to delete your account and associated data.',
                ),
                SizedBox(height: 20.h),
                Text(
                  'Last updated: February 2026',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: NexoraColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard() {
    return GlassContainer(
      borderRadius: 16.r,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(Icons.security, color: NexoraColors.accentCyan, size: 32.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                Text(
                  'Learn how we handle your data.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: NexoraColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: NexoraColors.primaryPurple,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: NexoraColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
