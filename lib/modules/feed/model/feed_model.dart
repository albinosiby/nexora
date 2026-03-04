import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/post_model.dart
class PostModel {
  final String id;
  final String userId;
  final String user;
  final String username;
  final String avatar;
  final String time;
  final String content;
  final int likes;
  final int comments;
  final int shares;
  final List<String> likedBy; // New: track users who liked
  final List<String> savedBy; // New: track users who saved
  final List<String> images;
  final List<String> hashtags;
  final List<CommentModel> commentsList;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final PollModel? poll;
  final String? feeling;
  final String visibility; // New: Public, Campus, Friends

  PostModel({
    required this.id,
    required this.userId,
    required this.user,
    required this.username,
    required this.avatar,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
    required this.shares,
    this.likedBy = const [],
    this.savedBy = const [],
    required this.images,
    required this.hashtags,
    required this.commentsList,
    required this.createdAt,
    this.updatedAt,
    this.poll,
    this.feeling,
    this.visibility = 'Public',
  });

  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool isSavedBy(String userId) => savedBy.contains(userId);

  String get displayName => username.isNotEmpty
      ? username
      : '@${user.toLowerCase().replaceAll(' ', '.')}';

  factory PostModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      user: json['user'] ?? '',
      username: json['username'] ?? '',
      avatar: (json['avatar'] as String? ?? '').startsWith('http')
          ? json['avatar']
          : 'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(json['username'] ?? json['user'] ?? json['userId'] ?? 'User')}&backgroundColor=transparent&size=200',
      time: json['time'] ?? '',
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      savedBy: List<String>.from(json['savedBy'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      commentsList: (json['comments_list'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDate(json['updatedAt'])
          : null,
      poll: json['poll'] != null ? PollModel.fromJson(json['poll']) : null,
      feeling: json['feeling'],
      visibility: json['visibility'] ?? 'Public',
    );
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return PostModel.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user': user,
      'username': username,
      'avatar': avatar,
      'time': time,
      'content': content,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'images': images,
      'hashtags': hashtags,
      'comments_list': commentsList.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'poll': poll?.toJson(),
      'feeling': feeling,
      'visibility': visibility,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? user,
    String? username,
    String? avatar,
    String? time,
    String? content,
    int? likes,
    int? comments,
    int? shares,
    List<String>? likedBy,
    List<String>? savedBy,
    List<String>? images,
    List<String>? hashtags,
    List<CommentModel>? commentsList,
    DateTime? createdAt,
    DateTime? updatedAt,
    PollModel? poll,
    String? feeling,
    String? visibility,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      time: time ?? this.time,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      likedBy: likedBy ?? this.likedBy,
      savedBy: savedBy ?? this.savedBy,
      images: images ?? this.images,
      hashtags: hashtags ?? this.hashtags,
      commentsList: commentsList ?? this.commentsList,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      poll: poll ?? this.poll,
      feeling: feeling ?? this.feeling,
      visibility: visibility ?? this.visibility,
    );
  }
}

class PollModel {
  final String question;
  final List<String> options;
  final List<int> votes;
  final Map<String, int> votedBy; // New: userId -> optionIndex

  PollModel({
    required this.question,
    required this.options,
    required this.votes,
    this.votedBy = const {},
  });

  int? userVote(String userId) => votedBy[userId];

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      votes: List<int>.from(json['votes'] ?? []),
      votedBy: Map<String, int>.from(json['votedBy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'votes': votes,
      'votedBy': votedBy,
    };
  }
}

// lib/models/comment_model.dart
class CommentModel {
  final String id;
  final String userId;
  final String user;
  final String username;
  final String avatar;
  final String comment;
  final String time;
  final DateTime createdAt;
  final List<ReplyModel> replies;
  final int likes;
  final List<String> likedBy;

  CommentModel({
    required this.id,
    required this.userId,
    required this.user,
    this.username = '',
    this.avatar = '',
    required this.comment,
    required this.time,
    required this.createdAt,
    this.replies = const [],
    this.likes = 0,
    this.likedBy = const [],
  });

  bool isLikedBy(String userId) => likedBy.contains(userId);

  String get displayName => username.isNotEmpty
      ? username
      : '@${user.toLowerCase().replaceAll(' ', '.')}';

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return CommentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      user: json['user'] ?? '',
      username: json['username'] ?? '',
      avatar: (json['avatar'] as String? ?? '').startsWith('http')
          ? json['avatar']
          : 'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(json['username'] ?? json['user'] ?? json['userId'] ?? 'User')}&backgroundColor=transparent&size=200',
      comment: json['comment'] ?? '',
      time: json['time'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      replies: (json['replies'] as List? ?? [])
          .map((r) => ReplyModel.fromJson(r))
          .toList(),
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user': user,
      'username': username,
      'avatar': avatar,
      'comment': comment,
      'time': time,
      'createdAt': createdAt.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  CommentModel copyWith({
    String? id,
    String? userId,
    String? user,
    String? username,
    String? avatar,
    String? comment,
    String? time,
    DateTime? createdAt,
    List<ReplyModel>? replies,
    int? likes,
    List<String>? likedBy,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      comment: comment ?? this.comment,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

// lib/models/reply_model.dart
class ReplyModel {
  final String id;
  final String userId;
  final String user;
  final String username;
  final String avatar;
  final String reply;
  final String time;
  final DateTime createdAt;

  ReplyModel({
    required this.id,
    required this.userId,
    required this.user,
    this.username = '',
    this.avatar = '',
    required this.reply,
    required this.time,
    required this.createdAt,
  });

  String get displayName => username.isNotEmpty
      ? username
      : '@${user.toLowerCase().replaceAll(' ', '.')}';

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return ReplyModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      user: json['user'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      reply: json['reply'] ?? '',
      time: json['time'] ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user': user,
      'username': username,
      'avatar': avatar,
      'reply': reply,
      'time': time,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
