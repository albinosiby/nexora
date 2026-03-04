import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../providers/chat_provider.dart';
import '../../profile/repositories/user_repository.dart';
import '../../profile/models/profile_model.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  ConsumerState<CommunityChatScreen> createState() =>
      _CommunityChatScreenState();
}

class _CommunityChatScreenState extends ConsumerState<CommunityChatScreen>
    with TickerProviderStateMixin {
  static const String _chatId = 'community';

  // Controllers
  late final TextEditingController _messageController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final AnimationController _typingAnimation;

  late final ChatRepository _chatRepo;
  late final UserRepository _userRepo;

  // State
  bool _isTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _messageSubscription;
  List<MessageModel> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatRepo = ref.read(chatRepositoryProvider);
    _userRepo = ref.read(userRepositoryProvider);

    _initializeControllers();
    _setupStreams();
  }

  void _initializeControllers() {
    _messageController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    _typingAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  void _setupStreams() {
    _messageSubscription = _chatRepo.getMessagesStream(_chatId).listen((
      messages,
    ) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _typingAnimation.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final String messageId = FirebaseDatabase.instance
          .ref('messages/$_chatId')
          .push()
          .key!;

      // Optimistic update
      final optimisticMsg = MessageModel(
        id: messageId,
        chatId: _chatId,
        senderId: _chatRepo.currentUserId!,
        content: text,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(optimisticMsg);
      });
      _scrollToBottom();

      _chatRepo
          .sendMessage(chatId: _chatId, content: text, messageId: messageId)
          .catchError((e) {
            debugPrint('Community Send Error: $e');
            return '';
          });
    } catch (e) {
      debugPrint('Send Message Error: $e');
    }
  }

  void _onTypingChanged(String value) {
    if (!_isTyping && value.isNotEmpty) {
      _isTyping = true;
      _chatRepo.setTypingStatus(_chatId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _chatRepo.setTypingStatus(_chatId, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: NexoraColors.primaryPurple,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(20.r),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageItem(_messages[index], index);
                      },
                    ),
            ),
            _buildTypingIndicator(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: NexoraColors.midnightDark.withOpacity(0.95),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: NexoraColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.groups_rounded,
              color: NexoraColors.primaryPurple,
              size: 24.r,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              Text(
                'Public Discussion',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: NexoraColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message, int index) {
    final isSender = message.senderId == _chatRepo.currentUserId;
    final showSenderName =
        !isSender &&
        (index == 0 || _messages[index - 1].senderId != message.senderId);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h, top: showSenderName ? 8.h : 0),
      child: Column(
        crossAxisAlignment: isSender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showSenderName)
            FutureBuilder<ProfileModel?>(
              future: _userRepo.getUserById(message.senderId),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                  child: Text(
                    user?.displayName ?? 'Loading...',
                    style: TextStyle(
                      color: NexoraColors.primaryPurple,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          _buildMessageBubble(message, isSender),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isSender) {
    return Container(
      constraints: BoxConstraints(maxWidth: 0.75.sw),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: isSender ? NexoraGradients.primaryButton : null,
        color: isSender ? null : NexoraColors.glassBackground,
        borderRadius: BorderRadius.circular(18.r).copyWith(
          bottomRight: isSender ? Radius.circular(4.r) : null,
          bottomLeft: !isSender ? Radius.circular(4.r) : null,
        ),
        border: Border.all(
          color: isSender
              ? NexoraColors.primaryPurple.withOpacity(0.2)
              : NexoraColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isSender ? Colors.white : NexoraColors.textPrimary,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: (isSender ? Colors.white : NexoraColors.textMuted)
                  .withOpacity(0.6),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final typingUsersAsync = ref.watch(typingUsersProvider(_chatId));

    return typingUsersAsync.when(
      data: (uids) {
        if (uids.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            children: [
              _buildModernTypingDot(),
              SizedBox(width: 8.w),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: Future.wait(
                    uids.take(3).map((uid) async {
                      final user = await _userRepo.getUserById(uid);
                      return user?.displayName ?? 'Someone';
                    }),
                  ),
                  builder: (context, snapshot) {
                    final names = snapshot.data ?? [];
                    final text = names.isEmpty
                        ? 'Someone is typing...'
                        : (names.length == 1
                              ? '${names[0]} is typing...'
                              : '${names.join(', ')} are typing...');
                    return Text(
                      text,
                      style: TextStyle(
                        color: NexoraColors.primaryPurple,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildModernTypingDot() {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          width: 4.r,
          height: 4.r,
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            color: NexoraColors.primaryPurple.withOpacity(0.5 + (index * 0.2)),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: NexoraColors.midnightDark.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: NexoraColors.glassBorder.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: NexoraColors.glassBorder),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  onChanged: _onTypingChanged,
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 15.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: NexoraGradients.primaryButton,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NexoraColors.primaryPurple.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20.r,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}
