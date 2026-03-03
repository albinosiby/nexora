import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../../profile/repositories/user_repository.dart';
import 'chat_detail_screen.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final ChatRepository _chatRepo = ref.read(chatRepositoryProvider);
  final UserRepository _userRepo = UserRepository.instance;

  // Cache resolved user names for filtering
  final Map<String, String> _userNameCache = {};

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: StreamBuilder<List<ChatModel>>(
                stream: _chatRepo.getConversations(),
                builder: (context, snapshot) {
                  final chats = snapshot.data ?? [];

                  // onlineFriendsCount removed as it's not currently used in the main UI

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),

                      // Redesigned Search Bar
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        child: Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: NexoraColors.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(
                              color: NexoraColors.primaryPurple.withOpacity(
                                0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 16.w),
                              Icon(
                                Icons.search,
                                color: NexoraColors.textMuted,
                                size: 24.r,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value.toLowerCase();
                                    });
                                  },
                                  style: TextStyle(
                                    color: NexoraColors.textPrimary,
                                    fontSize: 17.sp,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: TextStyle(
                                      color: NexoraColors.textMuted,
                                      fontSize: 17.sp,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.mic_none_rounded,
                                color: NexoraColors.textMuted,
                                size: 24.r,
                              ),
                              SizedBox(width: 16.w),
                            ],
                          ),
                        ),
                      ),

                      // Chat List
                      Expanded(child: _buildChatList(chats)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatModel> chatList) {
    if (chatList.isEmpty) {
      return _buildEmptyState('No messages found', Icons.chat_bubble_outline);
    }

    // Filter by search query using cached user names
    final filteredList = _searchQuery.isEmpty
        ? chatList
        : chatList.where((chat) {
            final currentUserId = _chatRepo.currentUserId;
            final otherUserId = chat.participantIds.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            final cachedName = _userNameCache[otherUserId]?.toLowerCase() ?? '';
            return cachedName.contains(_searchQuery);
          }).toList();

    if (filteredList.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptyState('No results found', Icons.search_off_rounded);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) =>
          _buildChatItem(filteredList[index], index),
    );
  }

  Widget _buildChatItem(ChatModel chat, int index) {
    final currentUserId = _chatRepo.currentUserId;
    final otherUserId = chat.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final unreadCount = chat.unreadCounts[currentUserId ?? ''] ?? 0;
    final hasUnread = unreadCount > 0;
    final isTyping = chat.typingStatus[otherUserId] == true;

    return StreamBuilder<ProfileModel?>(
      stream: _userRepo.getUserStream(otherUserId),
      builder: (context, userSnapshot) {
        final otherUser = userSnapshot.data;
        final name = otherUser?.displayName ?? 'Loading...';
        final avatar = otherUser?.avatar ?? '';
        final isOnline = otherUser?.isOnline ?? false;

        // Cache the resolved name for search filtering
        if (otherUser != null) {
          _userNameCache[otherUserId] = name;
        }

        return TweenAnimationBuilder<double>(
          key: ValueKey('chat_item_${chat.id}'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index.clamp(0, 10) * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: GestureDetector(
                  onTap: () {
                    _chatRepo.markAsRead(chat.id);
                    Navigator.push(
                      context,
                      NexoraPageRoute(
                        page: ChatDetailScreen(
                          name: name,
                          avatar: avatar,
                          chatId: chat.id,
                          participantId: otherUserId,
                        ),
                      ),
                    );
                  },
                  onLongPress: () =>
                      _showChatOptions(chat, name, avatar, isOnline),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          children: [
                            StreamBuilder<bool>(
                              stream: _userRepo.getUserPresenceStream(
                                otherUserId,
                              ),
                              builder: (context, presenceSnapshot) {
                                final currentOnlineStatus =
                                    presenceSnapshot.data ?? isOnline;
                                return _buildAvatar(
                                  avatar,
                                  name,
                                  currentOnlineStatus,
                                  hasUnread,
                                  otherUser,
                                );
                              },
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.sp,
                                            color: NexoraColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(chat.lastMessageTime),
                                        style: TextStyle(
                                          color: NexoraColors.textMuted,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: isTyping
                                            ? _buildTypingIndicator()
                                            : Text(
                                                chat.lastMessage.isEmpty
                                                    ? 'Start a conversation'
                                                    : chat.lastMessage,
                                                style: TextStyle(
                                                  color: hasUnread
                                                      ? NexoraColors.textPrimary
                                                      : NexoraColors.textMuted,
                                                  fontSize: 13.sp,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                      ),
                                      if (hasUnread)
                                        Container(
                                          width: 10.r,
                                          height: 10.r,
                                          margin: EdgeInsets.only(left: 8.w),
                                          decoration: BoxDecoration(
                                            color: NexoraColors.romanticPink,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 78.w, right: 20.w),
                        child: Divider(
                          color: Colors.white.withOpacity(0.04),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(
    String avatar,
    String name,
    bool isOnline,
    bool hasUnread,
    ProfileModel? user,
  ) {
    return GestureDetector(
      onTap: () {
        if (user != null) {
          Navigator.push(
            context,
            NexoraPageRoute(page: ProfileViewScreen(profile: user)),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10.r,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: avatar.startsWith('http')
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(name),
                    )
                  : _buildPlaceholder(name),
            ),
          ),
          if (isOnline)
            Positioned(
              bottom: 2.r,
              right: 2.r,
              child: Container(
                width: 11.r,
                height: 11.r,
                decoration: BoxDecoration(
                  color: NexoraColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NexoraColors.midnightDark,
                    width: 2.5.w,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NexoraColors.romanticPink.withOpacity(0.8),
            NexoraColors.romanticPink,
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Text(
          'typing',
          style: TextStyle(
            color: NexoraColors.romanticPink,
            fontSize: 14.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 600 + (index * 200)),
              builder: (context, double value, child) {
                return Container(
                  width: 4.r,
                  height: 4.r,
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  decoration: BoxDecoration(
                    color: NexoraColors.romanticPink.withOpacity(
                      0.4 + (value * 0.6),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  void _showChatOptions(
    ChatModel chat,
    String name,
    String avatar,
    bool isOnline,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.2),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 50.r,
                      height: 50.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: avatar.startsWith('http')
                            ? Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(name),
                              )
                            : _buildPlaceholder(name),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: NexoraColors.textPrimary,
                            ),
                          ),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isOnline
                                  ? NexoraColors.online
                                  : NexoraColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildChatOption(
                  Icons.push_pin_rounded,
                  'Pin conversation',
                  NexoraColors.accentCyan,
                ),
                _buildChatOption(
                  Icons.notifications_off_rounded,
                  'Mute notifications',
                  NexoraColors.textSecondary,
                ),
                _buildChatOption(
                  Icons.archive_rounded,
                  'Archive chat',
                  NexoraColors.primaryPurple,
                ),
                _buildChatOption(
                  Icons.delete_outline_rounded,
                  'Delete chat',
                  NexoraColors.loveRed,
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatOption(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: color == NexoraColors.error
                      ? color
                      : NexoraColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: NexoraColors.textMuted,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64.r,
            color: NexoraColors.textMuted.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
