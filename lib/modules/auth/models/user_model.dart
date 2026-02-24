// lib/modules/auth/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String? avatar;
  final String? bio;
  final String? year;
  final String? major;
  final List<String> interests;
  final bool isOnline;
  final int followers;
  final int following;
  final int posts;
  final String? instagram;
  final String? spotify;
  final String? spotifyTrackName;
  final String? spotifyArtist;
  final String? lookingFor;
  final String avatarSeed;
  final String avatarStyle;
  final List<String> chats;
  final DateTime createdAt;
  final DateTime? lastActive;
  final String? fcmToken;
  final bool pushNotifications;
  final bool messageNotifications;
  final bool feedNotifications;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone = '',
    this.avatar,
    this.bio,
    this.year,
    this.major,
    this.interests = const [],
    this.isOnline = false,
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.instagram,
    this.spotify,
    this.spotifyTrackName,
    this.spotifyArtist,
    this.lookingFor,
    this.avatarSeed = '',
    this.avatarStyle = 'avataaars',
    this.chats = const [],
    required this.createdAt,
    this.lastActive,
    this.fcmToken,
    this.pushNotifications = true,
    this.messageNotifications = true,
    this.feedNotifications = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
      year: json['year'],
      major: json['major'],
      interests: List<String>.from(json['interests'] ?? []),
      isOnline: json['isOnline'] ?? false,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      posts: json['posts'] ?? 0,
      instagram: json['instagram'],
      spotify: json['spotify'],
      spotifyTrackName: json['spotifyTrackName'],
      spotifyArtist: json['spotifyArtist'],
      lookingFor: json['lookingFor'],
      chats: List<String>.from(json['chats'] ?? []),
      avatarSeed: json['avatarSeed'] ?? '',
      avatarStyle: json['avatarStyle'] ?? 'avataaars',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
                ? DateTime.parse(json['createdAt'])
                : (json['createdAt'] as dynamic).toDate())
          : DateTime.now(),
      lastActive: json['lastActive'] != null
          ? (json['lastActive'] is String
                ? DateTime.parse(json['lastActive'])
                : (json['lastActive'] as dynamic).toDate())
          : null,
      pushNotifications: json['pushNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      feedNotifications: json['feedNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'bio': bio,
      'year': year,
      'major': major,
      'interests': interests,
      'isOnline': isOnline,
      'followers': followers,
      'following': following,
      'posts': posts,
      'instagram': instagram,
      'spotify': spotify,
      'spotifyTrackName': spotifyTrackName,
      'spotifyArtist': spotifyArtist,
      'lookingFor': lookingFor,
      'avatarSeed': avatarSeed,
      'avatarStyle': avatarStyle,
      'chats': chats,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'fcmToken': fcmToken,
      'pushNotifications': pushNotifications,
      'messageNotifications': messageNotifications,
      'feedNotifications': feedNotifications,
    };
  }

  // Firestore specific serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'bio': bio,
      'year': year,
      'major': major,
      'interests': interests,
      'isOnline': isOnline,
      'followers': followers,
      'following': following,
      'posts': posts,
      'instagram': instagram,
      'spotify': spotify,
      'spotifyTrackName': spotifyTrackName,
      'spotifyArtist': spotifyArtist,
      'lookingFor': lookingFor,
      'avatarSeed': avatarSeed,
      'avatarStyle': avatarStyle,
      'chats': chats,
      'createdAt': createdAt, // Firestore uses Timestamp
      'lastActive': lastActive ?? DateTime.now(),
      'fcmToken': fcmToken,
      'pushNotifications': pushNotifications,
      'messageNotifications': messageNotifications,
      'feedNotifications': feedNotifications,
    };
  }

  // RTDB specific serialization (for chat simulation/online status)
  Map<String, dynamic> toRTDB() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastActive': {".sv": "timestamp"}, // Use RTDB server timestamp
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? avatar,
    String? bio,
    String? year,
    String? major,
    List<String>? interests,
    bool? isOnline,
    int? followers,
    int? following,
    int? posts,
    String? instagram,
    String? spotify,
    String? spotifyTrackName,
    String? spotifyArtist,
    String? lookingFor,
    String? avatarSeed,
    String? avatarStyle,
    List<String>? chats,
    DateTime? createdAt,
    DateTime? lastActive,
    String? fcmToken,
    bool? pushNotifications,
    bool? messageNotifications,
    bool? feedNotifications,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      year: year ?? this.year,
      major: major ?? this.major,
      interests: interests ?? this.interests,
      isOnline: isOnline ?? this.isOnline,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      instagram: instagram ?? this.instagram,
      spotify: spotify ?? this.spotify,
      spotifyTrackName: spotifyTrackName ?? this.spotifyTrackName,
      spotifyArtist: spotifyArtist ?? this.spotifyArtist,
      lookingFor: lookingFor ?? this.lookingFor,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      chats: chats ?? this.chats,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      fcmToken: fcmToken ?? this.fcmToken,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      feedNotifications: feedNotifications ?? this.feedNotifications,
    );
  }
}
