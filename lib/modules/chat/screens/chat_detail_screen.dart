import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/dummy_database.dart';
import '../../profile/screens/profile_view_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String avatar;
  final String? chatId;
  final String? participantId;

  const ChatDetailScreen({
    required this.name,
    required this.avatar,
    this.chatId,
    this.participantId,
    super.key,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final TextEditingController _messageController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final AnimationController _typingAnimation;
  final DummyDatabase _db = DummyDatabase.instance;

  // State
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isOnline = true;
  Timer? _typingTimer;

  // Voice recording
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  late final AnimationController _pulseAnimation;
  double _slideOffset = 0.0;
  static const double _cancelThreshold = -120.0;
  bool _recordingCancelled = false;
  double _longPressStartX = 0.0;

  // Emoji picker
  bool _showEmojiKeyboard = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialMessages();
    _checkOnlineStatus();
    _simulateUserTyping();
  }

  void _initializeControllers() {
    _messageController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    // Hide emoji picker when keyboard shows
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiKeyboard) {
        setState(() => _showEmojiKeyboard = false);
      }
    });

    _typingAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _checkOnlineStatus() {
    if (widget.participantId != null) {
      final user = _db.getUserById(widget.participantId!);
      setState(() {
        _isOnline = user?.isOnline ?? false;
      });
    }
  }

  void _loadInitialMessages() {
    if (widget.chatId != null) {
      // Load messages from DummyDatabase
      final dbMessages = _db.getMessagesForChat(widget.chatId!);
      final currentUserId = _db.currentUser.value.id;

      _messages.addAll(
        dbMessages.map(
          (msg) => ChatMessage(
            id: msg.id,
            text: msg.content,
            time: _formatTime(msg.timestamp),
            isSender: msg.senderId == currentUserId,
            status: msg.isRead ? MessageStatus.read : MessageStatus.delivered,
          ),
        ),
      );
    } else {
      // Fallback to hardcoded messages for demo
      _messages.addAll([
        ChatMessage(
          id: '1',
          text: 'Hey! How are you?',
          time: '2:30 PM',
          isSender: false,
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: '2',
          text: 'I\'m good! Just working on the hackathon project.',
          time: '2:32 PM',
          isSender: true,
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: '3',
          text: 'That sounds awesome! Need any help?',
          time: '2:35 PM',
          isSender: false,
          status: MessageStatus.read,
          reaction: '❤️',
        ),
        ChatMessage(
          id: '4',
          text: 'Maybe with the UI design?',
          time: '2:36 PM',
          isSender: false,
          status: MessageStatus.delivered,
        ),
      ]);
    }
  }

  void _simulateUserTyping() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _isTyping = true);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _isTyping = false);
        _receiveMessage();
      });
    });
  }

  void _receiveMessage() {
    final message = ChatMessage(
      id: DateTime.now().toString(),
      text: 'Would love your help with the UI!',
      time: _formatTime(DateTime.now()),
      isSender: false,
      status: MessageStatus.delivered,
    );

    setState(() => _messages.add(message));
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final message = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      time: _formatTime(DateTime.now()),
      isSender: true,
      status: MessageStatus.sent,
    );

    setState(() => _messages.add(message));
    _scrollToBottom();
    _simulateMessageDelivery(message);

    // Also save to DummyDatabase if we have a chat context
    if (widget.chatId != null && widget.participantId != null) {
      _db.sendMessage(chatId: widget.chatId!, content: text);
    }
  }

  void _simulateMessageDelivery(ChatMessage message) {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => message.status = MessageStatus.delivered);
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => message.status = MessageStatus.read);
    });
  }

  void _startRecording(LongPressStartDetails details) {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _slideOffset = 0.0;
      _recordingCancelled = false;
      _longPressStartX = details.globalPosition.dx;
    });

    _pulseAnimation.repeat(reverse: true);
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordingDuration++);
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _pulseAnimation.stop();
    _pulseAnimation.reset();

    final duration = _recordingDuration;
    final wasCancelled = _recordingCancelled;
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
      _slideOffset = 0.0;
      _recordingCancelled = false;
    });

    if (!wasCancelled && duration >= 1) _sendVoiceMessage(duration);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isRecording || _recordingCancelled) return;

    final deltaX = details.globalPosition.dx - _longPressStartX;
    setState(() {
      _slideOffset = deltaX.clamp(_cancelThreshold - 20, 0.0);
    });

    // Auto-cancel when threshold is reached
    if (_slideOffset <= _cancelThreshold) {
      _cancelRecording();
    }
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    _pulseAnimation.stop();
    _pulseAnimation.reset();

    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
      _slideOffset = 0.0;
      _recordingCancelled = true;
    });

    Get.snackbar(
      'Cancelled',
      'Voice message discarded',
      backgroundColor: NexoraColors.textMuted.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _sendVoiceMessage(int duration) {
    final message = ChatMessage(
      id: DateTime.now().toString(),
      time: _formatTime(DateTime.now()),
      isSender: true,
      status: MessageStatus.sent,
      type: MessageType.audio,
      audioDuration: duration,
    );

    setState(() => _messages.add(message));
    _scrollToBottom();
    _simulateMessageDelivery(message);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addReaction(String messageId, String reaction) {
    setState(() {
      final message = _messages.firstWhere((m) => m.id == messageId);
      message.reaction = reaction;
    });
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackgroundPatterns(),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index], index);
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildMessageInput(),
              if (_showEmojiKeyboard) _buildInlineEmojiPicker(),
            ],
          ),
          if (_isRecording) _buildRecordingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: NexoraColors.midnightDark.withOpacity(0.95),
      elevation: 0,
      leadingWidth: 40,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            color: NexoraColors.textPrimary,
            size: 22,
          ),
        ),
      ),
      titleSpacing: 0,
      flexibleSpace: SizedBox(width: 10),
      title: GestureDetector(
        onTap: () => _showUserProfile(),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: NexoraColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: NexoraColors.accentCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _buildStatusIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // More options
        GestureDetector(
          onTap: _showOptions,
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 12),
            child: const Icon(
              Icons.more_vert_rounded,
              color: NexoraColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  void _showUserProfile() {
    Get.to(
      () => ProfileViewScreen(
        userId: 'user_${widget.name.toLowerCase().replaceAll(' ', '_')}',
        name: widget.name,
        avatar: widget.avatar,
        bio: 'Hey there! I\'m using Nexora 💜',
        year: '3rd Year',
        major: 'Computer Science',
        interests: const ['Music', 'Tech', 'Coffee', 'Gaming'],
        isOnline: true,
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [NexoraShadows.purpleGlow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.avatar,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: NexoraGradients.primaryButton,
                  ),
                  child: Center(
                    child: Text(
                      widget.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
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
        if (_isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: NexoraColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: NexoraColors.midnightDark, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    if (_isTyping) {
      return Row(
        children: [
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: NexoraColors.primaryPurple.withOpacity(
                      (index == 0 && _typingAnimation.value > 0.5) ||
                              (index == 1 && _typingAnimation.value > 0.3) ||
                              (index == 2 && _typingAnimation.value > 0.7)
                          ? 1.0
                          : 0.3,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
          const SizedBox(width: 4),
          Text(
            "typing...",
            style: TextStyle(color: NexoraColors.primaryPurple, fontSize: 10),
          ),
        ],
      );
    }

    return Text(
      _isOnline ? "Online" : "Offline",
      style: TextStyle(
        color: _isOnline ? NexoraColors.success : NexoraColors.textMuted,
        fontSize: 10,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            child: ClipOval(
              child: Image.network(
                widget.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: NexoraColors.primaryPurple.withOpacity(
                          (index == 0 && _typingAnimation.value > 0.5) ||
                                  (index == 1 &&
                                      _typingAnimation.value > 0.3) ||
                                  (index == 2 && _typingAnimation.value > 0.7)
                              ? 1.0
                              : 0.3,
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NexoraColors.midnightDark.withOpacity(0.8),
            NexoraColors.midnightDark,
          ],
        ),
        border: Border(
          top: BorderSide(color: NexoraColors.glassBorder.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            GestureDetector(
              onTap: _showAttachmentOptions,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: NexoraColors.glassBorder),
                ),
                child: const Icon(
                  Icons.add,
                  color: NexoraColors.primaryPurple,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: NexoraColors.glassBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: NexoraColors.textPrimary,
                          fontSize: 16,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "Message...",
                          hintStyle: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showEmojiPicker,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 10),
                        child: Icon(
                          _showEmojiKeyboard
                              ? Icons.keyboard_rounded
                              : Icons.emoji_emotions_outlined,
                          color: _showEmojiKeyboard
                              ? NexoraColors.primaryPurple
                              : NexoraColors.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Send or Voice button
            GestureDetector(
              onTap: hasText ? _sendMessage : null,
              onLongPressStart: hasText ? null : _startRecording,
              onLongPressMoveUpdate: hasText ? null : _onLongPressMoveUpdate,
              onLongPressEnd: hasText ? null : (_) => _stopRecording(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: NexoraGradients.primaryButton,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: NexoraColors.primaryPurple.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  hasText ? Icons.send_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    if (_showEmojiKeyboard) {
      // Switching back to keyboard
      setState(() => _showEmojiKeyboard = false);
      _focusNode.requestFocus();
    } else {
      // Switching to emoji picker
      _focusNode.unfocus();
      setState(() => _showEmojiKeyboard = true);
    }
  }

  Widget _buildInlineEmojiPicker() {
    final emojis = [
      // Smileys
      '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '😉', '😍',
      '🥰', '😘', '😗', '😋', '😛', '😜', '🤪', '😝', '🤗', '🤭', '🤫', '🤔',
      // Hearts & Love
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💕', '💞', '💓', '💗',
      '💖',
      '💘',
      '💝',
      '😻',
      '💑',
      '👩‍❤️‍👨',
      '💏',
      '👫',
      '🥰',
      '😍',
      '😘',
      '💋',
      // Gestures
      '👍', '👎', '👏', '🙌', '🤝', '🙏', '✌️', '🤞', '🤟', '🤙', '👋', '🤚',
      '✋', '🖐️', '👌', '🤌', '💪', '🦾', '👊', '✊', '🤛', '🤜', '👐', '🫶',
      // Objects
      '🔥', '⭐', '✨', '💫', '🌟', '💥', '💯', '🎉', '🎊', '🎁', '🎈', '🎀',
    ];

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: NexoraColors.midnightDark,
        border: Border(
          top: BorderSide(color: NexoraColors.glassBorder.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          // Category tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildEmojiTab(Icons.emoji_emotions_rounded, true),
                _buildEmojiTab(Icons.favorite_rounded, false),
                _buildEmojiTab(Icons.thumb_up_rounded, false),
                _buildEmojiTab(Icons.celebration_rounded, false),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final text = _messageController.text;
                    if (text.isNotEmpty) {
                      _messageController.text = text.substring(
                        0,
                        text.length - 1,
                      );
                      _messageController.selection = TextSelection.collapsed(
                        offset: _messageController.text.length,
                      );
                      setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.backspace_rounded,
                      color: NexoraColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    final currentText = _messageController.text;
                    final selection = _messageController.selection;
                    final baseOffset = selection.baseOffset >= 0
                        ? selection.baseOffset
                        : currentText.length;
                    final extentOffset = selection.extentOffset >= 0
                        ? selection.extentOffset
                        : currentText.length;
                    final newText =
                        currentText.substring(0, baseOffset) +
                        emojis[index] +
                        currentText.substring(extentOffset);
                    _messageController.text = newText;
                    _messageController.selection = TextSelection.collapsed(
                      offset: baseOffset + emojis[index].length,
                    );
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiTab(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isActive
            ? NexoraColors.primaryPurple.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: isActive ? NexoraColors.primaryPurple : NexoraColors.textMuted,
        size: 20,
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    final slideProgress = (_slideOffset / _cancelThreshold).clamp(0.0, 1.0);
    final isNearCancel = slideProgress > 0.7;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: NexoraColors.midnightDark,
          border: Border(
            top: BorderSide(color: NexoraColors.glassBorder.withOpacity(0.3)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Cancel button (always visible) / Trash icon (when sliding)
              GestureDetector(
                onTap: _cancelRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: slideProgress > 0.3
                        ? NexoraColors.error.withOpacity(0.2)
                        : NexoraColors.glassBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: slideProgress > 0.3
                          ? NexoraColors.error.withOpacity(0.5)
                          : NexoraColors.glassBorder,
                    ),
                  ),
                  child: Icon(
                    slideProgress > 0.3
                        ? Icons.delete_rounded
                        : Icons.close_rounded,
                    color: slideProgress > 0.3
                        ? NexoraColors.error
                        : NexoraColors.textMuted,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Slide to cancel section
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _slideOffset = (_slideOffset + details.delta.dx).clamp(
                        _cancelThreshold - 20,
                        0.0,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_slideOffset <= _cancelThreshold) {
                      _cancelRecording();
                    } else {
                      setState(() => _slideOffset = 0.0);
                    }
                  },
                  onTap: () {
                    // Tapping the bar cancels recording
                    _cancelRecording();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    transform: Matrix4.translationValues(_slideOffset, 0, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isNearCancel
                          ? NexoraColors.error.withOpacity(0.1)
                          : NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isNearCancel
                            ? NexoraColors.error.withOpacity(0.3)
                            : NexoraColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Recording indicator dot
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: NexoraColors.error.withOpacity(
                                  0.6 + (_pulseAnimation.value * 0.4),
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: NexoraColors.error.withOpacity(
                                      0.4 * _pulseAnimation.value,
                                    ),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),

                        // Timer
                        Text(
                          _formatDuration(_recordingDuration),
                          style: const TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),

                        const Spacer(),

                        // Slide to cancel with animated chevrons
                        AnimatedOpacity(
                          opacity: 1.0 - slideProgress,
                          duration: const Duration(milliseconds: 100),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      -4 * _pulseAnimation.value,
                                      0,
                                    ),
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      color: NexoraColors.textMuted.withOpacity(
                                        0.5 + (_pulseAnimation.value * 0.5),
                                      ),
                                      size: 18,
                                    ),
                                  );
                                },
                              ),
                              Icon(
                                Icons.chevron_left_rounded,
                                color: NexoraColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Slide to cancel',
                                style: TextStyle(
                                  color: NexoraColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Mic button (recording active)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return AnimatedScale(
                    scale: isNearCancel ? 0.8 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedOpacity(
                      opacity: isNearCancel ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 48 + (_pulseAnimation.value * 4),
                        height: 48 + (_pulseAnimation.value * 4),
                        decoration: BoxDecoration(
                          gradient: isNearCancel
                              ? LinearGradient(
                                  colors: [
                                    NexoraColors.error.withOpacity(0.8),
                                    NexoraColors.error.withOpacity(0.6),
                                  ],
                                )
                              : NexoraGradients.romanticGlow,
                          borderRadius: BorderRadius.circular(
                            24 + (_pulseAnimation.value * 2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isNearCancel
                                          ? NexoraColors.error
                                          : NexoraColors.romanticPink)
                                      .withOpacity(
                                        0.3 + (_pulseAnimation.value * 0.2),
                                      ),
                              blurRadius: 12 + (_pulseAnimation.value * 4),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isNearCancel
                              ? Icons.close_rounded
                              : Icons.mic_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPatterns() {
    return Stack(
      children: [
        // Large heart doodle top-left
        Positioned(
          top: 40,
          left: -20,
          child: Transform.rotate(
            angle: -0.3,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.favorite_outline,
                size: 100,
                color: NexoraColors.romanticPink,
              ),
            ),
          ),
        ),
        // Chat bubble top-right
        Positioned(
          top: 80,
          right: 20,
          child: Transform.rotate(
            angle: 0.2,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: NexoraColors.primaryPurple,
              ),
            ),
          ),
        ),
        // Stars scattered
        Positioned(
          top: 150,
          left: 40,
          child: Opacity(
            opacity: 0.18,
            child: Icon(
              Icons.star_outline,
              size: 35,
              color: NexoraColors.accentCyan,
            ),
          ),
        ),
        Positioned(
          top: 220,
          right: 60,
          child: Transform.rotate(
            angle: 0.5,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.auto_awesome,
                size: 40,
                color: NexoraColors.romanticPink,
              ),
            ),
          ),
        ),
        // Paper plane
        Positioned(
          top: 300,
          left: 10,
          child: Transform.rotate(
            angle: 0.4,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.send_rounded,
                size: 45,
                color: NexoraColors.primaryPurple,
              ),
            ),
          ),
        ),
        // Small hearts
        Positioned(
          top: 380,
          right: 30,
          child: Opacity(
            opacity: 0.14,
            child: Icon(
              Icons.favorite,
              size: 25,
              color: NexoraColors.romanticPink,
            ),
          ),
        ),
        Positioned(
          top: 420,
          right: 80,
          child: Opacity(
            opacity: 0.10,
            child: Icon(
              Icons.favorite_outline,
              size: 20,
              color: NexoraColors.romanticPink,
            ),
          ),
        ),
        // Emoji doodle
        Positioned(
          bottom: 350,
          left: 50,
          child: Transform.rotate(
            angle: -0.2,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.emoji_emotions_outlined,
                size: 50,
                color: NexoraColors.accentCyan,
              ),
            ),
          ),
        ),
        // Message icons
        Positioned(
          bottom: 280,
          right: 20,
          child: Transform.rotate(
            angle: 0.3,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.mark_chat_unread_outlined,
                size: 55,
                color: NexoraColors.primaryPurple,
              ),
            ),
          ),
        ),
        // Music note
        Positioned(
          bottom: 200,
          left: 20,
          child: Opacity(
            opacity: 0.12,
            child: Icon(
              Icons.music_note_outlined,
              size: 40,
              color: NexoraColors.romanticPink,
            ),
          ),
        ),
        // Camera
        Positioned(
          bottom: 150,
          right: 70,
          child: Transform.rotate(
            angle: -0.15,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.camera_alt_outlined,
                size: 35,
                color: NexoraColors.accentCyan,
              ),
            ),
          ),
        ),
        // Sparkle
        Positioned(
          bottom: 100,
          left: 80,
          child: Opacity(
            opacity: 0.15,
            child: Icon(
              Icons.flare,
              size: 30,
              color: NexoraColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isSender = message.isSender;
    final showAvatar =
        !isSender && (index == 0 || _messages[index - 1].isSender);
    final senderChanged =
        index > 0 && _messages[index - 1].isSender != isSender;

    return GestureDetector(
      onLongPress: () => _showReactionSheet(message),
      child: Container(
        margin: EdgeInsets.only(
          left: isSender ? 60 : 0,
          right: isSender ? 0 : 60,
          top: senderChanged ? 16 : 0,
          bottom: 8,
        ),
        child: Row(
          mainAxisAlignment: isSender
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSender && showAvatar)
              _buildSenderAvatar()
            else if (!isSender)
              const SizedBox(width: 38),
            Flexible(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: message.type == MessageType.audio
                        ? const EdgeInsets.all(10)
                        : const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                    decoration: BoxDecoration(
                      gradient: isSender
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                NexoraColors.primaryPurple,
                                NexoraColors.primaryPurple.withOpacity(0.85),
                              ],
                            )
                          : null,
                      color: isSender ? null : NexoraColors.glassBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isSender ? 18 : 4),
                        bottomRight: Radius.circular(isSender ? 4 : 18),
                      ),
                      border: isSender
                          ? null
                          : Border.all(color: NexoraColors.glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isSender
                              ? NexoraColors.primaryPurple.withOpacity(0.25)
                              : Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (message.type == MessageType.audio)
                          _buildAudioMessage(message)
                        else
                          Text(
                            message.text!,
                            style: TextStyle(
                              color: isSender
                                  ? Colors.white
                                  : NexoraColors.textPrimary,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.time,
                              style: TextStyle(
                                color: isSender
                                    ? Colors.white.withOpacity(0.7)
                                    : NexoraColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            if (isSender) _buildStatusIcon(message.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (message.reaction != null)
                    Positioned(
                      bottom: -10,
                      right: isSender ? 0 : null,
                      left: isSender ? null : 0,
                      child: _buildReactionBadge(message.reaction!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderAvatar() {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(right: 8),
      child: ClipOval(
        child: Image.network(
          widget.avatar,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: NexoraGradients.primaryButton,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioMessage(ChatMessage message) {
    final isSender = message.isSender;
    final duration = message.audioDuration ?? 0;

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with Play overlay (WhatsApp style)
          GestureDetector(
            onTap: () {
              Get.snackbar(
                'Playing',
                'Voice message ${_formatDuration(duration)}',
                backgroundColor: NexoraColors.glassBackground,
                colorText: NexoraColors.textPrimary,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 1),
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Avatar background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSender
                        ? LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.1),
                            ],
                          )
                        : NexoraGradients.primaryButton,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isSender
                                    ? Colors.black
                                    : NexoraColors.primaryPurple)
                                .withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: isSender
                        ? Center(
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Image.network(
                            widget.avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                widget.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                // Play button overlay
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSender
                        ? Colors.white.withOpacity(0.9)
                        : NexoraColors.romanticPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: isSender ? NexoraColors.primaryPurple : Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Waveform and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform visualization
                Row(
                  children: List.generate(24, (index) {
                    // Create a more realistic waveform pattern
                    final heights = [
                      8,
                      14,
                      10,
                      18,
                      12,
                      20,
                      8,
                      16,
                      10,
                      14,
                      22,
                      12,
                      18,
                      8,
                      14,
                      20,
                      10,
                      16,
                      8,
                      12,
                      18,
                      10,
                      14,
                      8,
                    ];
                    final height = heights[index].toDouble();

                    return Container(
                      width: 3,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: isSender
                            ? Colors.white.withOpacity(0.8)
                            : NexoraColors.romanticPink.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),

                // Duration row
                Row(
                  children: [
                    // Duration
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        color: isSender
                            ? Colors.white.withOpacity(0.8)
                            : NexoraColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    // Mic icon indicator
                    Icon(
                      Icons.mic_rounded,
                      size: 14,
                      color: isSender
                          ? Colors.white.withOpacity(0.6)
                          : NexoraColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sent:
        icon = Icons.done_rounded;
        color = Colors.white.withOpacity(0.6);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all_rounded;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all_rounded;
        color = NexoraColors.accentCyan;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildReactionBadge(String reaction) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: NexoraColors.midnightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NexoraColors.primaryPurple.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(reaction, style: const TextStyle(fontSize: 14)),
    );
  }

  void _showReactionSheet(ChatMessage message) {
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
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "React to message",
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '🔥', '😂', '😮', '😢', '👍']
                      .map(
                        (reaction) => _buildReactionButton(
                          reaction,
                          () => _addReaction(message.id, reaction),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(String reaction, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NexoraColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(reaction, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  void _showAttachmentOptions() {
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
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Share Content',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose what you want to share',
                  style: TextStyle(color: NexoraColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // Attachment grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentButton(
                      Icons.photo_library_rounded,
                      'Gallery',
                      NexoraColors.primaryPurple,
                      () => _handleAttachment('gallery'),
                    ),
                    _buildAttachmentButton(
                      Icons.camera_alt_rounded,
                      'Camera',
                      NexoraColors.romanticPink,
                      () => _handleAttachment('camera'),
                    ),
                    _buildAttachmentButton(
                      Icons.insert_drive_file_rounded,
                      'Document',
                      NexoraColors.accentCyan,
                      () => _handleAttachment('document'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachment(String type) {
    Get.back();
    Get.snackbar(
      type[0].toUpperCase() + type.substring(1),
      'Opening $type picker...',
      backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: NexoraGradients.mainBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.2),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User info header
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
                                widget.avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: NexoraGradients.primaryButton,
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
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
                                  widget.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: NexoraColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Chat options',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: NexoraColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildOptionItem(
                        Icons.notifications_off_rounded,
                        'Mute notifications',
                        NexoraColors.textSecondary,
                        () => Get.back(),
                      ),

                      Divider(color: NexoraColors.glassBorder, height: 24),
                      _buildOptionItem(
                        Icons.delete_outline_rounded,
                        'Clear chat history',
                        NexoraColors.warning,
                        () => Get.back(),
                      ),
                      _buildOptionItem(
                        Icons.block_rounded,
                        'Block user',
                        NexoraColors.error,
                        () => Get.back(),
                      ),
                      _buildOptionItem(
                        Icons.flag_rounded,
                        'Report user',
                        NexoraColors.error,
                        () => Get.back(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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
                  color:
                      color == NexoraColors.error ||
                          color == NexoraColors.warning
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

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _typingAnimation.dispose();
    _pulseAnimation.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }
}

// Models
enum MessageStatus { sent, delivered, read }

enum MessageType { text, audio }

class ChatMessage {
  final String id;
  final String? text;
  final String time;
  final bool isSender;
  MessageStatus status;
  String? reaction;
  final MessageType type;
  final int? audioDuration;

  ChatMessage({
    required this.id,
    this.text,
    required this.time,
    required this.isSender,
    required this.status,
    this.reaction,
    this.type = MessageType.text,
    this.audioDuration,
  });
}
