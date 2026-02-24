import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository = NotificationRepository();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _bindNotifications();
  }

  void _bindNotifications() {
    notifications.bindStream(_repository.getNotificationsStream());

    // Set loading to false once we have data or stream starts
    ever(notifications, (_) {
      if (isLoading.value) isLoading.value = false;
    });

    // Timeout loading if no data
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading.value) isLoading.value = false;
    });
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
