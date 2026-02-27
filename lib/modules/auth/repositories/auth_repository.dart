// lib/modules/auth/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRepository extends GetxService {
  static AuthRepository get instance => Get.find<AuthRepository>();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final Rx<fb.User?> _firebaseUser = Rx<fb.User?>(null);
  fb.User? get user => _firebaseUser.value;

  final Rx<UserModel?> _currentUserProfile = Rx<UserModel?>(null);
  UserModel? get currentUserProfile => _currentUserProfile.value;

  final RxBool _isProfileLoading = false.obs;
  bool get isProfileLoading => _isProfileLoading.value;

  final RxBool _showOnboarding = true.obs;
  bool get showOnboarding => _showOnboarding.value;

  @override
  void onInit() {
    super.onInit();
    _checkOnboardingStatus();
    _firebaseUser.bindStream(_auth.authStateChanges());

    // Periodically sync profile
    ever<fb.User?>(_firebaseUser, (fb.User? user) async {
      if (user != null) {
        _isProfileLoading.value = true;
        final profile = await getUserProfile(user.uid);
        _currentUserProfile.value = profile;
        _isProfileLoading.value = false;

        // Sync with RTDB and set up presence handlers
        if (profile != null) {
          await syncUserWithRTDB(profile);
        }
      } else {
        _currentUserProfile.value = null;
        _isProfileLoading.value = false;
      }
    });
  }

  // Phone Authentication
  Future<void> signInWithPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        onVerificationFailed(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOtp(
    String verificationId,
    String smsCode,
  ) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // User Profile Management (Firestore)
  Future<void> createUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
    await syncUserWithRTDB(user);
    _currentUserProfile.value = user;
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  // RTDB User Sync (for Chat Simulation & Online Status)
  Future<void> syncUserWithRTDB(UserModel userModel) async {
    final userRef = _database.ref('users/${userModel.id}');
    await userRef.update(userModel.toRTDB());

    // Set up presence
    final connectedRef = _database.ref(".info/connected");
    connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        userRef.onDisconnect().update({
          'isOnline': false,
          'lastActive': ServerValue.timestamp,
        });
        userRef.update({'isOnline': true, 'lastActive': ServerValue.timestamp});
      }
    });
  }

  /// Refresh the current user profile from Firestore
  Future<void> refreshProfile() async {
    if (user != null) {
      _currentUserProfile.value = await getUserProfile(user!.uid);
    }
  }

  Future<void> signOut() async {
    if (user != null) {
      await _database.ref('users/${user!.uid}').update({
        'isOnline': false,
        'lastActive': ServerValue.timestamp,
      });
    }
    await _auth.signOut();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _showOnboarding.value = prefs.getBool('showOnboarding') ?? true;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    _showOnboarding.value = false;
  }

  /// Save FCM token to Firestore
  Future<void> saveFcmToken(String token) async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.uid).update({
        'fcmToken': token,
      });
      // Also update local profile if it exists
      if (_currentUserProfile.value != null) {
        _currentUserProfile.value = _currentUserProfile.value!.copyWith(
          // Assuming fcmToken exists in UserModel or we can just ignore local sync for now
          // If UserModel has it, we should add it there too.
        );
      }
    }
  }
}
