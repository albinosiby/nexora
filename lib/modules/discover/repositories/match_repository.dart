import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/match_user_model.dart';
import '../../auth/repositories/auth_repository.dart';

/// MatchRepository provides realtime user data for the discover/matching screen.
class MatchRepository extends GetxService {
  static MatchRepository get instance => Get.find<MatchRepository>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final AuthRepository _auth = AuthRepository.instance;

  String? get _currentUserId => _auth.user?.uid;

  /// Realtime stream of all users (excluding current user) from Firestore,
  /// with real-time online status from RTDB.
  Stream<List<MatchUserModel>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final users = snapshot.docs
              .where((doc) => doc.id != _currentUserId)
              .map((doc) => MatchUserModel.fromFirestore(doc.data(), doc.id))
              .toList();

          // Fetch real-time online status from RTDB for each user
          final updatedUsers = await Future.wait(
            users.map((user) async {
              try {
                final presenceSnap = await _rtdb
                    .ref('users/${user.id}/isOnline')
                    .get();
                final isOnline = presenceSnap.value as bool? ?? false;
                if (isOnline != user.isOnline) {
                  return MatchUserModel(
                    id: user.id,
                    name: user.name,
                    username: user.username,
                    age: user.age,
                    year: user.year,
                    major: user.major,
                    bio: user.bio,
                    interests: user.interests,
                    avatar: user.avatar,
                    connections: user.connections,
                    isOnline: isOnline,
                    isVerified: user.isVerified,
                    lastActive: user.lastActive,
                    photos: user.photos,
                    lookingFor: user.lookingFor,
                    profileLikes: user.profileLikes,
                    likedBy: user.likedBy,
                  );
                }
                return user;
              } catch (_) {
                return user;
              }
            }),
          );

          return updatedUsers;
        });
  }

  /// Search users by name or username from Firestore
  Future<List<MatchUserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();

    // Search by username prefix
    final usernameResults = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('username', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .limit(20)
        .get();

    final users = usernameResults.docs
        .where((doc) => doc.id != _currentUserId)
        .map((doc) => MatchUserModel.fromFirestore(doc.data(), doc.id))
        .toList();

    return users;
  }

  /// Get a single user by ID as a stream (for realtime profile updates)
  Stream<MatchUserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return MatchUserModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }
}
