import 'package:get/get.dart';
import '../../../core/services/dummy_database.dart';

/// UserRepository - Handles all user data operations
/// Abstracts DummyDatabase access for user-related data
class UserRepository {
  final DummyDatabase _db = DummyDatabase.instance;

  /// Get current logged in user
  UserData get currentUser => _db.currentUser.value;

  /// Get current user as observable
  Rx<UserData> get currentUserRx => _db.currentUser;

  /// Get all users for discover
  List<UserData> getAllUsers() => _db.getAllUsersExceptCurrent();

  /// Get user by ID
  UserData? getUserById(String userId) => _db.getUserById(userId);

  /// Get online users
  List<UserData> getOnlineUsers() {
    return _db.users.where((u) => u.isOnline).toList();
  }

  /// Get verified users
  List<UserData> getVerifiedUsers() {
    return _db.users.where((u) => u.isVerified).toList();
  }

  /// Get new users (registered within 30 days)
  List<UserData> getNewUsers() {
    final threshold = DateTime.now().subtract(const Duration(days: 30));
    return _db.users.where((u) {
      return u.createdAt != null && u.createdAt!.isAfter(threshold);
    }).toList();
  }

  /// Search users by name or major
  List<UserData> searchUsers(String query) {
    final q = query.toLowerCase();
    return _db.users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.major.toLowerCase().contains(q) ||
          u.interests.any((i) => i.toLowerCase().contains(q));
    }).toList();
  }

  /// Update current user profile
  void updateProfile({
    String? name,
    String? bio,
    String? year,
    String? major,
    List<String>? interests,
    String? instagram,
    String? spotify,
    String? lookingFor,
  }) {
    _db.updateCurrentUserProfile(
      name: name,
      bio: bio,
      year: year,
      major: major,
      interests: interests,
      instagram: instagram,
      spotify: spotify,
      lookingFor: lookingFor,
    );
  }

  /// Get connected users for current user
  List<UserData> getConnectedUsers() => _db.getConnectedUsers();

  /// Get users with active stories
  List<UserData> getUsersWithStories() => _db.getUsersWithStories();
}
