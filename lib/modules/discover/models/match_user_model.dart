import '../../profile/models/profile_model.dart';

/// Model representing a user in the discover/matching context
class MatchUserModel {
  final String id;
  final String name;
  final String username;
  final int age;
  final String year;
  final String major;
  final String bio;
  final List<String> interests;
  final String avatar;
  final int connections;
  final bool isOnline;
  final bool isVerified;
  final DateTime? lastActive;
  final List<String> photos;
  final String? lookingFor;
  final int profileLikes;
  final List<String> likedBy;

  MatchUserModel({
    required this.id,
    required this.name,
    this.username = '',
    this.age = 18,
    this.year = '',
    this.major = '',
    this.bio = '',
    this.interests = const [],
    required this.avatar,
    this.connections = 0,
    this.isOnline = false,
    this.isVerified = false,
    this.lastActive,
    this.photos = const [],
    this.lookingFor,
    this.profileLikes = 0,
    this.likedBy = const [],
  });

  /// Create from Firestore document data
  factory MatchUserModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return MatchUserModel(
      id: docId,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      age: data['age'] ?? 18,
      year: data['year'] ?? '',
      major: data['major'] ?? '',
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      avatar: (data['avatar'] as String? ?? '').startsWith('http')
          ? data['avatar']
          : 'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(data['username'] ?? data['name'] ?? 'User')}&backgroundColor=transparent&size=200',
      connections: data['followers'] ?? data['connections'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] is String
                ? DateTime.tryParse(data['lastActive'])
                : (data['lastActive'] as dynamic).toDate())
          : null,
      photos: List<String>.from(data['photos'] ?? []),
      lookingFor: data['lookingFor'],
      profileLikes: data['profileLikes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  /// Convert to ProfileModel for navigation
  ProfileModel toProfileModel() {
    return ProfileModel(
      id: id,
      name: name,
      username: username,
      email: '',
      avatar: avatar,
      bio: bio,
      year: year,
      major: major,
      age: age,
      isOnline: isOnline,
      isVerified: isVerified,
      interests: interests,
      photos: photos,
      connections: connections,
      lookingFor: lookingFor,
      profileLikes: profileLikes,
      likedBy: likedBy,
    );
  }

  /// Format last active time as human-readable string
  String get formattedLastActive {
    if (lastActive == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(lastActive!);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Public display name (uses username if available, else formatted name)
  String get displayName =>
      username.isNotEmpty ? username : name.toLowerCase().replaceAll(' ', '.');
}
