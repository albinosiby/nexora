import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';
import '../../connections/repositories/connection_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../connections/screens/connections_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _messageNotifications = true;
  bool _eventNotifications = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Settings', style: NexoraTextStyles.headline2),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: NexoraColors.textPrimary,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Section with Grid
                _buildSectionHeader('Account', Icons.person_outline),
                SizedBox(height: 12.h),
                _buildAccountGrid(),
                SizedBox(height: 24.h),

                // Notifications Section with Modern Switches
                _buildSectionHeader(
                  'Notifications',
                  Icons.notifications_outlined,
                ),
                SizedBox(height: 12.h),
                _buildNotificationCards(),
                SizedBox(height: 24.h),

                // Support & Info Section
                _buildSectionHeader('Support', Icons.help_outline),
                SizedBox(height: 12.h),
                _buildSupportGrid(),
                SizedBox(height: 24.h),

                // Danger Zone with Alert Style
                _buildDangerZone(),
                SizedBox(height: 32.h),

                // App version with branding
                _buildAppVersion(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NexoraColors.primaryPurple.withOpacity(0.3),
                  NexoraColors.deepPurple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: NexoraColors.primaryPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: NexoraColors.primaryPurple, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: NexoraColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.4,
      children: [
        _buildAccountGridItem(
          icon: Icons.person,
          title: 'Edit Profile',
          subtitle: 'Personal info',
          color: NexoraColors.primaryPurple,
          onTap: () {},
        ),
        _buildAccountGridItem(
          icon: Icons.people,
          title: 'Connections',
          subtitle: 'Manage friends',
          color: NexoraColors.romanticPink,
          onTap: () => Get.to(() => const ConnectionsScreen()),
        ),
      ],
    );
  }

  Widget _buildAccountGridItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 16.r,
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: NexoraColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCards() {
    return Column(
      children: [
        _buildNotificationCard(
          icon: Icons.notifications,
          title: 'Push Notifications',
          description: 'Receive push alerts',
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
          color: NexoraColors.primaryPurple,
        ),
        SizedBox(height: 8.h),
        _buildNotificationCard(
          icon: Icons.message,
          title: 'Message Notifications',
          description: 'New message alerts',
          value: _messageNotifications,
          onChanged: (value) => setState(() => _messageNotifications = value),
          color: NexoraColors.romanticPink,
        ),
        SizedBox(height: 8.h),
        _buildNotificationCard(
          icon: Icons.event,
          title: 'Event Notifications',
          description: 'Campus event updates',
          value: _eventNotifications,
          onChanged: (value) => setState(() => _eventNotifications = value),
          color: NexoraColors.success,
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return GlassContainer(
      borderRadius: 16.r,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: NexoraColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.2,
      children: [
        _buildSupportItem(
          icon: Icons.help,
          title: 'Help Center',
          subtitle: 'Get assistance',
          color: NexoraColors.primaryPurple,
          onTap: () {},
        ),
        _buildSupportItem(
          icon: Icons.feedback,
          title: 'Feedback',
          subtitle: 'Share thoughts',
          color: NexoraColors.romanticPink,
          onTap: () {},
        ),
        _buildSupportItem(
          icon: Icons.description,
          title: 'Terms',
          subtitle: 'Service terms',
          color: NexoraColors.success,
          onTap: () {},
        ),
        _buildSupportItem(
          icon: Icons.privacy_tip,
          title: 'Privacy',
          subtitle: 'Data policy',
          color: NexoraColors.warning,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 16.r,
        padding: EdgeInsets.all(12.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: NexoraColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10.sp, color: NexoraColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Danger Zone', Icons.warning_amber_outlined),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              _buildDangerAction(
                icon: Icons.logout,
                title: 'Logout',
                description: 'Sign out from your account',
                color: NexoraColors.warning,
                onTap: _logout,
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerAction({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: isDestructive
              ? Border.all(color: color.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? color : NexoraColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: NexoraColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.7),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    return Center(
      child: Column(
        children: [
          Text(
            'NEXORA',
            style: NexoraTextStyles.logoStyle.copyWith(fontSize: 18.sp),
          ),

          SizedBox(height: 8.h),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: NexoraColors.textMuted, fontSize: 11.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            'Where Campus Hearts Connect',
            style: TextStyle(
              color: NexoraColors.textMuted.withOpacity(0.7),
              fontSize: 9.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          borderRadius: 24.r,
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: NexoraColors.warning.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: NexoraColors.warning,
                  size: 40,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: NexoraColors.textSecondary,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: NexoraColors.textMuted,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.warning,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);
                        Get.offAll(() => const LoginScreen());
                      },
                      child: Text('Logout', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
