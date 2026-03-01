import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  final String userId;
  final String name;
  final String avatar;
  final String major;
  final String year;
  final DateTime timestamp;

  ConnectionModel({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.major,
    required this.year,
    required this.timestamp,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      major: json['major'] ?? '',
      year: json['year'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'major': major,
      'year': year,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
