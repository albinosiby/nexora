import 'package:firebase_database/firebase_database.dart';

enum MessageType { text, image, voice, video, file }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final String? reaction;
  final int? duration;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.reaction,
    this.duration,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) {
    return MessageModel(
      id: id,
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      type: () {
        final typeStr = json['type']?.toString().toLowerCase() ?? 'text';
        return MessageType.values.firstWhere(
          (e) => e.name.toLowerCase() == typeStr,
          orElse: () => MessageType.text,
        );
      }(),
      mediaUrl: json['mediaUrl'],
      timestamp: () {
        final ts = json['timestamp'];
        if (ts is int) {
          return DateTime.fromMillisecondsSinceEpoch(ts);
        } else if (ts is Map) {
          // ServerValue.timestamp placeholder
          return DateTime.now();
        }
        return DateTime.now();
      }(),
      isRead: json['isRead'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      reaction: json['reaction'],
      duration: json['duration'],
      replyToId: json['replyToId'],
      replyToContent: json['replyToContent'],
      replyToSenderId: json['replyToSenderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'timestamp': ServerValue.timestamp,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'reaction': reaction,
      'duration': duration,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToContent != null) 'replyToContent': replyToContent,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    String? mediaUrl,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    String? reaction,
    int? duration,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      reaction: reaction ?? this.reaction,
      duration: duration ?? this.duration,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
    );
  }
}
