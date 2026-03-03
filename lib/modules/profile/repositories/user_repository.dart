import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../../notifications/models/notification_model.dart';

class UserRepository {
  static final UserRepository instance = UserRepository();

  final FirebaseDatabase _db;
  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  UserRepository({
    FirebaseDatabase? firebaseDatabase,
    FirebaseFirestore? firebaseFirestore,
    AuthRepository? authRepository,
  }) : _db = firebaseDatabase ?? FirebaseDatabase.instance,
       _firestore = firebaseFirestore ?? FirebaseFirestore.instance,
       _auth = authRepository ?? AuthRepository.instance;

  String? get currentUserId => _auth.user?.uid;

  /// Get current logged in user profile
  ProfileModel get currentUser {
    final user = _auth.currentUserProfile;
    if (user == null) {
      return ProfileModel(
        id: 'anonymous',
        name: 'Anonymous',
        email: '',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=Anon',
      );
    }
    return ProfileModel(
      id: user.id,
      name: user.name,
      email: user.email,
      avatar:
          user.avatar ??
          'https://api.dicebear.com/7.x/avataaars/png?seed=${user.name}',
      username: user.username,
      bio: user.bio ?? '',
      year: user.year ?? '',
      major: user.major ?? '',
      interests: user.interests,
      isOnline: user.isOnline,
      connections: user.connections,
      posts: user.posts,
      instagram: user.instagram,
      lookingFor: user.lookingFor,
      avatarSeed: user.avatarSeed,
      avatarStyle: user.avatarStyle,
      profileLikes: user.profileLikes,
      likedBy: user.likedBy,
      photos: [],
    );
  }

  /// Get user by ID from Firestore
  Future<ProfileModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return ProfileModel.fromUserData(UserModel.fromJson(doc.data()!));
    }
    return null;
  }

  /// Stream of user by ID from Firestore
  Stream<ProfileModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return ProfileModel.fromUserData(UserModel.fromJson(doc.data()!));
      }
      return null;
    });
  }

  /// Stream of user presence (online status) from RTDB
  Stream<bool> getUserPresenceStream(String userId) {
    return _db.ref('users/$userId/isOnline').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Get search results from Firestore
  Future<List<ProfileModel>> searchUsers(String query) async {
    final results = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return results.docs
        .map((doc) => ProfileModel.fromUserData(UserModel.fromJson(doc.data())))
        .toList();
  }

  /// Update current user profile in Firestore and sync limited data to RTDB
  Future<void> updateProfile(ProfileModel profile) async {
    if (currentUserId == null) return;

    // Convert ProfileModel to UserModel for AuthRepository consistency if needed
    // or just update Firestore directly
    final userDoc = _firestore.collection('users').doc(currentUserId);
    final userData = profile.toJson();

    // We want to keep UserModel structure in Firestore
    await userDoc.update(userData);

    // Sync limited data to RTDB for chat simulation
    await _db.ref('users/$currentUserId').update({
      'name': profile.name,
      'username': profile.username,
      'avatar': profile.avatar,
    });

    // Refresh local profile state from Firestore
    await _auth.refreshProfile();
  }

  /// Check if a username is already taken by another user
  Future<bool> isUsernameTaken(String username) async {
    if (username.isEmpty) return false;
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    // Exclude the current user from results
    final otherUsers = query.docs.where((doc) => doc.id != currentUserId);
    return otherUsers.isNotEmpty;
  }

  /// Get user by username from Firestore
  Future<ProfileModel?> getUserByUsername(String username) async {
    if (username.isEmpty) return null;
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ProfileModel.fromUserData(
        UserModel.fromJson(query.docs.first.data()),
      );
    }
    return null;
  }

  /// Submit feedback to Firestore
  Future<void> submitFeedback(String category, String message) async {
    if (currentUserId == null) return;

    await _firestore.collection('feedback').add({
      'userId': currentUserId,
      'userName': currentUser.name,
      'userEmail': currentUser.email,
      'category': category,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle profile like
  Future<void> toggleProfileLike(String targetUserId) async {
    if (currentUserId == null) return;

    try {
      final targetUserDoc = _firestore.collection('users').doc(targetUserId);
      final targetDoc = await targetUserDoc.get();

      if (!targetDoc.exists) return;

      final targetData = targetDoc.data()!;
      final List<String> likedBy = List<String>.from(
        targetData['likedBy'] ?? [],
      );
      final bool isCurrentlyLiked = likedBy.contains(currentUserId);

      if (isCurrentlyLiked) {
        // Unlike
        await targetUserDoc.update({
          'likedBy': FieldValue.arrayRemove([currentUserId]),
          'profileLikes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await targetUserDoc.update({
          'likedBy': FieldValue.arrayUnion([currentUserId]),
          'profileLikes': FieldValue.increment(1),
        });

        // Get current user info for notification
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final currentUserDoc = await currentUserRef.get();
        if (currentUserDoc.exists) {
          final currentUserData = currentUserDoc.data()!;
          final currentUserName =
              currentUserData['username'] ??
              currentUserData['name'] ??
              'Someone';
          final currentUserAvatar = currentUserData['avatar'] ?? '';

          // Send notification
          final notification = NotificationModel(
            id: '',
            type: NotificationType.profileLike,
            userId: currentUserId!,
            userName: currentUserName,
            userAvatar: currentUserAvatar,
            message: 'liked your profile! ✨',
            timestamp: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(targetUserId)
              .collection('notifications')
              .add(notification.toFirestore());
        }
      }

      // Refresh local state if the target is the current user (unlikely but possible)
      if (targetUserId == currentUserId) {
        await _auth.refreshProfile();
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }
}
