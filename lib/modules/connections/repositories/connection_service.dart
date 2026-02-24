import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/repositories/auth_repository.dart';

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
  final String avatar;
  final String major;
  final String year;
  final DateTime timestamp;
  final bool
  isIncoming; // true = they requested you, false = you requested them

  ConnectionRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.major,
    required this.year,
    required this.timestamp,
    required this.isIncoming,
  });
}

class ConnectionService extends GetxController {
  static ConnectionService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _auth = AuthRepository.instance;

  // Map of userId -> ConnectionStatus
  final RxMap<String, ConnectionStatus> _connectionStatuses =
      <String, ConnectionStatus>{}.obs;

  // List of connection requests (incoming)
  final RxList<ConnectionRequest> _incomingRequests = <ConnectionRequest>[].obs;

  // List of sent requests (pending)
  final RxList<ConnectionRequest> _sentRequests = <ConnectionRequest>[].obs;

  // List of connected users
  final RxList<ConnectionRequest> _connections = <ConnectionRequest>[].obs;

  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;

  @override
  void onInit() {
    super.onInit();
    _setupFirestoreListeners();
  }

  @override
  void onClose() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    super.onClose();
  }

  void _setupFirestoreListeners() {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    // Listen for incoming requests
    _incomingSub = _firestore
        .collection('connection_requests')
        .where('toId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            return ConnectionRequest(
              id: doc.id,
              userId: data['fromId'],
              name: data['fromName'],
              avatar: data['fromAvatar'],
              major: data['fromMajor'] ?? '',
              year: data['fromYear'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isIncoming: true,
            );
          }).toList();

          _incomingRequests.assignAll(requests);
          for (var r in requests) {
            _connectionStatuses[r.userId] = ConnectionStatus.incoming;
          }
        });

    // Listen for accepted requests where I am the sender
    _firestore
        .collection('connection_requests')
        .where('fromId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
          _updateConnectionsList(snapshot, currentUserId, true);
        });

    // Listen for accepted requests where I am the recipient
    _firestore
        .collection('connection_requests')
        .where('toId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
          _updateConnectionsList(snapshot, currentUserId, false);
        });

    // Listen for pending sent requests
    _firestore
        .collection('connection_requests')
        .where('fromId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          final sent = snapshot.docs.map((doc) {
            final data = doc.data();
            return ConnectionRequest(
              id: doc.id,
              userId: data['toId'],
              name: data['toName'] ?? 'Pending...',
              avatar: data['toAvatar'] ?? '',
              major: data['toMajor'] ?? '',
              year: data['toYear'] ?? '',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isIncoming: false,
            );
          }).toList();

          _sentRequests.assignAll(sent);
          for (var s in sent) {
            _connectionStatuses[s.userId] = ConnectionStatus.pending;
          }
        });
  }

  // Getters
  Map<String, ConnectionStatus> get statuses => _connectionStatuses;
  List<ConnectionRequest> get incomingRequests => _incomingRequests;
  List<ConnectionRequest> get sentRequests => _sentRequests;
  List<ConnectionRequest> get connections => _connections;
  int get incomingCount => _incomingRequests.length;

  // Get status for a specific user
  ConnectionStatus getStatus(String userId) {
    return _connectionStatuses[userId] ?? ConnectionStatus.none;
  }

  // Send connection request
  void sendRequest({
    required String userId,
    required String name,
    required String avatar,
    required String major,
    required String year,
  }) async {
    final currentUserId = _auth.user?.uid;
    final currentUser = _auth.currentUserProfile;
    if (currentUserId == null || currentUser == null) return;

    if (_connectionStatuses[userId] == ConnectionStatus.none ||
        _connectionStatuses[userId] == null) {
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

      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .set(requestData);

      _connectionStatuses[userId] = ConnectionStatus.pending;
    }
  }

  void _updateConnectionsList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
    bool isSender,
  ) {
    for (var change in snapshot.docChanges) {
      final doc = change.doc;
      final data = doc.data();
      if (data == null) continue;

      final otherId = isSender ? data['toId'] : data['fromId'];

      if (change.type == DocumentChangeType.removed) {
        _connections.removeWhere((c) => c.userId == otherId);
        _connectionStatuses.remove(otherId);
        continue;
      }

      final otherName = isSender ? data['toName'] : data['fromName'];
      final otherAvatar = isSender ? data['toAvatar'] : data['fromAvatar'];
      final otherMajor = isSender ? data['toMajor'] : data['fromMajor'];
      final otherYear = isSender ? data['toYear'] : data['fromYear'];

      final conn = ConnectionRequest(
        id: doc.id,
        userId: otherId,
        name: otherName ?? 'Someone',
        avatar: otherAvatar ?? '',
        major: otherMajor ?? '',
        year: otherYear ?? '',
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isIncoming: false,
      );

      final index = _connections.indexWhere((c) => c.userId == otherId);
      if (index != -1) {
        if (change.type == DocumentChangeType.modified) {
          _connections[index] = conn;
        }
      } else if (change.type == DocumentChangeType.added ||
          change.type == DocumentChangeType.modified) {
        _connections.add(conn);
      }
      _connectionStatuses[otherId] = ConnectionStatus.connected;
    }
  }

  // Add an incoming connection request (removed as it was only for mock demo)

  // Accept incoming request
  void acceptRequest(String userId) async {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    final requestId = '${userId}_$currentUserId';
    await _firestore.collection('connection_requests').doc(requestId).update({
      'status': 'accepted',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Reject/decline incoming request
  void rejectRequest(String userId) async {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    final requestId = '${userId}_$currentUserId';
    await _firestore.collection('connection_requests').doc(requestId).delete();
    _connectionStatuses[userId] = ConnectionStatus.none;
  }

  // Cancel sent request
  void cancelRequest(String userId) async {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    final requestId = '${currentUserId}_$userId';
    await _firestore.collection('connection_requests').doc(requestId).delete();
    _connectionStatuses[userId] = ConnectionStatus.none;
  }

  // Remove connection
  void removeConnection(String userId) async {
    final currentUserId = _auth.user?.uid;
    if (currentUserId == null) return;

    // Can be either way
    final req1 = '${currentUserId}_$userId';
    final req2 = '${userId}_$currentUserId';

    final doc1 = await _firestore
        .collection('connection_requests')
        .doc(req1)
        .get();
    if (doc1.exists) {
      await doc1.reference.delete();
    } else {
      await _firestore.collection('connection_requests').doc(req2).delete();
    }

    _connectionStatuses[userId] = ConnectionStatus.none;
  }

  // No longer needed
}
