import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../auth/repositories/auth_repository.dart';

class ChatRepository extends GetxService {
  static ChatRepository get instance => Get.find<ChatRepository>();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _auth = AuthRepository.instance;

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
          conversations.add(
            ChatModel.fromJson(
              Map<String, dynamic>.from(chatDoc.value as Map),
              chatId,
            ),
          );
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

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? duration,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
  }) async {
    if (currentUserId == null) return;

    final messageRef = _db.ref('messages/$chatId').push();
    final messageId = messageRef.key!;

    final message = MessageModel(
      id: messageId,
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
    });

    // Update User Chats (for sorting and unread counts)
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

  /// Create new chat
  Future<String> createChat(String otherUserId) async {
    if (currentUserId == null) return '';

    // Check if chat already exists
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

  /// Add or remove a reaction on a message
  Future<void> addReaction(
    String chatId,
    String messageId,
    String? reaction,
  ) async {
    await _db.ref('messages/$chatId/$messageId/reaction').set(reaction);
  }
}
