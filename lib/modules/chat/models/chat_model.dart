class ChatModel {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final Map<String, bool> typingStatus;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.typingStatus = const {},
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, String id) {
    return ChatModel(
      id: id,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
        json['lastMessageTime'] ?? 0,
      ),
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      typingStatus: Map<String, bool>.from(json['typingStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCounts': unreadCounts,
      'typingStatus': typingStatus,
    };
  }
}
