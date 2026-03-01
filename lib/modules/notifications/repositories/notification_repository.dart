import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/notification_model.dart';

/// NotificationRepository - Handles all notification operations
/// Uses Firestore for real-time data
class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _auth = AuthRepository.instance;

  String? get _uid => _auth.user?.uid;

  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    NotificationModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();
        });
  }

  Future<void> markAsRead(String notificationId) async {
    if (_uid == null) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_uid == null) return;

    final batch = _firestore.batch();
    final snapshots = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> addNotification(
    NotificationModel notification,
    String recipientId,
  ) async {
    await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('notifications')
        .add({...notification.toFirestore(), 'recipientId': recipientId});
  }
}
