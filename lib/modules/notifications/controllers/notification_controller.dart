import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository = NotificationRepository();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription? _notificationSub;
  StreamSubscription? _authSub;

  @override
  void onInit() {
    super.onInit();
    _authSub = AuthRepository.instance.userRx.listen((user) {
      if (user != null) {
        _bindNotifications();
      } else {
        _cleanup();
      }
    });

    if (AuthRepository.instance.user != null) {
      _bindNotifications();
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _cleanup();
    super.onClose();
  }

  void _cleanup() {
    _notificationSub?.cancel();
    _notificationSub = null;
    notifications.clear();
    isLoading.value = false;
  }

  void _bindNotifications() {
    _cleanup();
    bool isInitialLoad = true;

    _notificationSub = _repository.getNotificationsStream().listen((list) {
      if (isInitialLoad) {
        notifications.assignAll(list);
        isInitialLoad = false;
        if (isLoading.value) isLoading.value = false;
        return;
      }

      // Check for new notifications
      if (list.isNotEmpty) {
        final latest = list.first;
        // If the list was empty before OR the latest notification is different and unread
        if (notifications.isEmpty ||
            (latest.id != notifications.first.id && !latest.isRead)) {
          _showNotificationSnackbar(latest);
        }
      }

      notifications.assignAll(list);
    });

    // Timeout loading if no data
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading.value) isLoading.value = false;
    });
  }

  void _showNotificationSnackbar(NotificationModel notification) {
    Get.snackbar(
      notification.userName ?? 'Nexora',
      notification.message,
      backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      icon: Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: Container(
          width: 40.r,
          height: 40.r,
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child:
                notification.userAvatar != null &&
                    notification.userAvatar!.isNotEmpty
                ? Image.network(
                    notification.userAvatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.notifications, color: Colors.white),
                  )
                : const Icon(Icons.notifications, color: Colors.white),
          ),
        ),
      ),
      onTap: (_) {
        // Navigate to notifications screen or handle tap
      },
    );
  }

  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  List<NotificationModel> get mentionNotifications =>
      notifications.where((n) => n.type == NotificationType.mention).toList();

  List<NotificationModel> get activityNotifications => notifications
      .where(
        (n) =>
            n.type == NotificationType.like ||
            n.type == NotificationType.comment ||
            n.type == NotificationType.follow ||
            n.type == NotificationType.profileLike,
      )
      .toList();

  void markAsRead(String id) {
    _repository.markAsRead(id);
  }

  void markAllAsRead() {
    _repository.markAllAsRead();
  }
}
