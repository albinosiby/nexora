import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../../profile/repositories/user_repository.dart';
import 'chat_detail_screen.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/screens/profile_view_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchGlowAnimation;

  final ChatRepository _chatRepo = ChatRepository.instance;
  final UserRepository _userRepo = UserRepository.instance;

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
    _tabController = TabController(length: 2, vsync: this);
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
    if (_searchFocusNode.hasFocus) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StreamBuilder<List<ChatModel>>(
          stream: _chatRepo.getConversations(),
          builder: (context, snapshot) {
            final chats = snapshot.data ?? [];
            final filteredChats = _searchQuery.isEmpty
                ? chats
                : chats
                      .where(
                        (c) => c.lastMessage.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

            // onlineFriendsCount removed as it's not currently used in the main UI

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                NexoraColors.textPrimary,
                                NexoraColors.primaryPurple.withOpacity(0.9),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              "Messages",
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: BoxDecoration(
                                  color: NexoraColors.online,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: NexoraColors.online.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 6.r,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "Real-time Chat Active",
                                style: TextStyle(
                                  color: NexoraColors.textMuted,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Search bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: AnimatedBuilder(
                    animation: _searchGlowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: _isSearchFocused || _searchQuery.isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: NexoraColors.primaryPurple
                                        .withOpacity(
                                          0.3 * _searchGlowAnimation.value,
                                        ),
                                    blurRadius: 20.r,
                                    spreadRadius: 2.r,
                                  ),
                                  BoxShadow(
                                    color: NexoraColors.accentCyan.withOpacity(
                                      0.15 * _searchGlowAnimation.value,
                                    ),
                                    blurRadius: 30.r,
                                    spreadRadius: 0,
                                    offset: Offset(0, 4.h),
                                  ),
                                ]
                              : [],
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            color: _isSearchFocused
                                ? NexoraColors.cardSurface
                                : NexoraColors.cardBackground,
                            border: Border.all(
                              color: _isSearchFocused
                                  ? NexoraColors.primaryPurple.withOpacity(0.5)
                                  : NexoraColors.cardBorder,
                              width: _isSearchFocused ? 1.5.w : 1.w,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: _isSearchFocused
                                      ? LinearGradient(
                                          colors: [
                                            NexoraColors.primaryPurple
                                                .withOpacity(0.3),
                                            NexoraColors.accentCyan.withOpacity(
                                              0.2,
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    _searchQuery.isNotEmpty
                                        ? Icons.manage_search_rounded
                                        : Icons.search_rounded,
                                    key: ValueKey(_searchQuery.isNotEmpty),
                                    color: _isSearchFocused
                                        ? NexoraColors.brightPurple
                                        : NexoraColors.textMuted,
                                    size: 22.r,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  style: TextStyle(
                                    color: NexoraColors.textPrimary,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  cursorColor: NexoraColors.primaryPurple,
                                  decoration: InputDecoration(
                                    hintText: _isSearchFocused
                                        ? 'Search by last message...'
                                        : 'Search messages...',
                                    hintStyle: TextStyle(
                                      color: _isSearchFocused
                                          ? NexoraColors.textMuted.withOpacity(
                                              0.8,
                                            )
                                          : NexoraColors.textMuted,
                                      fontSize: 15.sp,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _searchQuery.isNotEmpty
                                    ? GestureDetector(
                                        key: const ValueKey('clear'),
                                        onTap: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(6.r),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: NexoraColors.textMuted
                                                .withOpacity(0.2),
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: NexoraColors.textSecondary,
                                            size: 16.r,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('empty'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Tabs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: NexoraColors.glassBorder),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: NexoraGradients.primaryButton,
                        boxShadow: [
                          BoxShadow(
                            color: NexoraColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: NexoraColors.textMuted,
                      labelStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: EdgeInsets.all(4.r),
                      tabs: [
                        const Tab(text: "All Chats"),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Unread"),
                              if (chats.any(
                                (c) =>
                                    (c.unreadCounts[_chatRepo.currentUserId ??
                                            ''] ??
                                        0) >
                                    0,
                              )) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NexoraColors.loveRed,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '${chats.where((c) => (c.unreadCounts[_chatRepo.currentUserId ?? ''] ?? 0) > 0).length}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Chat list
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChatList(filteredChats),
                        _buildChatList(
                          filteredChats
                              .where(
                                (c) =>
                                    (c.unreadCounts[_chatRepo.currentUserId ??
                                            ''] ??
                                        0) >
                                    0,
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatModel> chatList) {
    if (chatList.isEmpty) {
      return _buildEmptyState('No messages found', Icons.chat_bubble_outline);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: chatList.length,
      itemBuilder: (context, index) => _buildChatItem(chatList[index], index),
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
        final name = otherUser?.name ?? 'Loading...';
        final avatar = otherUser?.avatar ?? '';
        final isOnline = otherUser?.isOnline ?? false;

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: GestureDetector(
                  onTap: () {
                    _chatRepo.markAsRead(chat.id);
                    Get.to(
                      () => ChatDetailScreen(
                        name: name,
                        avatar: avatar,
                        chatId: chat.id,
                        participantId: otherUserId,
                      ),
                    );
                  },
                  onLongPress: () =>
                      _showChatOptions(chat, name, avatar, isOnline),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: hasUnread
                            ? NexoraColors.primaryPurple.withOpacity(0.08)
                            : NexoraColors.glassBackground,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: hasUnread
                              ? NexoraColors.primaryPurple.withOpacity(0.2)
                              : NexoraColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(
                            avatar,
                            name,
                            isOnline,
                            hasUnread,
                            otherUser,
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: hasUnread
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 15.sp,
                                          color: NexoraColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      _formatTime(chat.lastMessageTime),
                                      style: TextStyle(
                                        color: hasUnread
                                            ? NexoraColors.primaryPurple
                                            : NexoraColors.textMuted,
                                        fontSize: 12.sp,
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    if (!hasUnread &&
                                        !isTyping &&
                                        chat.lastMessage.isNotEmpty) ...[
                                      Icon(
                                        Icons.done_all,
                                        size: 16.r,
                                        color: NexoraColors.accentCyan,
                                      ),
                                      SizedBox(width: 4.w),
                                    ],
                                    Expanded(
                                      child: isTyping
                                          ? _buildTypingIndicator()
                                          : Text(
                                              chat.lastMessage.isEmpty
                                                  ? 'Start a conversation'
                                                  : chat.lastMessage,
                                              style: TextStyle(
                                                color: hasUnread
                                                    ? NexoraColors.textSecondary
                                                    : NexoraColors.textMuted,
                                                fontSize: 14.sp,
                                                fontWeight: hasUnread
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ),
                                    if (hasUnread)
                                      _buildUnreadBadge(unreadCount),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
          Get.to(
            () => ProfileViewScreen(profile: user),
            transition: Transition.rightToLeftWithFade,
          );
        }
      },
      child: Stack(
        children: [
          Container(
            padding: isOnline ? EdgeInsets.all(3.r) : null,
            decoration: isOnline
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    gradient: NexoraGradients.romanticGlow,
                  )
                : null,
            child: Container(
              width: 54.r,
              height: 54.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: isOnline
                    ? Border.all(color: NexoraColors.midnightDark, width: 2.w)
                    : null,
                boxShadow: hasUnread ? [NexoraShadows.purpleGlow] : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: avatar.startsWith('http')
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(name),
                      )
                    : _buildPlaceholder(name),
              ),
            ),
          ),
          if (isOnline)
            Positioned(bottom: 0, right: 0, child: _buildOnlineIndicator()),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      decoration: BoxDecoration(gradient: NexoraGradients.primaryButton),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: TextStyle(
            fontSize: 22.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Container(
      width: 16.r,
      height: 16.r,
      decoration: BoxDecoration(
        color: NexoraColors.online,
        shape: BoxShape.circle,
        border: Border.all(color: NexoraColors.midnightDark, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: NexoraColors.online.withOpacity(0.5),
            blurRadius: 6.r,
            spreadRadius: 1.r,
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Text(
          'typing',
          style: TextStyle(
            color: NexoraColors.primaryPurple,
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
                    color: NexoraColors.primaryPurple.withOpacity(
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

  Widget _buildUnreadBadge(int count) {
    return Container(
      margin: EdgeInsets.only(left: 10.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: NexoraGradients.primaryButton,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: NexoraColors.primaryPurple.withOpacity(0.4),
            blurRadius: 8.r,
          ),
        ],
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
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
                  NexoraColors.error,
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
    return GestureDetector(
      onTap: () => Get.back(),
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
