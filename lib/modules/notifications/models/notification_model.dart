import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  comment,
  follow,
  match,
  feed,
  mention,
  connectionRequest,
  message,
  profileLike,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? targetId; // ID of the post, comment, etc.

  NotificationModel({
    required this.id,
    required this.type,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.targetId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => json['type'] == 'event'
            ? NotificationType.feed
            : NotificationType.message,
      ),
      userId: json['userId'] ?? '',
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is Timestamp
                ? (json['timestamp'] as Timestamp).toDate()
                : DateTime.parse(json['timestamp']))
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      targetId: json['targetId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'targetId': targetId,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'targetId': targetId,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? userId,
    String? userName,
    String? userAvatar,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? targetId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      targetId: targetId ?? this.targetId,
    );
  }
}
