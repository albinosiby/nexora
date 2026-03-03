import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../auth/repositories/auth_repository.dart';

class ChatRepository {
  static final ChatRepository instance = ChatRepository();

  final FirebaseDatabase _db;
  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  ChatRepository({
    FirebaseDatabase? firebaseDatabase,
    FirebaseFirestore? firebaseFirestore,
    AuthRepository? authRepository,
  }) : _db = firebaseDatabase ?? FirebaseDatabase.instance,
       _firestore = firebaseFirestore ?? FirebaseFirestore.instance,
       _auth = authRepository ?? AuthRepository.instance;

  String? get currentUserId => _auth.user?.uid;

  /// Get real-time streams of chats for current user
  Stream<List<ChatModel>> getConversations() {
    if (currentUserId == null) return const Stream.empty();

    final userChatsRef = _db.ref('user_chats/$currentUserId');
    return userChatsRef.onValue.asyncMap((event) async {
      final List<ChatModel> conversations = [];
      if (event.snapshot.value == null) return conversations;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      for (var entry in data.entries) {
        final chatId = entry.key;
        final chatDoc = await _db.ref('chats/$chatId').get();
        if (chatDoc.exists) {
          final chatData = Map<String, dynamic>.from(chatDoc.value as Map);

          // Merge unreadCount from user_chats entry
          final userChatData = Map<String, dynamic>.from(entry.value as Map);
          final unreadCount = userChatData['unreadCount'] ?? 0;

          // ChatModel expects unreadCounts map
          chatData['unreadCounts'] = {currentUserId!: unreadCount};

          conversations.add(ChatModel.fromJson(chatData, chatId));
        }
      }
      conversations.sort(
        (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
      );
      return conversations;
    });
  }

  /// Get messages for a chat as a stream
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _db.ref('messages/$chatId').onValue.map((event) {
      final List<MessageModel> messages = [];
      if (event.snapshot.value == null) return messages;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      data.forEach((id, value) {
        messages.add(
          MessageModel.fromJson(Map<String, dynamic>.from(value as Map), id),
        );
      });
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Get unread message count for a specific chat
  Stream<int> getUnreadCount(String chatId) {
    if (currentUserId == null) return Stream.value(0);
    return _db
        .ref('user_chats/$currentUserId/$chatId/unreadCount')
        .onValue
        .map((event) => (event.snapshot.value as int?) ?? 0);
  }

  /// Send a message
  Future<String> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? duration,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? messageId,
  }) async {
    if (currentUserId == null) return '';

    final DatabaseReference dbRef = _db.ref('messages/$chatId');
    final messageRef = messageId != null
        ? dbRef.child(messageId)
        : dbRef.push();
    final String finalMessageId = messageId ?? messageRef.key!;

    final message = MessageModel(
      id: finalMessageId,
      chatId: chatId,
      senderId: currentUserId!,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
      duration: duration,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderId: replyToSenderId,
    );

    await messageRef.set(message.toJson());

    // Update Chat Metadata
    final chatRef = _db.ref('chats/$chatId');
    await chatRef.update({
      'lastMessage': content,
      'lastMessageTime': ServerValue.timestamp,
      'lastMessageSenderId': currentUserId,
      'lastMessageStatus': 'sent',
    });

    // Update User Chats (skip for community chat)
    if (chatId != 'community') {
      final chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        final participantIds = List<String>.from(
          chatDoc.child('participantIds').value as List,
        );
        for (var uid in participantIds) {
          final userChatRef = _db.ref('user_chats/$uid/$chatId');
          if (uid != currentUserId) {
            // Increment unread for others
            await userChatRef.child('unreadCount').runTransaction((count) {
              if (count == null) return Transaction.success(1);
              return Transaction.success((count as int) + 1);
            });
          }
          await userChatRef.update({'lastMessageTime': ServerValue.timestamp});
        }
      }
    }

    return finalMessageId;
  }

  /// Find an existing chat with another user
  Future<String?> findExistingChat(String otherUserId) async {
    if (currentUserId == null) return null;

    final userChats = await _db.ref('user_chats/$currentUserId').get();
    if (userChats.exists) {
      final data = Map<String, dynamic>.from(userChats.value as Map);
      for (var entry in data.entries) {
        final chatId = entry.key;
        final chat = await _db.ref('chats/$chatId').get();
        if (chat.exists) {
          final participants = List<String>.from(
            chat.child('participantIds').value as List,
          );
          if (participants.contains(otherUserId)) return chatId;
        }
      }
    }
    return null;
  }

  /// Create new chat
  Future<String> createChat(String otherUserId) async {
    if (currentUserId == null) return '';

    // Check if chat already exists
    final existingChatId = await findExistingChat(otherUserId);
    if (existingChatId != null) return existingChatId;

    // Create new
    final chatRef = _db.ref('chats').push();
    final chatId = chatRef.key!;

    final participantIds = [currentUserId!, otherUserId];
    await chatRef.set({
      'participantIds': participantIds,
      'lastMessage': '',
      'lastMessageTime': ServerValue.timestamp,
      'typingStatus': {for (var uid in participantIds) uid: false},
    });

    for (var uid in participantIds) {
      await _db.ref('user_chats/$uid/$chatId').set({
        'unreadCount': 0,
        'lastMessageTime': ServerValue.timestamp,
      });

      // Sync chatId to Firestore user profiles
      await _firestore.collection('users').doc(uid).update({
        'chats': FieldValue.arrayUnion([chatId]),
      });
    }

    return chatId;
  }

  /// Mark chat as read
  Future<void> markAsRead(String chatId) async {
    if (currentUserId == null) return;
    await _db.ref('user_chats/$currentUserId/$chatId/unreadCount').set(0);

    // Update messages from other participants to 'seen'
    final messagesRef = _db.ref('messages/$chatId');
    final snapshot = await messagesRef.get();
    if (snapshot.exists) {
      final updates = <String, dynamic>{};
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((id, value) {
        final msgData = Map<String, dynamic>.from(value as Map);
        if (msgData['senderId'] != currentUserId && msgData['isRead'] != true) {
          updates['$id/isRead'] = true;
          updates['$id/isDelivered'] = true;
        }
      });
      if (updates.isNotEmpty) {
        await messagesRef.update(updates);

        // If the last message was one of these, update chat status
        final chatRef = _db.ref('chats/$chatId');
        final chatSnapshot = await chatRef.get();
        if (chatSnapshot.exists) {
          final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
          if (chatData['lastMessageSenderId'] != currentUserId) {
            await chatRef.update({'lastMessageStatus': 'seen'});
          }
        }
      }
    }
  }

  /// Mark messages as delivered
  Future<void> markMessagesAsDelivered(String chatId) async {
    if (currentUserId == null) return;

    final messagesRef = _db.ref('messages/$chatId');
    final snapshot = await messagesRef.get();
    if (snapshot.exists) {
      final updates = <String, dynamic>{};
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((id, value) {
        final msgData = Map<String, dynamic>.from(value as Map);
        if (msgData['senderId'] != currentUserId &&
            msgData['isDelivered'] != true) {
          updates['$id/isDelivered'] = true;
        }
      });
      if (updates.isNotEmpty) {
        await messagesRef.update(updates);

        // Update chat status if last message was from the other user
        final chatRef = _db.ref('chats/$chatId');
        final chatSnapshot = await chatRef.get();
        if (chatSnapshot.exists) {
          final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
          if (chatData['lastMessageSenderId'] != currentUserId &&
              chatData['lastMessageStatus'] == 'sent') {
            await chatRef.update({'lastMessageStatus': 'delivered'});
          }
        }
      }
    }
  }

  /// Update typing status
  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    if (currentUserId == null) return;
    await _db.ref('chats/$chatId/typingStatus/$currentUserId').set(isTyping);
  }

  /// Get typing status for a specific user in a chat
  Stream<bool> getTypingStatus(String chatId, String userId) {
    return _db
        .ref('chats/$chatId/typingStatus/$userId')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false);
  }

  /// Get a stream of user IDs currently typing in a chat
  Stream<List<String>> getTypingUsersStream(String chatId) {
    return _db.ref('chats/$chatId/typingStatus').onValue.map((event) {
      final List<String> typingUsers = [];
      if (event.snapshot.value == null) return typingUsers;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      data.forEach((uid, isTyping) {
        if (isTyping == true && uid != currentUserId) {
          typingUsers.add(uid);
        }
      });
      return typingUsers;
    });
  }

  /// Add or remove a reaction on a message
  Future<void> addReaction(
    String chatId,
    String messageId,
    String? reaction,
  ) async {
    await _db.ref('messages/$chatId/$messageId/reaction').set(reaction);
  }

  /// Clear all messages in a chat (local user's view)
  Future<void> clearMessages(String chatId) async {
    if (currentUserId == null) return;
    await _db.ref('messages/$chatId').remove();
    // Reset last message in chat metadata
    await _db.ref('chats/$chatId').update({
      'lastMessage': '',
      'lastMessageTime': ServerValue.timestamp,
    });
  }

  /// Mute or unmute notifications for a chat
  Future<bool> toggleMuteChat(String chatId) async {
    if (currentUserId == null) return false;
    final muteRef = _db.ref('user_chats/$currentUserId/$chatId/muted');
    final snapshot = await muteRef.get();
    final isMuted = snapshot.value as bool? ?? false;
    await muteRef.set(!isMuted);
    return !isMuted;
  }

  /// Check if a chat is muted
  Future<bool> isChatMuted(String chatId) async {
    if (currentUserId == null) return false;
    final snapshot = await _db
        .ref('user_chats/$currentUserId/$chatId/muted')
        .get();
    return snapshot.value as bool? ?? false;
  }

  /// Block a user
  Future<void> blockUser(String blockedUserId) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    });
  }

  /// Report a user
  Future<void> reportUser(String reportedUserId, String reason) async {
    if (currentUserId == null) return;
    await _firestore.collection('reports').add({
      'reporterId': currentUserId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
