import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/services/dummy_database.dart';
import 'chat_detail_screen.dart';
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

  final DummyDatabase _db = DummyDatabase.instance;

  List<Map<String, dynamic>> get chats {
    final currentUserId = _db.currentUser.value.id;
    return _db.chats.map((chat) {
      // Get the other participant
      final otherUserId = chat.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => chat.participantIds.first,
      );
      final otherUser = _db.getUserById(otherUserId);
      
      return {
        'chatId': chat.id,
        'userId': otherUserId,
        'name': otherUser?.displayName ?? 'unknown',
        'lastMessage': chat.lastMessage,
        'time': _formatTime(chat.lastMessageTime),
        'unread': chat.unreadCount,
        'image': otherUser?.avatar ?? '',
        'online': otherUser?.isOnline ?? false,
        'typing': chat.isTyping,
        'pinned': false,
      };
    }).toList()
      ..sort((a, b) {
        // Sort by pinned first, then by time
        if ((a['pinned'] as bool) != (b['pinned'] as bool)) {
          return (a['pinned'] as bool) ? -1 : 1;
        }
        return 0;
      });
  }

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

  List<Map<String, dynamic>> get filteredChats {
    if (_searchQuery.isEmpty) return chats;
    return chats.where((chat) {
      final name = (chat['name'] as String).toLowerCase();
      final message = (chat['lastMessage'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          message.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final onlineFriends = chats.where((c) => c['online'] == true).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        child: const Text(
                          "Messages",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: NexoraColors.online,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: NexoraColors.online.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${onlineFriends.length} friends online",
                            style: TextStyle(
                              color: NexoraColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Online friends horizontal list
            if (onlineFriends.isNotEmpty) ...[
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: onlineFriends.length,
                  itemBuilder: (context, index) =>
                      _buildOnlineFriendAvatar(onlineFriends[index]),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _searchGlowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isSearchFocused || _searchQuery.isNotEmpty
                          ? [
                              BoxShadow(
                                color: NexoraColors.primaryPurple.withOpacity(
                                  0.3 * _searchGlowAnimation.value,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: NexoraColors.accentCyan.withOpacity(
                                  0.15 * _searchGlowAnimation.value,
                                ),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _isSearchFocused
                            ? NexoraColors.cardSurface
                            : NexoraColors.cardBackground,
                        border: Border.all(
                          color: _isSearchFocused
                              ? NexoraColors.primaryPurple.withOpacity(0.5)
                              : NexoraColors.cardBorder,
                          width: _isSearchFocused ? 1.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _isSearchFocused
                                  ? LinearGradient(
                                      colors: [
                                        NexoraColors.primaryPurple.withOpacity(
                                          0.3,
                                        ),
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
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: const TextStyle(
                                color: NexoraColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              cursorColor: NexoraColors.primaryPurple,
                              decoration: InputDecoration(
                                hintText: _isSearchFocused
                                    ? 'Search by name or message...'
                                    : 'Search messages...',
                                hintStyle: TextStyle(
                                  color: _isSearchFocused
                                      ? NexoraColors.textMuted.withOpacity(0.8)
                                      : NexoraColors.textMuted,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    key: const ValueKey('clear'),
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: NexoraColors.textMuted
                                            .withOpacity(0.2),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: NexoraColors.textSecondary,
                                        size: 16,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Search results count
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _searchQuery.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: 24, top: 8),
                      child: Text(
                        '${filteredChats.length} ${filteredChats.length == 1 ? 'result' : 'results'} found',
                        style: TextStyle(
                          color: NexoraColors.primaryPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NexoraColors.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: NexoraGradients.primaryButton,
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: NexoraColors.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    const Tab(text: "All Chats"),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Unread"),
                          if (chats
                              .where((c) => (c['unread'] as int) > 0)
                              .isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: NexoraColors.loveRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${chats.where((c) => (c['unread'] as int) > 0).length}',
                                style: const TextStyle(
                                  fontSize: 10,
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
                          .where((c) => (c['unread'] as int) > 0)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<Map<String, dynamic>> chatList) {
    if (chatList.isEmpty) {
      return _buildEmptyState('No messages found', Icons.chat_bubble_outline);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: chatList.length,
      itemBuilder: (context, index) => _buildChatItem(chatList[index], index),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, int index) {
    final bool hasUnread = (chat['unread'] as int) > 0;
    final bool isOnline = chat['online'] as bool;
    final bool isTyping = chat['typing'] == true;

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
              onTap: () => Get.to(
                () => ChatDetailScreen(
                  name: chat['name'] as String,
                  avatar: chat['image'] as String,
                  chatId: chat['chatId'] as String?,
                  participantId: chat['userId'] as String?,
                ),
              ),
              onLongPress: () => _showChatOptions(chat),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hasUnread
                        ? NexoraColors.primaryPurple.withOpacity(0.08)
                        : NexoraColors.glassBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: hasUnread
                          ? NexoraColors.primaryPurple.withOpacity(0.2)
                          : NexoraColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar with story ring for online users - tap to view profile
                      GestureDetector(
                        onTap: () => Get.to(
                          () => ProfileViewScreen(
                            userId: '${chat['name']?.hashCode ?? 0}',
                            name: chat['name'] as String,
                            avatar: chat['image'] as String,
                            bio: 'Hey there! I\'m using Nexora 💜',
                            year: '3rd Year',
                            major: 'Computer Science',
                            interests: const ['Coding', 'Music', 'Gaming'],
                            isOnline: isOnline,
                          ),
                          transition: Transition.rightToLeftWithFade,
                        ),
                        child: Stack(
                          children: [
                            Container(
                              padding: isOnline
                                  ? const EdgeInsets.all(3)
                                  : null,
                              decoration: isOnline
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: NexoraGradients.romanticGlow,
                                    )
                                  : null,
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: isOnline
                                      ? Border.all(
                                          color: NexoraColors.midnightDark,
                                          width: 2,
                                        )
                                      : null,
                                  boxShadow: hasUnread
                                      ? [NexoraShadows.purpleGlow]
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    chat['image'] as String,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient:
                                              NexoraGradients.primaryButton,
                                        ),
                                        child: Center(
                                          child: Text(
                                            (chat['name'] as String)[0],
                                            style: const TextStyle(
                                              fontSize: 22,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            // Online indicator dot
                            if (isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: NexoraColors.online,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: NexoraColors.midnightDark,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: NexoraColors.online.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          chat['name'] as String,
                                          style: TextStyle(
                                            fontWeight: hasUnread
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 15,
                                            color: NexoraColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  chat['time'] as String,
                                  style: TextStyle(
                                    color: hasUnread
                                        ? NexoraColors.primaryPurple
                                        : NexoraColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Message status icon (for sent messages)
                                if (!hasUnread && !isTyping) ...[
                                  Icon(
                                    Icons.done_all,
                                    size: 16,
                                    color: NexoraColors.accentCyan,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: isTyping
                                      ? Row(
                                          children: [
                                            Text(
                                              'typing',
                                              style: TextStyle(
                                                color:
                                                    NexoraColors.primaryPurple,
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            _buildTypingIndicator(),
                                          ],
                                        )
                                      : Text(
                                          chat['lastMessage'] as String,
                                          style: TextStyle(
                                            color: hasUnread
                                                ? NexoraColors.textSecondary
                                                : NexoraColors.textMuted,
                                            fontSize: 14,
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
                                    margin: const EdgeInsets.only(left: 10),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: NexoraGradients.primaryButton,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: NexoraColors.primaryPurple
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${chat['unread']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChatOptions(Map<String, dynamic> chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.2),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          chat['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: NexoraGradients.primaryButton,
                              ),
                              child: Center(
                                child: Text(
                                  (chat['name'] as String)[0],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat['name'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: NexoraColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            chat['online'] == true ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 13,
                              color: chat['online'] == true
                                  ? NexoraColors.online
                                  : NexoraColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
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
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + (index * 200)),
          builder: (context, double value, child) {
            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
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
    );
  }

  Widget _buildOnlineFriendAvatar(Map<String, dynamic> friend) {
    return GestureDetector(
      onTap: () => Get.to(
        () => ChatDetailScreen(
          name: friend['name'] as String,
          avatar: friend['image'] as String,
          chatId: friend['chatId'] as String?,
          participantId: friend['userId'] as String?,
        ),
      ),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NexoraGradients.romanticGlow,
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NexoraColors.midnightDark,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        friend['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: NexoraGradients.primaryButton,
                            ),
                            child: Center(
                              child: Text(
                                (friend['name'] as String)[0],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: NexoraColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NexoraColors.midnightDark,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              (friend['name'] as String).split(' ').first,
              style: const TextStyle(
                fontSize: 12,
                color: NexoraColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showNewMessageSheet() {
    Get.snackbar(
      'New Message',
      'Start a new conversation',
      backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NexoraColors.glassBackground,
              shape: BoxShape.circle,
              border: Border.all(color: NexoraColors.glassBorder),
            ),
            child: Icon(
              icon,
              size: 48,
              color: NexoraColors.primaryPurple.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation',
            style: TextStyle(color: NexoraColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
