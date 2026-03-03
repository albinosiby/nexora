import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../../profile/repositories/user_repository.dart';
import '../../../core/services/storage_service.dart';

// Provides the ChatRepository instance
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository.instance;
});

// Provides the StorageService instance using Riverpod
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// Stream of recent chats for ChatListScreen
final recentChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getConversations();
});

// Stream of chat messages for a specific chat ID
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessagesStream(chatId);
});

// Stream of unread message count for a specific chat ID
final unreadCountProvider = StreamProvider.family<int, String>((ref, chatId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getUnreadCount(chatId);
});

// Stream of a user's presence/online status
final userPresenceProvider = StreamProvider.family<bool, String>((ref, userId) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserPresenceStream(userId);
});

// Stream to track if a specific user is typing in a specific chat
final typingStatusProvider = StreamProvider.family
    .autoDispose<bool, ({String chatId, String userId})>((ref, params) {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.getTypingStatus(params.chatId, params.userId);
    });

// Stream of all user IDs typing in a specific chat (e.g., for Community Chat)
final typingUsersProvider = StreamProvider.family
    .autoDispose<List<String>, String>((ref, chatId) {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.getTypingUsersStream(chatId);
    });
