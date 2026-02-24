import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/user_model.dart';

class UserRepository extends GetxService {
  static UserRepository get instance => Get.find<UserRepository>();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _auth = AuthRepository.instance;

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
      connections: user.followers,
      posts: user.posts,
      instagram: user.instagram,
      spotify: user.spotify,
      spotifyTrackName: user.spotifyTrackName,
      spotifyArtist: user.spotifyArtist,
      lookingFor: user.lookingFor,
      avatarSeed: user.avatarSeed,
      avatarStyle: user.avatarStyle,
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
}
