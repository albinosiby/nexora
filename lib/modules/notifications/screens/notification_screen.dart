import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/dummy_database.dart';
import '../../connections/repositories/connection_service.dart';
import '../../connections/screens/connections_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DummyDatabase _db = DummyDatabase.instance;

  List<Map<String, dynamic>> get notifications {
    return _db.notifications.map((notif) {
      final user = _db.getUserById(notif.userId);
      final notifConfig = _getNotificationConfig(notif.type);

      return {
        'id': notif.id,
        'type': notif.type.name,
        'user': user?.displayName ?? 'system',
        'message': notif.message,
        'time': _formatTime(notif.timestamp),
        'read': notif.isRead,
        'icon': notifConfig['icon'],
        'color': notifConfig['color'],
        'avatar': user?.avatar,
      };
    }).toList();
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
      case NotificationType.event:
        return {'icon': Icons.event, 'color': NexoraColors.brightPurple};
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

  List<Map<String, dynamic>> get unreadNotifications =>
      notifications.where((n) => n['read'] == false).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: NexoraTextStyles.headline2),
        actions: [
          if (unreadNotifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: NexoraColors.primaryPurple,
                  fontSize: 12,
                ),
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: NexoraGradients.primaryButton,
                  ),
                  labelColor: NexoraColors.textPrimary,
                  unselectedLabelColor: NexoraColors.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('All'),
                          if (unreadNotifications.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: NexoraColors.romanticPink,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${unreadNotifications.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: NexoraColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
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
                  _buildNotificationList(notifications),
                  _buildNotificationList(
                    notifications.where((n) => n['type'] == 'mention').toList(),
                  ),
                  _buildNotificationList(
                    notifications
                        .where(
                          (n) =>
                              n['type'] == 'like' ||
                              n['type'] == 'comment' ||
                              n['type'] == 'follow',
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: NexoraColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notification = items[index];
        return _buildNotificationItem(notification, index);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: Key(notification['id'] as String),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: NexoraColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete, color: NexoraColors.error),
                ),
                onDismissed: (_) {
                  setState(() {
                    notifications.remove(notification);
                  });
                },
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (notification['color'] as Color).withOpacity(
                            0.2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          notification['icon'],
                          color: notification['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: notification['user'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: NexoraColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${notification['message']}',
                                    style: TextStyle(
                                      color: NexoraColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification['time'],
                              style: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Unread indicator
                      if (notification['read'] == false)
                        Container(
                          width: 10,
                          height: 10,
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
          ),
        );
      },
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['read'] = true;
      }
    });
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
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NexoraColors.primaryPurple.withOpacity(0.3),
                NexoraColors.romanticPink.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NexoraColors.primaryPurple.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.person_add_rounded,
                      color: NexoraColors.primaryPurple,
                      size: 24,
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: NexoraColors.romanticPink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${requests.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Requests',
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      requests.length == 1
                          ? '${requests.first.name} wants to connect'
                          : '${requests.first.name} and ${requests.length - 1} others want to connect',
                      style: const TextStyle(
                        color: NexoraColors.textSecondary,
                        fontSize: 12,
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
