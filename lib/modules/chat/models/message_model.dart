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
  final String? reaction;
  final int? duration;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
    this.reaction,
    this.duration,
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
      reaction: json['reaction'],
      duration: json['duration'],
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
      'reaction': reaction,
      'duration': duration,
    };
  }
}
