class ProfileModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String avatar;
  final String bio;
  final String year;
  final String major;
  final String avatarSeed;
  final String avatarStyle;
  final int age;
  final String? gender;
  final DateTime? dateOfBirth;
  final bool isVjecStudent;
  final bool isOnline;
  final bool isVerified;
  final int connections;
  final int posts;
  final List<String> interests;
  final String? instagram;
  final String? spotify;
  final String? spotifyTrackName;
  final String? spotifyArtist;
  final String? lookingFor;
  final List<String> chats;
  final List<String> photos;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final String? fcmToken;
  final bool pushNotifications;
  final bool messageNotifications;
  final bool feedNotifications;

  ProfileModel({
    required this.id,
    required this.name,
    this.username = '',
    required this.email,
    this.phone = '',
    required this.avatar,
    this.bio = '',
    this.year = '',
    this.major = '',
    this.avatarSeed = '',
    this.avatarStyle = 'avataaars',
    this.age = 18,
    this.gender,
    this.dateOfBirth,
    this.isVjecStudent = false,
    this.isOnline = false,
    this.isVerified = false,
    this.connections = 0,
    this.posts = 0,
    this.interests = const [],
    this.instagram,
    this.spotify,
    this.spotifyTrackName,
    this.spotifyArtist,
    this.lookingFor,
    this.chats = const [],
    this.photos = const [],
    this.createdAt,
    this.lastActive,
    this.fcmToken,
    this.pushNotifications = true,
    this.messageNotifications = true,
    this.feedNotifications = true,
  });

  String get displayName =>
      username.isNotEmpty ? username : name.toLowerCase().replaceAll(' ', '.');

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final avatarSeed = json['avatarSeed'] ?? '';
    final avatarStyle = json['avatarStyle'] ?? 'avataaars';
    final name = json['name'] ?? '';
    final rawAvatar = json['avatar'] ?? '';
    // Generate DiceBear URL if avatar field is empty
    final seed = avatarSeed.isNotEmpty ? avatarSeed : name;
    final generatedAvatar = seed.isNotEmpty
        ? 'https://api.dicebear.com/7.x/$avatarStyle/png?seed=${Uri.encodeComponent(seed)}&backgroundColor=transparent&size=200'
        : '';
    final avatar = (rawAvatar is String && rawAvatar.isNotEmpty)
        ? rawAvatar
        : generatedAvatar;

    return ProfileModel(
      id: json['id'] ?? '',
      name: name,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: avatar,
      bio: json['bio'] ?? '',
      year: json['year'] ?? '',
      major: json['major'] ?? '',
      avatarSeed: avatarSeed,
      avatarStyle: avatarStyle,
      age: json['age'] ?? 18,
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      isVjecStudent: json['isVjecStudent'] ?? false,
      isOnline: json['isOnline'] ?? false,
      isVerified: json['isVerified'] ?? false,
      connections: json['connections'] ?? json['followers'] ?? 0,
      posts: json['posts'] ?? 0,
      interests: List<String>.from(json['interests'] ?? []),
      instagram: json['instagram'],
      spotify: json['spotify'],
      spotifyTrackName: json['spotifyTrackName'],
      spotifyArtist: json['spotifyArtist'],
      lookingFor: json['lookingFor'],
      chats: List<String>.from(json['chats'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : null,
      fcmToken: json['fcmToken'],
      pushNotifications: json['pushNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      feedNotifications: json['feedNotifications'] ?? true,
    );
  }

  factory ProfileModel.fromUserData(dynamic userData) {
    // Handle UserModel specifically for proper field mapping
    final avatarSeed = userData.avatarSeed ?? '';
    final avatarStyle = userData.avatarStyle ?? 'avataaars';
    final name = userData.name ?? '';
    final rawAvatar = userData.avatar;
    // Generate DiceBear URL if avatar field is empty/null
    final seed = avatarSeed.isNotEmpty ? avatarSeed : name;
    final generatedAvatar = seed.isNotEmpty
        ? 'https://api.dicebear.com/7.x/$avatarStyle/png?seed=${Uri.encodeComponent(seed)}&backgroundColor=transparent&size=200'
        : '';
    final avatar = (rawAvatar != null && rawAvatar.isNotEmpty)
        ? rawAvatar
        : generatedAvatar;

    return ProfileModel(
      id: userData.id ?? '',
      name: name,
      username: userData.username ?? '',
      email: userData.email ?? '',
      phone: userData.phone ?? '',
      avatar: avatar,
      bio: userData.bio ?? '',
      year: userData.year ?? '',
      major: userData.major ?? '',
      interests: userData.interests ?? const [],
      isOnline: userData.isOnline ?? false,
      connections: userData.connections ?? 0,
      posts: userData.posts ?? 0,
      instagram: userData.instagram,
      spotify: userData.spotify,
      spotifyTrackName: userData.spotifyTrackName,
      spotifyArtist: userData.spotifyArtist,
      lookingFor: userData.lookingFor,
      age: userData.age,
      chats: userData.chats ?? const [],
      avatarSeed: avatarSeed,
      avatarStyle: avatarStyle,
      photos: [],
      createdAt: userData.createdAt,
      lastActive: userData.lastActive,
      fcmToken: userData.fcmToken,
      pushNotifications: (userData as dynamic).pushNotifications ?? true,
      messageNotifications: (userData as dynamic).messageNotifications ?? true,
      feedNotifications: (userData as dynamic).feedNotifications ?? true,
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
      'avatarSeed': avatarSeed,
      'avatarStyle': avatarStyle,
      'age': age,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'isVjecStudent': isVjecStudent,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'connections': connections,
      'posts': posts,
      'interests': interests,
      'instagram': instagram,
      'spotify': spotify,
      'spotifyTrackName': spotifyTrackName,
      'spotifyArtist': spotifyArtist,
      'lookingFor': lookingFor,
      'chats': chats,
      'photos': photos,
      'createdAt': createdAt?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'fcmToken': fcmToken,
      'pushNotifications': pushNotifications,
      'messageNotifications': messageNotifications,
      'feedNotifications': feedNotifications,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? avatar,
    String? bio,
    String? year,
    String? major,
    String? avatarSeed,
    String? avatarStyle,
    int? age,
    String? gender,
    DateTime? dateOfBirth,
    bool? isVjecStudent,
    bool? isOnline,
    bool? isVerified,
    int? connections,
    int? posts,
    List<String>? interests,
    String? instagram,
    String? spotify,
    String? spotifyTrackName,
    String? spotifyArtist,
    String? lookingFor,
    List<String>? chats,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? lastActive,
    String? fcmToken,
    bool? pushNotifications,
    bool? messageNotifications,
    bool? feedNotifications,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      year: year ?? this.year,
      major: major ?? this.major,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isVjecStudent: isVjecStudent ?? this.isVjecStudent,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      connections: connections ?? this.connections,
      posts: posts ?? this.posts,
      interests: interests ?? this.interests,
      instagram: instagram ?? this.instagram,
      spotify: spotify ?? this.spotify,
      spotifyTrackName: spotifyTrackName ?? this.spotifyTrackName,
      spotifyArtist: spotifyArtist ?? this.spotifyArtist,
      lookingFor: lookingFor ?? this.lookingFor,
      chats: chats ?? this.chats,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      fcmToken: fcmToken ?? this.fcmToken,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      feedNotifications: feedNotifications ?? this.feedNotifications,
    );
  }
}
