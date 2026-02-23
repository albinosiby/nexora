import 'package:get/get.dart';

/// DummyDatabase - Acts as Firebase/Backend mock database
/// All data is stored here and accessed through repositories
class DummyDatabase extends GetxService {
  static DummyDatabase get instance => Get.find<DummyDatabase>();

  // ========== CURRENT USER ==========
  final Rx<UserData> currentUser = UserData(
    id: 'current_user_001',
    name: 'Alex Chen',
    email: 'alex.chen@university.edu',
    avatar:
        'https://api.dicebear.com/7.x/avataaars/png?seed=AlexChen&backgroundColor=transparent',
    bio: 'Full-stack developer 💻 | Hackathon enthusiast 🚀 | Coffee addict ☕',
    year: '3rd Year',
    major: 'Computer Science',
    age: 21,
    isOnline: true,
    isVerified: true,
    connections: 156,
    interests: ['Coding', 'Gaming', 'Music', 'Coffee', 'Hackathons'],
    instagram: '@alexchen_dev',
    spotify: 'spotify:track:4cOdK2wGLETKBW3PvgPWqT',
    spotifyTrackName: 'Blinding Lights',
    spotifyArtist: 'The Weeknd',
    lookingFor: 'Study partners & friends who love tech',
    photos: [
      'https://api.dicebear.com/7.x/avataaars/png?seed=Alex1',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Alex2',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Alex3',
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 180)),
  ).obs;

  // ========== USERS DATABASE ==========
  final RxList<UserData> users = <UserData>[
    UserData(
      id: 'user_001',
      name: 'Sarah Johnson',
      email: 'sarah.j@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=SarahJohnson&backgroundColor=transparent',
      bio: 'Marketing enthusiast | Book lover | Yoga everyday 🧘‍♀️',
      year: '2nd Year',
      major: 'Business',
      age: 20,
      isOnline: true,
      isVerified: true,
      connections: 243,
      interests: ['Marketing', 'Reading', 'Travel', 'Yoga'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    UserData(
      id: 'user_002',
      name: 'Mike Rodriguez',
      email: 'mike.r@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=MikeRodriguez&backgroundColor=transparent',
      bio: 'Robotics club president | F1 fan | Gym rat 💪',
      year: '4th Year',
      major: 'Engineering',
      age: 22,
      isOnline: false,
      isVerified: true,
      connections: 89,
      interests: ['Robotics', 'Sports', 'Fitness', 'F1'],
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    UserData(
      id: 'user_003',
      name: 'Emily Watson',
      email: 'emily.w@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=EmilyWatson&backgroundColor=transparent',
      bio: 'Mental health advocate | Cat mom | Coffee lover 🐱',
      year: '2nd Year',
      major: 'Psychology',
      age: 20,
      isOnline: true,
      isVerified: true,
      connections: 312,
      interests: ['Psychology', 'Art', 'Cats', 'Coffee'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
    UserData(
      id: 'user_004',
      name: 'James Wilson',
      email: 'james.w@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=JamesWilson&backgroundColor=transparent',
      bio: 'Future doctor | Chess enthusiast | Tea over coffee 🍵',
      year: '4th Year',
      major: 'Medicine',
      age: 23,
      isOnline: true,
      isVerified: true,
      connections: 178,
      interests: ['Medicine', 'Chess', 'Running', 'Tea'],
      lastActive: DateTime.now(),
    ),
    UserData(
      id: 'user_005',
      name: 'Priya Sharma',
      email: 'priya.s@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=PriyaSharma&backgroundColor=transparent',
      bio: 'ML enthusiast | Dancer | Foodie 🍕',
      year: '1st Year',
      major: 'Data Science',
      age: 19,
      isOnline: false,
      isVerified: false,
      connections: 67,
      interests: ['AI', 'Dancing', 'Photography', 'Food'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    UserData(
      id: 'user_006',
      name: 'David Kim',
      email: 'david.k@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=DavidKim&backgroundColor=transparent',
      bio: 'Crypto trader | Basketball | Night owl 🦉',
      year: '3rd Year',
      major: 'Finance',
      age: 21,
      isOnline: true,
      isVerified: true,
      connections: 198,
      interests: ['Finance', 'Basketball', 'Gaming', 'Crypto'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    UserData(
      id: 'user_007',
      name: 'Olivia Martinez',
      email: 'olivia.m@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=OliviaMartinez&backgroundColor=transparent',
      bio: 'Design lover | Piano player | Coffee snob ☕',
      year: '4th Year',
      major: 'Architecture',
      age: 22,
      isOnline: false,
      isVerified: true,
      connections: 145,
      interests: ['Design', 'Music', 'Art', 'Coffee'],
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    UserData(
      id: 'user_008',
      name: 'Ryan Thompson',
      email: 'ryan.t@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=RyanThompson&backgroundColor=transparent',
      bio: 'Social media guru | Gym everyday | Dog dad 🐕',
      year: '2nd Year',
      major: 'Marketing',
      age: 20,
      isOnline: true,
      isVerified: true,
      connections: 234,
      interests: ['Marketing', 'Fitness', 'Photography', 'Dogs'],
      lastActive: DateTime.now(),
    ),
    UserData(
      id: 'user_009',
      name: 'Sophia Lee',
      email: 'sophia.l@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=SophiaLee&backgroundColor=transparent',
      bio: 'Pre-med student | K-pop fan | Boba addict 🧋',
      year: '3rd Year',
      major: 'Biology',
      age: 21,
      isOnline: true,
      isVerified: true,
      connections: 287,
      interests: ['Science', 'Music', 'Cooking', 'K-pop'],
      lastActive: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    UserData(
      id: 'user_010',
      name: 'Nathan Brooks',
      email: 'nathan.b@university.edu',
      avatar:
          'https://api.dicebear.com/7.x/avataaars/png?seed=NathanBrooks&backgroundColor=transparent',
      bio: 'Freshman exploring | Music producer | Sneakerhead 👟',
      year: '1st Year',
      major: 'Music Production',
      age: 18,
      isOnline: false,
      isVerified: false,
      connections: 45,
      interests: ['Music', 'Fashion', 'Gaming', 'Sneakers'],
      lastActive: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ].obs;

  // ========== CHATS DATABASE ==========
  final RxList<ChatData> chats = <ChatData>[
    ChatData(
      id: 'chat_001',
      participantIds: ['current_user_001', 'user_001'],
      lastMessage: 'See you at the library!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      isTyping: false,
    ),
    ChatData(
      id: 'chat_002',
      participantIds: ['current_user_001', 'user_003'],
      lastMessage: 'That sounds great! 😊',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 0,
      isTyping: true,
    ),
    ChatData(
      id: 'chat_003',
      participantIds: ['current_user_001', 'user_004'],
      lastMessage: 'Chess match tomorrow?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 1,
      isTyping: false,
    ),
    ChatData(
      id: 'chat_004',
      participantIds: ['current_user_001', 'user_006'],
      lastMessage: 'Check out this new crypto!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      isTyping: false,
    ),
    ChatData(
      id: 'chat_005',
      participantIds: ['current_user_001', 'user_009'],
      lastMessage: 'The study group was helpful',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isTyping: false,
    ),
  ].obs;

  // ========== MESSAGES DATABASE ==========
  final RxList<MessageData> messages = <MessageData>[
    // Chat with Sarah
    MessageData(
      id: 'msg_001',
      chatId: 'chat_001',
      senderId: 'user_001',
      content: 'Hey Alex! Are you coming to the study session?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: true,
    ),
    MessageData(
      id: 'msg_002',
      chatId: 'chat_001',
      senderId: 'current_user_001',
      content: 'Yes! I\'ll be there in 20 mins',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      isRead: true,
    ),
    MessageData(
      id: 'msg_003',
      chatId: 'chat_001',
      senderId: 'user_001',
      content: 'Perfect! I\'ll save you a seat',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      isRead: true,
    ),
    MessageData(
      id: 'msg_004',
      chatId: 'chat_001',
      senderId: 'user_001',
      content: 'See you at the library!',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    // Chat with Emily
    MessageData(
      id: 'msg_005',
      chatId: 'chat_002',
      senderId: 'current_user_001',
      content: 'Want to grab coffee later?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: true,
    ),
    MessageData(
      id: 'msg_006',
      chatId: 'chat_002',
      senderId: 'user_003',
      content: 'That sounds great! 😊',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: true,
    ),
  ].obs;

  // ========== STORIES DATABASE ==========
  final RxList<StoryData> stories = <StoryData>[
    StoryData(
      id: 'story_001',
      userId: 'user_001',
      mediaUrl: 'https://picsum.photos/400/700?random=1',
      type: StoryType.image,
      caption: 'Beautiful sunset! 🌅',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      viewerIds: ['current_user_001', 'user_002', 'user_003'],
      likeIds: ['user_002'],
    ),
    StoryData(
      id: 'story_002',
      userId: 'user_001',
      mediaUrl: 'https://picsum.photos/400/700?random=2',
      type: StoryType.image,
      caption: 'Study vibes 📚',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      viewerIds: ['current_user_001'],
      likeIds: [],
    ),
    StoryData(
      id: 'story_003',
      userId: 'user_003',
      mediaUrl: 'https://picsum.photos/400/700?random=3',
      type: StoryType.image,
      caption: 'Coffee time ☕',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      viewerIds: [],
      likeIds: [],
    ),
    StoryData(
      id: 'story_004',
      userId: 'user_006',
      mediaUrl: 'https://picsum.photos/400/700?random=4',
      type: StoryType.image,
      caption: 'Game night! 🎮',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      viewerIds: ['current_user_001', 'user_001'],
      likeIds: ['current_user_001'],
    ),
    StoryData(
      id: 'story_005',
      userId: 'user_009',
      mediaUrl: 'https://picsum.photos/400/700?random=5',
      type: StoryType.image,
      caption: 'Lab day 🧪',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      viewerIds: [],
      likeIds: [],
    ),
  ].obs;

  // ========== CONNECTIONS DATABASE ==========
  final RxList<ConnectionData> connections = <ConnectionData>[
    ConnectionData(
      id: 'conn_001',
      userId1: 'current_user_001',
      userId2: 'user_001',
      status: ConnectionStatus.connected,
      timestamp: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ConnectionData(
      id: 'conn_002',
      userId1: 'current_user_001',
      userId2: 'user_003',
      status: ConnectionStatus.connected,
      timestamp: DateTime.now().subtract(const Duration(days: 15)),
    ),
    // Incoming requests
    ConnectionData(
      id: 'conn_003',
      userId1: 'user_004',
      userId2: 'current_user_001',
      status: ConnectionStatus.pending,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ConnectionData(
      id: 'conn_004',
      userId1: 'user_006',
      userId2: 'current_user_001',
      status: ConnectionStatus.pending,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ConnectionData(
      id: 'conn_005',
      userId1: 'user_009',
      userId2: 'current_user_001',
      status: ConnectionStatus.pending,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ].obs;

  // ========== NOTIFICATIONS DATABASE ==========
  final RxList<NotificationData> notifications = <NotificationData>[
    NotificationData(
      id: 'notif_001',
      type: NotificationType.like,
      userId: 'user_001',
      message: 'liked your post',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
    ),
    NotificationData(
      id: 'notif_002',
      type: NotificationType.comment,
      userId: 'user_002',
      message: 'commented on your photo',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    NotificationData(
      id: 'notif_003',
      type: NotificationType.follow,
      userId: 'user_003',
      message: 'started following you',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationData(
      id: 'notif_004',
      type: NotificationType.match,
      userId: 'user_004',
      message: 'You have a new match!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    NotificationData(
      id: 'notif_005',
      type: NotificationType.event,
      userId: 'system',
      message: 'Hackathon 2026 starts tomorrow',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
  ].obs;

  // ========== POSTS/FEED DATABASE ==========
  final RxList<PostData> posts = <PostData>[
    PostData(
      id: 'post_001',
      userId: 'user_001',
      content: 'Just finished my final project! 🎉',
      imageUrl: 'https://picsum.photos/400/300?random=10',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      likeIds: ['current_user_001', 'user_002', 'user_003'],
      commentCount: 5,
    ),
    PostData(
      id: 'post_002',
      userId: 'user_003',
      content: 'Mental health matters. Take care of yourselves! 💚',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      likeIds: ['current_user_001', 'user_001', 'user_004', 'user_005'],
      commentCount: 12,
    ),
    PostData(
      id: 'post_003',
      userId: 'user_006',
      content: 'Bitcoin hitting new highs! Who\'s holding? 📈',
      imageUrl: 'https://picsum.photos/400/300?random=11',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      likeIds: ['user_002'],
      commentCount: 8,
    ),
  ].obs;

  // ========== HELPER METHODS ==========

  /// Get user by ID
  UserData? getUserById(String userId) {
    if (userId == 'current_user_001') return currentUser.value;
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  /// Get user by phone number
  UserData? getUserByPhone(String phone) {
    try {
      return users.firstWhere((u) => u.phone == phone);
    } catch (_) {
      // Also check current user
      if (currentUser.value.phone == phone) return currentUser.value;
      return null;
    }
  }

  /// Create a new user and set as current user
  UserData createUser({
    required String name,
    required String phone,
    required String username,
    required DateTime dateOfBirth,
    required String gender,
    required bool isVjecStudent,
    String bio = '',
    String department = '',
  }) {
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserData(
      id: userId,
      name: name,
      username: username,
      email: '$username@nexora.app',
      phone: phone,
      avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=$username',
      bio: bio,
      year: '',
      major: department.isNotEmpty
          ? department
          : (isVjecStudent ? 'VJEC Student' : ''),
      age: _calculateAge(dateOfBirth),
      gender: gender,
      dateOfBirth: dateOfBirth,
      isVjecStudent: isVjecStudent,
      isOnline: true,
      isVerified: false,
      connections: 0,
      interests: [],
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    // Set as current user
    currentUser.value = newUser;

    // Also add to users list
    users.add(newUser);

    return newUser;
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Get all users except current user
  List<UserData> getAllUsersExceptCurrent() {
    return users.toList();
  }

  /// Get chat by ID
  ChatData? getChatById(String chatId) {
    try {
      return chats.firstWhere((c) => c.id == chatId);
    } catch (_) {
      return null;
    }
  }

  /// Get chat between two users
  ChatData? getChatBetweenUsers(String userId1, String userId2) {
    try {
      return chats.firstWhere(
        (c) =>
            c.participantIds.contains(userId1) &&
            c.participantIds.contains(userId2),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get messages for a chat
  List<MessageData> getMessagesForChat(String chatId) {
    return messages.where((m) => m.chatId == chatId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get stories for a user
  List<StoryData> getStoriesForUser(String userId) {
    final now = DateTime.now();
    return stories
        .where(
          (s) => s.userId == userId && now.difference(s.timestamp).inHours < 24,
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get all active stories (within 24 hours)
  List<StoryData> getAllActiveStories() {
    final now = DateTime.now();
    return stories
        .where((s) => now.difference(s.timestamp).inHours < 24)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get users with active stories
  List<UserData> getUsersWithStories() {
    final activeStories = getAllActiveStories();
    final userIds = activeStories.map((s) => s.userId).toSet();
    return users.where((u) => userIds.contains(u.id)).toList();
  }

  /// Get connection status between users
  ConnectionStatus getConnectionStatus(String userId1, String userId2) {
    try {
      final connection = connections.firstWhere(
        (c) =>
            (c.userId1 == userId1 && c.userId2 == userId2) ||
            (c.userId1 == userId2 && c.userId2 == userId1),
      );
      return connection.status;
    } catch (_) {
      return ConnectionStatus.none;
    }
  }

  /// Get incoming connection requests for current user
  List<ConnectionData> getIncomingRequests() {
    return connections
        .where(
          (c) =>
              c.userId2 == 'current_user_001' &&
              c.status == ConnectionStatus.pending,
        )
        .toList();
  }

  /// Get connected users for current user
  List<UserData> getConnectedUsers() {
    final connectedIds = connections
        .where(
          (c) =>
              c.status == ConnectionStatus.connected &&
              (c.userId1 == 'current_user_001' ||
                  c.userId2 == 'current_user_001'),
        )
        .map((c) => c.userId1 == 'current_user_001' ? c.userId2 : c.userId1)
        .toList();
    return users.where((u) => connectedIds.contains(u.id)).toList();
  }

  /// Get unread notifications count
  int getUnreadNotificationsCount() {
    return notifications.where((n) => !n.isRead).length;
  }

  /// Get total unread messages count
  int getTotalUnreadMessagesCount() {
    return chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  // ========== MUTATION METHODS ==========

  /// Send a message
  void sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    final message = MessageData(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: 'current_user_001',
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
      isRead: false,
    );
    messages.add(message);

    // Update chat's last message
    final chatIndex = chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      final chat = chats[chatIndex];
      chats[chatIndex] = ChatData(
        id: chat.id,
        participantIds: chat.participantIds,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isTyping: false,
      );
    }
  }

  /// Create a new chat
  String createChat(String otherUserId) {
    final existingChat = getChatBetweenUsers('current_user_001', otherUserId);
    if (existingChat != null) return existingChat.id;

    final chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    chats.add(
      ChatData(
        id: chatId,
        participantIds: ['current_user_001', otherUserId],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isTyping: false,
      ),
    );
    return chatId;
  }

  /// Send connection request
  void sendConnectionRequest(String toUserId) {
    final status = getConnectionStatus('current_user_001', toUserId);
    if (status != ConnectionStatus.none) return;

    connections.add(
      ConnectionData(
        id: 'conn_${DateTime.now().millisecondsSinceEpoch}',
        userId1: 'current_user_001',
        userId2: toUserId,
        status: ConnectionStatus.pending,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Accept connection request
  void acceptConnectionRequest(String fromUserId) {
    final index = connections.indexWhere(
      (c) =>
          c.userId1 == fromUserId &&
          c.userId2 == 'current_user_001' &&
          c.status == ConnectionStatus.pending,
    );

    if (index != -1) {
      final conn = connections[index];
      connections[index] = ConnectionData(
        id: conn.id,
        userId1: conn.userId1,
        userId2: conn.userId2,
        status: ConnectionStatus.connected,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Reject connection request
  void rejectConnectionRequest(String fromUserId) {
    connections.removeWhere(
      (c) =>
          c.userId1 == fromUserId &&
          c.userId2 == 'current_user_001' &&
          c.status == ConnectionStatus.pending,
    );
  }

  /// Remove connection
  void removeConnection(String otherUserId) {
    connections.removeWhere(
      (c) =>
          c.status == ConnectionStatus.connected &&
          ((c.userId1 == 'current_user_001' && c.userId2 == otherUserId) ||
              (c.userId1 == otherUserId && c.userId2 == 'current_user_001')),
    );
  }

  /// Add story
  void addStory({
    required String mediaUrl,
    StoryType type = StoryType.image,
    String? caption,
  }) {
    stories.add(
      StoryData(
        id: 'story_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user_001',
        mediaUrl: mediaUrl,
        type: type,
        caption: caption,
        timestamp: DateTime.now(),
        viewerIds: [],
        likeIds: [],
      ),
    );
  }

  /// Mark story as viewed
  void viewStory(String storyId) {
    final index = stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final story = stories[index];
      if (!story.viewerIds.contains('current_user_001')) {
        stories[index] = StoryData(
          id: story.id,
          userId: story.userId,
          mediaUrl: story.mediaUrl,
          type: story.type,
          caption: story.caption,
          timestamp: story.timestamp,
          viewerIds: [...story.viewerIds, 'current_user_001'],
          likeIds: story.likeIds,
        );
      }
    }
  }

  /// Mark notification as read
  void markNotificationAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notif = notifications[index];
      notifications[index] = NotificationData(
        id: notif.id,
        type: notif.type,
        userId: notif.userId,
        message: notif.message,
        timestamp: notif.timestamp,
        isRead: true,
      );
    }
  }

  /// Mark all notifications as read
  void markAllNotificationsAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      final notif = notifications[i];
      if (!notif.isRead) {
        notifications[i] = NotificationData(
          id: notif.id,
          type: notif.type,
          userId: notif.userId,
          message: notif.message,
          timestamp: notif.timestamp,
          isRead: true,
        );
      }
    }
  }

  /// Update current user profile
  void updateCurrentUserProfile({
    String? name,
    String? bio,
    String? year,
    String? major,
    List<String>? interests,
    String? instagram,
    String? spotify,
    String? lookingFor,
  }) {
    final user = currentUser.value;
    currentUser.value = UserData(
      id: user.id,
      name: name ?? user.name,
      email: user.email,
      avatar: user.avatar,
      bio: bio ?? user.bio,
      year: year ?? user.year,
      major: major ?? user.major,
      age: user.age,
      isOnline: user.isOnline,
      isVerified: user.isVerified,
      connections: user.connections,
      interests: interests ?? user.interests,
      instagram: instagram ?? user.instagram,
      spotify: spotify ?? user.spotify,
      spotifyTrackName: user.spotifyTrackName,
      spotifyArtist: user.spotifyArtist,
      lookingFor: lookingFor ?? user.lookingFor,
      photos: user.photos,
      createdAt: user.createdAt,
      lastActive: DateTime.now(),
    );
  }

  /// Toggle like on a post
  void togglePostLike(String postId) {
    final userId = currentUser.value.id;
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    final newLikeIds = List<String>.from(post.likeIds);

    if (newLikeIds.contains(userId)) {
      newLikeIds.remove(userId);
    } else {
      newLikeIds.add(userId);
    }

    posts[index] = post.copyWith(likeIds: newLikeIds);
  }

  /// Toggle save on a post (local only for now)
  final RxMap<String, bool> savedPosts = <String, bool>{}.obs;

  void toggleSavePost(String postId) {
    savedPosts[postId] = !(savedPosts[postId] ?? false);
  }

  bool isPostSaved(String postId) => savedPosts[postId] ?? false;
}

// ========== DATA MODELS ==========

class UserData {
  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String avatar;
  final String bio;
  final String year;
  final String major;
  final int age;
  final String? gender;
  final DateTime? dateOfBirth;
  final bool isVjecStudent;
  final bool isOnline;
  final bool isVerified;
  final int connections;
  final List<String> interests;
  final String? instagram;
  final String? spotify;
  final String? spotifyTrackName;
  final String? spotifyArtist;
  final String? lookingFor;
  final List<String>? photos;
  final DateTime? createdAt;
  final DateTime? lastActive;

  UserData({
    required this.id,
    required this.name,
    this.username = '',
    required this.email,
    this.phone = '',
    required this.avatar,
    this.bio = '',
    this.year = '',
    this.major = '',
    this.age = 18,
    this.gender,
    this.dateOfBirth,
    this.isVjecStudent = false,
    this.isOnline = false,
    this.isVerified = false,
    this.connections = 0,
    this.interests = const [],
    this.instagram,
    this.spotify,
    this.spotifyTrackName,
    this.spotifyArtist,
    this.lookingFor,
    this.photos,
    this.createdAt,
    this.lastActive,
  });

  /// Returns the display name for public viewing (username if available, otherwise derived from name)
  String get displayName =>
      username.isNotEmpty ? username : name.toLowerCase().replaceAll(' ', '.');
}

class ChatData {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isTyping;

  ChatData({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isTyping = false,
  });
}

class MessageData {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isRead;

  MessageData({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
  });
}

enum MessageType { text, image, voice, video, file }

class StoryData {
  final String id;
  final String userId;
  final String mediaUrl;
  final StoryType type;
  final String? caption;
  final DateTime timestamp;
  final List<String> viewerIds;
  final List<String> likeIds;

  StoryData({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.type,
    this.caption,
    required this.timestamp,
    this.viewerIds = const [],
    this.likeIds = const [],
  });
}

enum StoryType { image, video, text }

class ConnectionData {
  final String id;
  final String userId1;
  final String userId2;
  final ConnectionStatus status;
  final DateTime timestamp;

  ConnectionData({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.timestamp,
  });
}

enum ConnectionStatus { none, pending, connected, blocked }

class NotificationData {
  final String id;
  final NotificationType type;
  final String userId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  NotificationData({
    required this.id,
    required this.type,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

enum NotificationType {
  like,
  comment,
  follow,
  match,
  event,
  mention,
  connectionRequest,
}

class PostData {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final List<String> likeIds;
  final int commentCount;

  PostData({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.likeIds = const [],
    this.commentCount = 0,
  });

  PostData copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    DateTime? timestamp,
    List<String>? likeIds,
    int? commentCount,
  }) {
    return PostData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      likeIds: likeIds ?? this.likeIds,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}
