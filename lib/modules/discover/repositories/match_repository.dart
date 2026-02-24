import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_user_model.dart';
import '../../auth/repositories/auth_repository.dart';

/// MatchRepository provides realtime user data for the discover/matching screen.
/// Uses Firestore as the primary source, falls back to DummyDatabase for development.
class MatchRepository extends GetxService {
  static MatchRepository get instance => Get.find<MatchRepository>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _auth = AuthRepository.instance;

  String? get _currentUserId => _auth.user?.uid;

  /// Realtime stream of all users (excluding current user) from Firestore.
  /// Falls back to DummyDatabase if Firestore collection is empty.
  Stream<List<MatchUserModel>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.id != _currentUserId)
              .map((doc) => MatchUserModel.fromFirestore(doc.data(), doc.id))
              .toList();
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
