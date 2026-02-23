import 'package:get/get.dart';
import '../../../core/services/dummy_database.dart';

/// NotificationRepository - Handles all notification operations
/// Abstracts DummyDatabase access for notification-related data
class NotificationRepository {
  final DummyDatabase _db = DummyDatabase.instance;

  /// Get all notifications
  List<NotificationData> getAllNotifications() {
    return _db.notifications.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get notifications as observable
  RxList<NotificationData> get notificationsRx => _db.notifications;

  /// Get unread notifications
  List<NotificationData> getUnreadNotifications() {
    return _db.notifications.where((n) => !n.isRead).toList();
  }

  /// Get unread count
  int getUnreadCount() => _db.getUnreadNotificationsCount();

  /// Get notifications by type
  List<NotificationData> getNotificationsByType(NotificationType type) {
    return _db.notifications.where((n) => n.type == type).toList();
  }

  /// Get activity notifications (likes, comments, follows)
  List<NotificationData> getActivityNotifications() {
    return _db.notifications.where((n) =>
        n.type == NotificationType.like ||
        n.type == NotificationType.comment ||
        n.type == NotificationType.follow).toList();
  }

  /// Get mention notifications
  List<NotificationData> getMentionNotifications() {
    return _db.notifications.where((n) => n.type == NotificationType.mention).toList();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    _db.markNotificationAsRead(notificationId);
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _db.markAllNotificationsAsRead();
  }

  /// Get user who triggered the notification
  UserData? getNotificationUser(String userId) {
    return _db.getUserById(userId);
  }

  /// Add new notification
  void addNotification({
    required NotificationType type,
    required String userId,
    required String message,
  }) {
    _db.notifications.add(NotificationData(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      userId: userId,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
    ));
  }
}
