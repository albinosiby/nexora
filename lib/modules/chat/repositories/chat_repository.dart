import 'package:get/get.dart';
import '../../../core/services/dummy_database.dart';

/// ChatRepository - Handles all chat/message operations
/// Abstracts DummyDatabase access for chat-related data
class ChatRepository {
  final DummyDatabase _db = DummyDatabase.instance;

  /// Get all chats for current user
  List<ChatData> getAllChats() {
    return _db.chats
        .where((c) => c.participantIds.contains('current_user_001'))
        .toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }

  /// Get chats as observable list
  RxList<ChatData> get chatsRx => _db.chats;

  /// Get chat by ID
  ChatData? getChatById(String chatId) => _db.getChatById(chatId);

  /// Get chat between two users
  ChatData? getChatWithUser(String otherUserId) {
    return _db.getChatBetweenUsers('current_user_001', otherUserId);
  }

  /// Get messages for a chat
  List<MessageData> getMessages(String chatId) => _db.getMessagesForChat(chatId);

  /// Get messages as observable
  RxList<MessageData> get messagesRx => _db.messages;

  /// Send text message
  void sendTextMessage(String chatId, String content) {
    _db.sendMessage(
      chatId: chatId,
      content: content,
      type: MessageType.text,
    );
  }

  /// Send image message
  void sendImageMessage(String chatId, String imageUrl, {String? caption}) {
    _db.sendMessage(
      chatId: chatId,
      content: caption ?? 'Photo',
      type: MessageType.image,
      mediaUrl: imageUrl,
    );
  }

  /// Send voice message
  void sendVoiceMessage(String chatId, String audioUrl, String duration) {
    _db.sendMessage(
      chatId: chatId,
      content: 'Voice message ($duration)',
      type: MessageType.voice,
      mediaUrl: audioUrl,
    );
  }

  /// Create or get existing chat with user
  String getOrCreateChat(String otherUserId) {
    return _db.createChat(otherUserId);
  }

  /// Get total unread count
  int getTotalUnreadCount() => _db.getTotalUnreadMessagesCount();

  /// Get unread count for specific chat
  int getUnreadCount(String chatId) {
    final chat = _db.getChatById(chatId);
    return chat?.unreadCount ?? 0;
  }

  /// Mark chat as read
  void markChatAsRead(String chatId) {
    final index = _db.chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final chat = _db.chats[index];
      _db.chats[index] = ChatData(
        id: chat.id,
        participantIds: chat.participantIds,
        lastMessage: chat.lastMessage,
        lastMessageTime: chat.lastMessageTime,
        unreadCount: 0,
        isTyping: chat.isTyping,
      );
    }
  }

  /// Get other participant in chat
  UserData? getOtherParticipant(String chatId) {
    final chat = _db.getChatById(chatId);
    if (chat == null) return null;
    
    final otherUserId = chat.participantIds.firstWhere(
      (id) => id != 'current_user_001',
      orElse: () => '',
    );
    return _db.getUserById(otherUserId);
  }
}
