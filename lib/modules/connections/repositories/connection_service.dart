import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/repositories/notification_repository.dart';

enum ConnectionStatus {
  none,
  pending, // You sent a request
  incoming, // They sent you a request
  connected,
}

class ConnectionRequest {
  final String id;
  final String userId;
  final String name; // Display name (username for public)
  final String? avatar;
  final String? major;
  final String? year;
  final DateTime timestamp;
  final bool
  isIncoming; // true = they requested you, false = you requested them

  ConnectionRequest({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.major,
    this.year,
    required this.timestamp,
    required this.isIncoming,
  });
}

class ConnectionService extends GetxController {
  static ConnectionService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _auth = AuthRepository.instance;
  final NotificationRepository _notificationRepo = NotificationRepository();

  // List of connection requests (incoming)
  final RxList<ConnectionRequest> _incomingRequests = <ConnectionRequest>[].obs;

  // List of sent requests (pending)
  final RxList<ConnectionRequest> _sentRequests = <ConnectionRequest>[].obs;

  // List of connected users
  final RxList<ConnectionRequest> _connections = <ConnectionRequest>[].obs;

  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _connectionsSub;
  StreamSubscription? _authSub;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes to setup/cleanup listeners
    _authSub = _auth.userRx.listen((user) {
      if (user != null) {
        _setupFirestoreListeners();
      } else {
        _cleanupListeners();
      }
    });

    // Initial check if user is already logged in
    if (_auth.user != null) {
      _setupFirestoreListeners();
    }
  }

  @override
  void onClose() {
    _cleanupListeners();
    _authSub?.cancel();
    super.onClose();
  }

  void _cleanupListeners() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _connectionsSub?.cancel();

    _incomingSub = null;
    _outgoingSub = null;
    _connectionsSub = null;

    // Clear data
    _incomingRequests.clear();
    _sentRequests.clear();
    _connections.clear();
  }

  void _setupFirestoreListeners() {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    // Cancel existing listeners before re-setup to avoid duplicates
    _cleanupListeners();

    // Listen for incoming requests
    _incomingSub = _firestore
        .collection('connection_requests')
        .where('toId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (snapshot) {
            final requests = snapshot.docs.map((doc) {
              final data = doc.data();
              return ConnectionRequest(
                id: doc.id,
                userId: data['fromId'] ?? '',
                name: data['fromName'] ?? 'Someone',
                avatar: data['fromAvatar'],
                major: data['fromMajor'],
                year: data['fromYear'],
                timestamp:
                    (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isIncoming: true,
              );
            }).toList();

            _incomingRequests.assignAll(requests);
          },
          onError: (e) => debugPrint('Error in incoming requests listener: $e'),
        );

    // Listen for accepted connections from my sub-collection
    _connectionsSub = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('connections')
        .snapshots()
        .listen((snapshot) {
          final conns = snapshot.docs
              .map(
                (doc) => ConnectionRequest(
                  id: doc.id,
                  userId: doc.data()['userId'] ?? doc.id,
                  name: doc.data()['name'] ?? 'Connected User',
                  avatar: doc.data()['avatar'],
                  major: doc.data()['major'],
                  year: doc.data()['year'],
                  timestamp:
                      (doc.data()['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  isIncoming: false,
                ),
              )
              .toList();

          _connections.assignAll(conns);
        }, onError: (e) => debugPrint('Error in connections listener: $e'));

    // Listen for pending sent requests
    _outgoingSub = _firestore
        .collection('connection_requests')
        .where('fromId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          final sent = snapshot.docs.map((doc) {
            final data = doc.data();
            return ConnectionRequest(
              id: doc.id,
              userId: data['toId'] ?? '',
              name: data['toName'] ?? 'Pending...',
              avatar: data['toAvatar'],
              major: data['toMajor'],
              year: data['toYear'],
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isIncoming: false,
            );
          }).toList();

          _sentRequests.assignAll(sent);
        }, onError: (e) => debugPrint('Error in sent requests listener: $e'));
  }

  // Getters
  List<ConnectionRequest> get incomingRequests => _incomingRequests;
  List<ConnectionRequest> get sentRequests => _sentRequests;
  List<ConnectionRequest> get connections => _connections;
  int get incomingCount => _incomingRequests.length;

  ConnectionStatus getStatus(String userId) {
    if (_connections.any((c) => c.userId == userId)) {
      return ConnectionStatus.connected;
    }
    if (_incomingRequests.any((r) => r.userId == userId)) {
      return ConnectionStatus.incoming;
    }
    if (_sentRequests.any((s) => s.userId == userId)) {
      return ConnectionStatus.pending;
    }
    return ConnectionStatus.none;
  }

  // Send connection request
  Future<bool> sendRequest({
    required String userId,
    required String name,
    required String avatar,
    required String major,
    required String year,
  }) async {
    final currentUserId = _auth.user?.uid;
    final currentUser = _auth.currentUserProfile;

    if (currentUserId == null) return false;

    if (currentUser == null) {
      Get.snackbar(
        'Profile Loading',
        'Please wait for your profile to load before connecting',
        backgroundColor: NexoraColors.warning.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    final status = getStatus(userId);
    if (status == ConnectionStatus.none) {
      final requestId = '${currentUserId}_$userId';

      final requestData = {
        'id': requestId,
        'fromId': currentUserId,
        'toId': userId,
        'fromName': currentUser.displayName,
        'fromAvatar': currentUser.avatar ?? '',
        'fromMajor': currentUser.major ?? '',
        'fromYear': currentUser.year ?? '',
        'toName': name,
        'toAvatar': avatar,
        'toMajor': major,
        'toYear': year,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      try {
        await _firestore
            .collection('connection_requests')
            .doc(requestId)
            .set(requestData);

        // Send notification to recipient
        final notification = NotificationModel(
          id: '', // Firestore will generate an ID if needed, or repo handles it
          type: NotificationType.connectionRequest,
          userId: currentUserId,
          userName: currentUser.displayName,
          userAvatar: currentUser.avatar,
          message: 'sent you a connection request',
          timestamp: DateTime.now(),
        );

        await _notificationRepo.addNotification(notification, userId);
        return true;
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to send connection request. Please try again.',
          backgroundColor: NexoraColors.error.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    }
    return false;
  }

  // Add an incoming connection request (removed as it was only for mock demo)

  // Accept incoming request
  void acceptRequest(String userId) async {
    final currentUserId = _auth.user?.uid;
    final currentUser = _auth.currentUserProfile;
    if (currentUserId == null || currentUser == null) return;

    final requestId = '${userId}_$currentUserId';

    try {
      // Need to get details of the person who sent the request
      final requestDoc = await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) return;

      final requestData = requestDoc.data()!;
      final otherName = requestData['fromName'] ?? 'Someone';
      final otherAvatar = requestData['fromAvatar'] ?? '';
      final otherMajor = requestData['fromMajor'] ?? '';
      final otherYear = requestData['fromYear'] ?? '';

      final batch = _firestore.batch();

      // 1. Update request status
      final requestRef = _firestore
          .collection('connection_requests')
          .doc(requestId);
      batch.update(requestRef, {
        'status': 'accepted',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Increment my connection count (connections field)
      final myUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(myUserRef, {'connections': FieldValue.increment(1)});

      // 3. Increment their connection count
      final theirUserRef = _firestore.collection('users').doc(userId);
      batch.update(theirUserRef, {'connections': FieldValue.increment(1)});

      // 4. Create connection doc in my sub-collection
      final myConnRef = myUserRef.collection('connections').doc(userId);
      batch.set(myConnRef, {
        'userId': userId,
        'name': otherName,
        'avatar': otherAvatar,
        'major': otherMajor,
        'year': otherYear,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Create connection doc in their sub-collection
      final theirConnRef = theirUserRef
          .collection('connections')
          .doc(currentUserId);
      batch.set(theirConnRef, {
        'userId': currentUserId,
        'name': currentUser.displayName,
        'avatar': currentUser.avatar,
        'major': currentUser.major,
        'year': currentUser.year,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Notify requester
      if (currentUser != null) {
        final notification = NotificationModel(
          id: '',
          type: NotificationType.match,
          userId: currentUserId,
          userName: currentUser.displayName,
          userAvatar: currentUser.avatar,
          message: 'accepted your connection request',
          timestamp: DateTime.now(),
        );

        await _notificationRepo.addNotification(notification, userId);
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');
      Get.snackbar(
        'Error',
        'Failed to accept request. Please try again.',
        backgroundColor: NexoraColors.error.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  // Reject/decline incoming request
  void rejectRequest(String userId) async {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    final requestId = '${userId}_$currentUserId';
    await _firestore.collection('connection_requests').doc(requestId).delete();
  }

  // Cancel sent request
  void cancelRequest(String userId) async {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    final requestId = '${currentUserId}_$userId';
    await _firestore.collection('connection_requests').doc(requestId).delete();
  }

  // Remove connection
  void removeConnection(String userId) async {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    try {
      // Can be either way (A_B or B_A)
      final req1 = '${currentUserId}_$userId';
      final req2 = '${userId}_$currentUserId';

      final doc1 = await _firestore
          .collection('connection_requests')
          .doc(req1)
          .get();
      DocumentReference? requestToDelete;

      if (doc1.exists) {
        requestToDelete = doc1.reference;
      } else {
        final doc2 = await _firestore
            .collection('connection_requests')
            .doc(req2)
            .get();
        if (doc2.exists) {
          requestToDelete = doc2.reference;
        }
      }

      if (requestToDelete != null) {
        final batch = _firestore.batch();

        // 1. Delete the connection request document
        batch.delete(requestToDelete);

        // 2. Decrement both connection counts
        final myUserRef = _firestore.collection('users').doc(currentUserId);
        batch.update(myUserRef, {'connections': FieldValue.increment(-1)});

        final theirUserRef = _firestore.collection('users').doc(userId);
        batch.update(theirUserRef, {'connections': FieldValue.increment(-1)});

        // 3. Delete from both sub-collections
        batch.delete(myUserRef.collection('connections').doc(userId));
        batch.delete(theirUserRef.collection('connections').doc(currentUserId));

        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error removing connection: $e');
      Get.snackbar(
        'Error',
        'Failed to remove connection.',
        backgroundColor: NexoraColors.error.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  // No longer needed
}
