import 'package:get/get.dart';

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

  // Map of userId -> ConnectionStatus
  final RxMap<String, ConnectionStatus> _connectionStatuses =
      <String, ConnectionStatus>{}.obs;

  // List of connection requests (incoming)
  final RxList<ConnectionRequest> _incomingRequests = <ConnectionRequest>[].obs;

  // List of sent requests (pending)
  final RxList<ConnectionRequest> _sentRequests = <ConnectionRequest>[].obs;

  // List of connected users
  final RxList<ConnectionRequest> _connections = <ConnectionRequest>[].obs;

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
  }) {
    if (_connectionStatuses[userId] == ConnectionStatus.none ||
        _connectionStatuses[userId] == null) {
      final request = ConnectionRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: name,
        avatar: avatar,
        major: major,
        year: year,
        timestamp: DateTime.now(),
        isIncoming: false,
      );

      _sentRequests.add(request);
      _connectionStatuses[userId] = ConnectionStatus.pending;

      // Simulate receiving a response after a delay (for demo purposes)
      // In real app, this would be handled by backend
    }
  }

  // Accept incoming request
  void acceptRequest(String userId) {
    final requestIndex = _incomingRequests.indexWhere(
      (r) => r.userId == userId,
    );
    if (requestIndex != -1) {
      final request = _incomingRequests[requestIndex];
      _incomingRequests.removeAt(requestIndex);

      // Add to connections
      _connections.add(
        ConnectionRequest(
          id: request.id,
          userId: request.userId,
          name: request.name,
          avatar: request.avatar,
          major: request.major,
          year: request.year,
          timestamp: DateTime.now(),
          isIncoming: false,
        ),
      );

      _connectionStatuses[userId] = ConnectionStatus.connected;
    }
  }

  // Reject/decline incoming request
  void rejectRequest(String userId) {
    _incomingRequests.removeWhere((r) => r.userId == userId);
    _connectionStatuses[userId] = ConnectionStatus.none;
  }

  // Cancel sent request
  void cancelRequest(String userId) {
    _sentRequests.removeWhere((r) => r.userId == userId);
    _connectionStatuses[userId] = ConnectionStatus.none;
  }

  // Remove connection
  void removeConnection(String userId) {
    _connections.removeWhere((r) => r.userId == userId);
    _connectionStatuses[userId] = ConnectionStatus.none;
  }

  // Initialize with some mock data for demo
  void initMockData() {
    // Add some incoming requests
    _incomingRequests.addAll([
      ConnectionRequest(
        id: '1',
        userId: 'sarah_johnson',
        name: 'sarah.johnson',
        avatar:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Sarah%20Johnson&backgroundColor=transparent',
        major: 'Business',
        year: '2nd Year',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isIncoming: true,
      ),
      ConnectionRequest(
        id: '2',
        userId: 'mike_rodriguez',
        name: 'mike.rodriguez',
        avatar:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Mike%20Rodriguez&backgroundColor=transparent',
        major: 'Engineering',
        year: '4th Year',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isIncoming: true,
      ),
      ConnectionRequest(
        id: '3',
        userId: 'emily_watson',
        name: 'emily.watson',
        avatar:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Emily%20Watson&backgroundColor=transparent',
        major: 'Psychology',
        year: '2nd Year',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isIncoming: true,
      ),
    ]);

    // Set statuses for incoming requests
    for (var request in _incomingRequests) {
      _connectionStatuses[request.userId] = ConnectionStatus.incoming;
    }

    // Add some existing connections
    _connections.addAll([
      ConnectionRequest(
        id: '4',
        userId: 'james_wilson',
        name: 'james.wilson',
        avatar:
            'https://api.dicebear.com/7.x/avataaars/png?seed=James%20Wilson&backgroundColor=transparent',
        major: 'Medicine',
        year: '4th Year',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        isIncoming: false,
      ),
      ConnectionRequest(
        id: '5',
        userId: 'priya_sharma',
        name: 'priya.sharma',
        avatar:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Priya%20Sharma&backgroundColor=transparent',
        major: 'Data Science',
        year: '1st Year',
        timestamp: DateTime.now().subtract(const Duration(days: 14)),
        isIncoming: false,
      ),
    ]);

    // Set statuses for connections
    for (var conn in _connections) {
      _connectionStatuses[conn.userId] = ConnectionStatus.connected;
    }
  }
}
