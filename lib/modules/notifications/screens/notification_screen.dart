import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../connections/repositories/connection_service.dart';
import '../../connections/screens/connections_screen.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationController _controller = Get.put(NotificationController());
  final ConnectionService _connectionService = Get.find<ConnectionService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return {'icon': Icons.favorite, 'color': NexoraColors.romanticPink};
      case NotificationType.comment:
        return {'icon': Icons.comment, 'color': NexoraColors.accentCyan};
      case NotificationType.follow:
        return {'icon': Icons.person_add, 'color': NexoraColors.primaryPurple};
      case NotificationType.match:
        return {
          'icon': Icons.favorite_border,
          'color': NexoraColors.romanticPink,
        };
      case NotificationType.feed:
        return {'icon': Icons.rss_feed, 'color': NexoraColors.brightPurple};
      case NotificationType.mention:
        return {
          'icon': Icons.alternate_email,
          'color': NexoraColors.accentCyan,
        };
      case NotificationType.connectionRequest:
        return {
          'icon': Icons.person_add_alt_1,
          'color': NexoraColors.primaryPurple,
        };
      case NotificationType.message:
        return {'icon': Icons.chat_bubble, 'color': NexoraColors.accentCyan};
      case NotificationType.profileLike:
        return {'icon': Icons.favorite, 'color': NexoraColors.romanticPink};
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: NexoraTextStyles.headline2),
        actions: [
          Obx(
            () => _controller.unreadCount > 0
                ? TextButton(
                    onPressed: _controller.markAllAsRead,
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        color: NexoraColors.primaryPurple,
                        fontSize: 12.sp,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Connection Requests Banner
            _buildConnectionRequestsBanner(),

            // Tab bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 45.h,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.r),
                    gradient: NexoraGradients.primaryButton,
                  ),
                  labelColor: NexoraColors.textPrimary,
                  unselectedLabelColor: NexoraColors.textMuted,
                  labelStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('All'),
                          Obx(
                            () => _controller.unreadCount > 0
                                ? Padding(
                                    padding: EdgeInsets.only(left: 6.w),
                                    child: Container(
                                      padding: EdgeInsets.all(4.r),
                                      decoration: const BoxDecoration(
                                        color: NexoraColors.romanticPink,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${_controller.unreadCount}',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: NexoraColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const Tab(text: 'Mentions'),
                    const Tab(text: 'Activity'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Notification list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Obx(() => _buildNotificationList(_controller.notifications)),
                  Obx(
                    () => _buildNotificationList(
                      _controller.mentionNotifications,
                    ),
                  ),
                  Obx(
                    () => _buildNotificationList(
                      _controller.activityNotifications,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> items) {
    if (_controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: NexoraColors.primaryPurple),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64.r,
              color: NexoraColors.textMuted.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'No notifications yet',
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notification = items[index];
        return _buildNotificationItem(notification, index);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    final config = _getNotificationConfig(notification.type);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(30.w * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: GlassContainer(
                borderRadius: 20.r,
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: (config['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        config['icon'],
                        color: config['color'],
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: notification.userName ?? 'User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: NexoraColors.textPrimary,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${notification.message}',
                                  style: TextStyle(
                                    color: NexoraColors.textSecondary,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _formatTime(notification.timestamp),
                            style: TextStyle(
                              color: NexoraColors.textMuted,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unread indicator
                    if (!notification.isRead)
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: const BoxDecoration(
                          color: NexoraColors.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionRequestsBanner() {
    return Obx(() {
      final requests = _connectionService.incomingRequests;

      if (requests.isEmpty) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () => Get.to(
          () => const ConnectionsScreen(),
          transition: Transition.rightToLeftWithFade,
        ),
        child: Container(
          margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NexoraColors.primaryPurple.withOpacity(0.3),
                NexoraColors.romanticPink.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: NexoraColors.primaryPurple.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      color: NexoraColors.primaryPurple,
                      size: 24.r,
                    ),
                    Positioned(
                      right: -2.w,
                      top: -2.h,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: const BoxDecoration(
                          color: NexoraColors.romanticPink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${requests.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Requests',
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      requests.length == 1
                          ? '${requests.first.name} wants to connect'
                          : '${requests.first.name} and ${requests.length - 1} others want to connect',
                      style: TextStyle(
                        color: NexoraColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: NexoraColors.textMuted,
              ),
            ],
          ),
        ),
      );
    });
  }
}
