import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/controllers/media_controller.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../repositories/chat_repository.dart';
import '../../profile/repositories/user_repository.dart';
import '../../../core/services/storage_service.dart';
import '../models/message_model.dart';
import '../../profile/models/profile_model.dart';
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

  final ChatRepository _chatRepo = ChatRepository.instance;
  final UserRepository _userRepo = UserRepository.instance;
  final StorageService _storageService = StorageService.instance;

  // Recording & Audio
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  PlayerState _playerState = PlayerState.stopped;

  // State
  String? _activeChatId;
  bool _isTyping = false;
  bool _isOnline = false;
  bool _isVerified = false;
  Timer? _typingTimer;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _onlineSubscription;
  StreamSubscription? _profileSubscription;
  List<MessageModel> _messages = [];
  bool _isLoading = true;

  // Voice recording
  bool _isRecording = false;
  bool _isRecordingLocked = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  late final AnimationController _pulseAnimation;
  double _slideOffset = 0.0;
  double _verticalSlideOffset = 0.0;
  static const double _cancelThreshold = -120.0;
  static const double _lockThreshold = -80.0;
  bool _recordingCancelled = false;
  double _longPressStartX = 0.0;
  double _longPressStartY = 0.0;

  // State
  bool _isUploadingAudio = false;
  bool _isSending = false;
  final RxSet<String> _downloadingIds = <String>{}.obs;
  bool _showEmojiKeyboard = false;

  // Reply
  MessageModel? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _activeChatId = widget.chatId;
    _initializeControllers();
    _initializeChat();
    // Pre-emptively check for microphone permission
    _checkPermission();
  }

  Future<void> _initializeChat() async {
    if (_activeChatId == null && widget.participantId != null) {
      final existingChatId = await _chatRepo.findExistingChat(
        widget.participantId!,
      );
      if (existingChatId != null) {
        if (mounted) {
          setState(() {
            _activeChatId = existingChatId;
          });
        }
      }
    }
    _setupStreams();
    _markAsRead();
  }

  Future<void> _checkPermission() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        // This will trigger the system prompt if not already denied
      }
    } catch (e) {
      print('Permission check error: $e');
    }
  }

  void _markAsRead() {
    if (_activeChatId != null) {
      _chatRepo.markAsRead(_activeChatId!);
    }
  }

  void _setupStreams() {
    if (_activeChatId != null) {
      // Cancel previous subscriptions if any
      _messageSubscription?.cancel();
      _typingSubscription?.cancel();
      _onlineSubscription?.cancel();
      _profileSubscription?.cancel();

      // Message stream
      _messageSubscription = _chatRepo.getMessagesStream(_activeChatId!).listen(
        (messages) {
          if (mounted) {
            setState(() {
              _messages = messages;
              _isLoading = false;
            });
            _scrollToBottom();
            _chatRepo.markMessagesAsDelivered(_activeChatId!);
            _chatRepo.markAsRead(_activeChatId!);
          }
        },
      );

      // Typing stream (for the OTHER user)
      if (widget.participantId != null) {
        _typingSubscription = _chatRepo
            .getTypingStatus(_activeChatId!, widget.participantId!)
            .listen((isTyping) {
              if (mounted) {
                setState(() => _isTyping = isTyping);
              }
            });

        // Online stream (from RTDB for real-time presence)
        _onlineSubscription = _userRepo
            .getUserPresenceStream(widget.participantId!)
            .listen((isOnline) {
              if (mounted) {
                setState(() => _isOnline = isOnline);
              }
            });

        // Profile stream (for verification badge, etc.)
        _profileSubscription = _userRepo
            .getUserStream(widget.participantId!)
            .listen((profile) {
              if (mounted && profile != null) {
                setState(() {
                  _isVerified = profile.isVerified;
                });
              }
            });
      }
    } else {
      // If we don't have a chatId yet, we are not loading messages
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _onlineSubscription?.cancel();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _typingAnimation.dispose();
    _pulseAnimation.dispose();
    _recordingTimer?.cancel();
    _typingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
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

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      if (_activeChatId == null) {
        if (widget.participantId == null) return;
        final newChatId = await _chatRepo.createChat(widget.participantId!);
        if (newChatId.isEmpty) return;

        setState(() {
          _activeChatId = newChatId;
        });
        _setupStreams();
      }

      // Capture reply before clearing state for optimistic feel
      final replyMsg = _replyingToMessage;
      _messageController.clear();
      setState(() => _replyingToMessage = null);

      await _chatRepo.sendMessage(
        chatId: _activeChatId!,
        content: text,
        replyToId: replyMsg?.id,
        replyToContent: replyMsg?.content,
        replyToSenderId: replyMsg?.senderId,
      );
      _scrollToBottom();
    } catch (e) {
      print('Send Message Error: $e');
      Get.snackbar('Error', 'Failed to send message');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _startRecording(LongPressStartDetails? details) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig();

        await _audioRecorder.start(config, path: path);

        if (mounted) {
          setState(() {
            _isRecording = true;
            _isRecordingLocked = false;
            _recordingDuration = 0;
            _slideOffset = 0.0;
            _verticalSlideOffset = 0.0;
            _recordingCancelled = false;
            if (details != null) {
              _longPressStartX = details.globalPosition.dx;
              _longPressStartY = details.globalPosition.dy;
            }
          });

          HapticFeedback.mediumImpact();
          _pulseAnimation.repeat(reverse: true);
          _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted) setState(() => _recordingDuration++);
          });
        }
      } else {
        Get.snackbar(
          'Permission Denied',
          'Please enable microphone access in settings to send voice messages',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Recording Error: $e');
      Get.snackbar('Error', 'Could not start recording: $e');
    }
  }

  void _stopRecording({bool send = true}) async {
    if (!_isRecording) return;

    _recordingTimer?.cancel();
    _pulseAnimation.stop();
    _pulseAnimation.reset();

    final wasCancelled = _recordingCancelled || !send;
    final duration = _recordingDuration;
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _isRecordingLocked = false;
      _recordingDuration = 0;
      _slideOffset = 0.0;
      _verticalSlideOffset = 0.0;
      _recordingCancelled = false;
    });

    if (!wasCancelled && path != null) {
      if (duration >= 1) {
        _sendVoiceMessage(path, duration);
      } else {
        Get.snackbar(
          'Message too short',
          'Hold to record, release to send',
          backgroundColor: NexoraColors.textMuted.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
        );
      }
    } else {
      if (path != null) {
        // Delete temporary file if cancelled
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isRecording || _recordingCancelled || _isRecordingLocked) return;

    final deltaX = details.globalPosition.dx - _longPressStartX;
    final deltaY = details.globalPosition.dy - _longPressStartY;

    setState(() {
      _slideOffset = deltaX.clamp(_cancelThreshold - 20, 0.0);
      _verticalSlideOffset = deltaY.clamp(_lockThreshold - 20, 0.0);
    });

    // Auto-lock when vertical threshold is reached
    if (_verticalSlideOffset <= _lockThreshold) {
      setState(() {
        _isRecordingLocked = true;
        _slideOffset = 0.0;
        _verticalSlideOffset = 0.0;
      });
      HapticFeedback.heavyImpact();
    }
    // Auto-cancel when horizontal threshold is reached
    else if (_slideOffset <= _cancelThreshold) {
      HapticFeedback.mediumImpact();
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
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
    );
  }

  void _sendVoiceMessage(String path, int duration) async {
    if (_isSending) return;

    if (_activeChatId == null) {
      if (widget.participantId == null) return;
      final newChatId = await _chatRepo.createChat(widget.participantId!);
      if (newChatId.isEmpty) return;
      setState(() {
        _activeChatId = newChatId;
      });
      _setupStreams();
    }

    // Capture reply before clearing
    final replyMsg = _replyingToMessage;
    setState(() {
      _isSending = true;
      _replyingToMessage = null;
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        Get.snackbar('Error', 'Voice recording not found. Please try again.');
        return;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        Get.snackbar('Error', 'Recording failed. Please try again.');
        return;
      }

      setState(() => _isUploadingAudio = true);
      _scrollToBottom();

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'chats/$_activeChatId/voice/$fileName';

      final downloadUrl = await _storageService.uploadFile(file, storagePath);

      final messageId = await _chatRepo.sendMessage(
        chatId: _activeChatId!,
        content: 'Voice message',
        type: MessageType.voice,
        mediaUrl: downloadUrl,
        duration: duration,
        replyToId: replyMsg?.id,
        replyToContent: replyMsg?.content,
        replyToSenderId: replyMsg?.senderId,
      );

      // Cache the local path for the sender immediately
      MediaController.instance.markAsDownloaded(messageId, path);

      _scrollToBottom();
    } catch (e) {
      Get.snackbar('Error', 'Failed to send voice message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAudio = false;
          _isSending = false;
        });
      }
    }
  }

  Future<void> _downloadAudio(MessageModel message) async {
    if (message.mediaUrl == null || _downloadingIds.contains(message.id))
      return;

    try {
      _downloadingIds.add(message.id);

      final response = await http.get(Uri.parse(message.mediaUrl!));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/voice_${message.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);

        MediaController.instance.markAsDownloaded(message.id, path);
        if (mounted) setState(() {});
      } else {
        Get.snackbar('Error', 'Failed to download audio');
      }
    } catch (e) {
      print('Download Error: $e');
      Get.snackbar('Error', 'Failed to download audio: $e');
    } finally {
      _downloadingIds.remove(message.id);
    }
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

  void _addReaction(String messageId, String reaction) async {
    Get.back();
    if (_activeChatId == null) return;

    // Find message to toggle reaction
    final msg = _messages.firstWhereOrNull((m) => m.id == messageId);
    final newReaction = (msg?.reaction == reaction) ? null : reaction;

    await _chatRepo.addReaction(_activeChatId!, messageId, newReaction);
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(20.r),
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
          if (_isRecording) ...[
            _buildRecordingBackground(),
            _buildRecordingOverlay(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingBackground() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _isRecordingLocked ? () => _stopRecording(send: false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: Colors.black.withOpacity(_isRecording ? 0.6 : 0.0),
          child: BackdropFilter(
            filter: ColorFilter.mode(
              Colors.black.withOpacity(_isRecording ? 0.4 : 0.0),
              BlendMode.darken,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: NexoraColors.midnightDark.withOpacity(0.95),
      elevation: 0,
      leadingWidth: 40.w,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: EdgeInsets.only(left: 8.w),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: NexoraColors.textPrimary,
            size: 22.r,
          ),
        ),
      ),
      titleSpacing: 0,
      flexibleSpace: SizedBox(width: 10.w),
      title: GestureDetector(
        onTap: () => _showUserProfile(),
        child: Row(
          children: [
            _buildAvatar(),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: NexoraColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isVerified) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: const BoxDecoration(
                            color: NexoraColors.accentCyan,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 8.r,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
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
            padding: EdgeInsets.all(8.r),
            margin: EdgeInsets.only(right: 12.w),
            child: Icon(
              Icons.more_vert_rounded,
              color: NexoraColors.textSecondary,
              size: 22.r,
            ),
          ),
        ),
      ],
    );
  }

  void _showUserProfile() {
    Get.to(
      () => ProfileViewScreen(
        profile: ProfileModel(
          id: 'user_${widget.name.toLowerCase().replaceAll(' ', '_')}',
          name: widget.name,
          username: widget.name,
          email:
              '${widget.name.toLowerCase().replaceAll(' ', '.')}@example.com',
          avatar: widget.avatar,
          bio: 'Hey there! I\'m using Nexora 💜',
          year: '3rd Year',
          major: 'Computer Science',
          interests: const ['Music', 'Tech', 'Coffee', 'Gaming'],
          isOnline: true,
          spotifyTrackName: 'Espresso',
          spotifyArtist: 'Sabrina Carpenter',
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 45.r,
          height: 45.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [NexoraShadows.purpleGlow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
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
                      style: TextStyle(
                        fontSize: 20.sp,
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
              width: 12.r,
              height: 12.r,
              decoration: BoxDecoration(
                color: NexoraColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NexoraColors.midnightDark,
                  width: 2.w,
                ),
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
                  margin: EdgeInsets.only(right: 3.w),
                  width: 6.r,
                  height: 6.r,
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
          SizedBox(width: 4.w),
          Text(
            "typing...",
            style: TextStyle(
              color: NexoraColors.primaryPurple,
              fontSize: 10.sp,
            ),
          ),
        ],
      );
    }

    return Text(
      _isOnline ? "Online" : "Offline",
      style: TextStyle(
        color: _isOnline ? NexoraColors.success : NexoraColors.textMuted,
        fontSize: 10.sp,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GlassContainer(
            borderRadius: 20.r,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      width: 6.r,
                      height: 6.r,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildReplyPreview(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: NexoraColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.add,
                      color: NexoraColors.primaryPurple,
                      size: 24.r,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Text input
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 100.h),
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: NexoraColors.glassBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            style: TextStyle(
                              color: NexoraColors.textPrimary,
                              fontSize: 16.sp,
                            ),
                            maxLines: 5,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: "Message...",
                              hintStyle: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 16.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showEmojiPicker,
                          child: Padding(
                            padding: EdgeInsets.only(right: 8.w, bottom: 10.h),
                            child: Icon(
                              _showEmojiKeyboard
                                  ? Icons.keyboard_rounded
                                  : Icons.emoji_emotions_outlined,
                              color: _showEmojiKeyboard
                                  ? NexoraColors.primaryPurple
                                  : NexoraColors.textMuted,
                              size: 24.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Send or Voice button
                GestureDetector(
                  onTap: _isSending
                      ? null
                      : (hasText
                            ? _sendMessage
                            : (_isRecording
                                  ? () => _stopRecording()
                                  : null)), // Removed one-tap _startRecording(null)
                  onLongPressStart: (hasText || _isSending)
                      ? null
                      : _startRecording,
                  onLongPressMoveUpdate: (hasText || _isSending)
                      ? null
                      : _onLongPressMoveUpdate,
                  onLongPressEnd: (hasText || _isSending)
                      ? null
                      : (_) {
                          if (!_isRecordingLocked) _stopRecording();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      borderRadius: BorderRadius.circular(22.r),
                      boxShadow: [
                        BoxShadow(
                          color: NexoraColors.primaryPurple.withOpacity(0.4),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? Padding(
                            padding: EdgeInsets.all(12.r),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            hasText ? Icons.send_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 22.r,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      height: 250.h,
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: NexoraColors.glassBackground,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.backspace_rounded,
                      color: NexoraColors.textMuted,
                      size: 20.r,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 6.h,
                crossAxisSpacing: 6.w,
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
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: TextStyle(fontSize: 22.sp),
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
      padding: EdgeInsets.all(8.r),
      margin: EdgeInsets.only(right: 8.w),
      decoration: BoxDecoration(
        color: isActive
            ? NexoraColors.primaryPurple.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        icon,
        color: isActive ? NexoraColors.primaryPurple : NexoraColors.textMuted,
        size: 20.r,
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    final slideProgress = (_slideOffset / _cancelThreshold).clamp(0.0, 1.0);
    final lockProgress = (_verticalSlideOffset / _lockThreshold).clamp(
      0.0,
      1.0,
    );
    final isNearCancel = slideProgress > 0.7;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Lock Indicator (Slides up)
          if (!_isRecordingLocked && _isRecording && _slideOffset == 0)
            Positioned(
              right: 16.w,
              bottom: 100.h - (_verticalSlideOffset).abs(),
              child: AnimatedOpacity(
                opacity: (1.0 - (lockProgress * 0.7)).clamp(0.1, 1.0),
                duration: const Duration(milliseconds: 50),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: NexoraColors.primaryPurple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: NexoraColors.primaryPurple,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: NexoraColors.primaryPurple,
                      size: 20.r,
                    ),
                  ],
                ),
              ),
            ),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NexoraColors.midnightDark.withOpacity(0.95),
                  NexoraColors.midnightDark,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20.r,
                  offset: Offset(0, -5.h),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: NexoraColors.primaryPurple.withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Cancel button
                  GestureDetector(
                    onTap: () => _stopRecording(send: false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: (slideProgress > 0.3 || _isRecordingLocked)
                            ? NexoraColors.error.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (slideProgress > 0.3 || _isRecordingLocked)
                              ? NexoraColors.error.withOpacity(0.4)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Icon(
                        (slideProgress > 0.3 || _isRecordingLocked)
                            ? Icons.delete_rounded
                            : Icons.close_rounded,
                        color: (slideProgress > 0.3 || _isRecordingLocked)
                            ? NexoraColors.error
                            : Colors.white70,
                        size: 24.r,
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Recording Info
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      transform: Matrix4.translationValues(_slideOffset, 0, 0),
                      child: Row(
                        children: [
                          // Recording dot
                          _buildRecordingDot(),
                          SizedBox(width: 10.w),

                          // Timer
                          Text(
                            _formatDuration(_recordingDuration),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),

                          const Spacer(),

                          if (!_isRecordingLocked)
                            _buildSlideToCancel(slideProgress)
                          else
                            _buildLockedIndicator(),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Main Button
                  _buildMainRecordingButton(isNearCancel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingDot() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 12.r,
          height: 12.r,
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
                blurRadius: 8.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlideToCancel(double slideProgress) {
    return AnimatedOpacity(
      opacity: (1.0 - slideProgress * 1.5).clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-5.w * _pulseAnimation.value, 0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 14.r,
                ),
              );
            },
          ),
          SizedBox(width: 4.w),
          Text(
            'Slide to cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, color: NexoraColors.primaryPurple, size: 16.r),
        SizedBox(width: 6.w),
        Text(
          "Recording Locked",
          style: TextStyle(
            color: NexoraColors.primaryPurple,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMainRecordingButton(bool isNearCancel) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isNearCancel
            ? 0.85
            : (1.0 + (_pulseAnimation.value * 0.05));
        return Transform.translate(
          offset: Offset(
            0,
            (!_isRecordingLocked && _slideOffset == 0)
                ? _verticalSlideOffset.clamp(_lockThreshold, 0.0)
                : 0,
          ),
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: _isRecordingLocked ? () => _stopRecording() : null,
              child: Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  gradient: isNearCancel
                      ? const LinearGradient(
                          colors: [NexoraColors.error, NexoraColors.error],
                        )
                      : NexoraGradients.primaryButton,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isNearCancel
                                  ? NexoraColors.error
                                  : NexoraColors.primaryPurple)
                              .withOpacity(0.4),
                      blurRadius: 15.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecordingLocked ? Icons.send_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 28.r,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundPatterns() {
    return Stack(
      children: [
        // Large heart doodle top-left
        Positioned(
          top: 40.h,
          left: -20.w,
          child: Transform.rotate(
            angle: -0.3,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.favorite_outline,
                size: 100.r,
                color: NexoraColors.romanticPink,
              ),
            ),
          ),
        ),
        // Chat bubble top-right
        Positioned(
          top: 80.h,
          right: 20.w,
          child: Transform.rotate(
            angle: 0.2,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.chat_bubble_outline,
                size: 60.r,
                color: NexoraColors.primaryPurple,
              ),
            ),
          ),
        ),
        // Stars scattered
        Positioned(
          top: 150.h,
          left: 40.w,
          child: Opacity(
            opacity: 0.18,
            child: Icon(
              Icons.star_outline,
              size: 35.r,
              color: NexoraColors.accentCyan,
            ),
          ),
        ),
        Positioned(
          top: 220.h,
          right: 60.w,
          child: Transform.rotate(
            angle: 0.5,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.auto_awesome,
                size: 40.r,
                color: NexoraColors.romanticPink,
              ),
            ),
          ),
        ),
        // Paper plane
        Positioned(
          top: 300.h,
          left: 10.w,
          child: Transform.rotate(
            angle: 0.4,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.send_rounded,
                size: 45.r,
                color: NexoraColors.primaryPurple,
              ),
            ),
          ),
        ),
        // Small hearts
        Positioned(
          top: 380.h,
          right: 30.w,
          child: Opacity(
            opacity: 0.14,
            child: Icon(
              Icons.favorite,
              size: 25.r,
              color: NexoraColors.romanticPink,
            ),
          ),
        ),
        Positioned(
          top: 420.h,
          right: 80.w,
          child: Opacity(
            opacity: 0.10,
            child: Icon(
              Icons.favorite_outline,
              size: 20.r,
              color: NexoraColors.romanticPink,
            ),
          ),
        ),
        // Emoji doodle
        Positioned(
          bottom: 350.h,
          left: 50.w,
          child: Transform.rotate(
            angle: -0.2,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.emoji_emotions_outlined,
                size: 50.r,
                color: NexoraColors.accentCyan,
              ),
            ),
          ),
        ),
        // Message icons
        Positioned(
          bottom: 280.h,
          right: 20.w,
          child: Transform.rotate(
            angle: 0.3,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.mark_chat_unread_outlined,
                size: 55.r,
                color: NexoraColors.primaryPurple,
              ),
            ),
          ),
        ),
        // Music note
        Positioned(
          bottom: 200.h,
          left: 20.w,
          child: Opacity(
            opacity: 0.12,
            child: Icon(
              Icons.music_note_outlined,
              size: 40.r,
              color: NexoraColors.romanticPink,
            ),
          ),
        ),
        // Camera
        Positioned(
          bottom: 150.h,
          right: 70.w,
          child: Transform.rotate(
            angle: -0.15,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.camera_alt_outlined,
                size: 35.r,
                color: NexoraColors.accentCyan,
              ),
            ),
          ),
        ),
        // Sparkle
        Positioned(
          bottom: 100.h,
          left: 80.w,
          child: Opacity(
            opacity: 0.15,
            child: Icon(
              Icons.flare,
              size: 30.r,
              color: NexoraColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(MessageModel message, int index) {
    final isSender = message.senderId == _chatRepo.currentUserId;
    final showAvatar =
        !isSender &&
        (index == 0 || _messages[index - 1].senderId != message.senderId);
    final senderChanged =
        index > 0 && _messages[index - 1].senderId != message.senderId;

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        setState(() => _replyingToMessage = message);
        return false; // Don't actually dismiss
      },
      background: Container(
        padding: EdgeInsets.only(left: 20.w),
        alignment: Alignment.centerLeft,
        child: Icon(
          Icons.reply_rounded,
          color: NexoraColors.primaryPurple,
          size: 24.r,
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _showReactionSheet(message),
        child: Container(
          margin: EdgeInsets.only(
            left: isSender ? 60.w : 0,
            right: isSender ? 0 : 60.w,
            top: senderChanged ? 16.h : 0,
            bottom: 4.h,
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
                SizedBox(width: 38.w),
              Flexible(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: message.type == MessageType.voice
                          ? EdgeInsets.all(6.r)
                          : EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 6.h,
                            ),
                      decoration: BoxDecoration(
                        gradient: isSender
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  NexoraColors.deepPurple,
                                  NexoraColors.primaryPurple.withOpacity(0.9),
                                ],
                              )
                            : null,
                        color: isSender ? null : NexoraColors.glassBackground,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18.r),
                          topRight: Radius.circular(18.r),
                          bottomLeft: Radius.circular(isSender ? 18.r : 4.r),
                          bottomRight: Radius.circular(isSender ? 4.r : 18.r),
                        ),
                        border: isSender
                            ? null
                            : Border.all(color: NexoraColors.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: isSender
                                ? NexoraColors.primaryPurple.withOpacity(0.25)
                                : Colors.black.withOpacity(0.15),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (message.replyToContent != null)
                            _buildReplyContext(message),
                          if (message.type == MessageType.voice)
                            _buildAudioMessage(message)
                          else if (message.type == MessageType.image)
                            _buildImageMessage(message)
                          else
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isSender
                                    ? Colors.white
                                    : NexoraColors.textPrimary,
                                fontSize: 15.sp,
                                height: 1.2,
                              ),
                            ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  color: isSender
                                      ? Colors.white.withOpacity(0.7)
                                      : NexoraColors.textMuted,
                                  fontSize: 10.sp,
                                ),
                              ),
                              if (isSender) _buildStatusIcon(message),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (message.reaction != null)
                      Positioned(
                        bottom: -10.h,
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
      ),
    );
  }

  Widget _buildReplyContext(MessageModel message) {
    final isSender = message.senderId == _chatRepo.currentUserId;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: (isSender ? Colors.black : NexoraColors.primaryPurple)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(
            color: isSender ? Colors.white70 : NexoraColors.primaryPurple,
            width: 3.w,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderId == _chatRepo.currentUserId
                ? 'You'
                : widget.name,
            style: TextStyle(
              color: isSender ? Colors.white : NexoraColors.primaryPurple,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            message.replyToContent ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: (isSender ? Colors.white : NexoraColors.textPrimary)
                  .withOpacity(0.8),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingToMessage == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: NexoraColors.midnightDark.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: NexoraColors.glassBorder.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            color: NexoraColors.primaryPurple,
            size: 20.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyingToMessage!.senderId == _chatRepo.currentUserId
                      ? 'Replying to yourself'
                      : 'Replying to ${widget.name}',
                  style: TextStyle(
                    color: NexoraColors.primaryPurple,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _replyingToMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: NexoraColors.textMuted,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: NexoraColors.textMuted,
              size: 20.r,
            ),
            onPressed: () => setState(() => _replyingToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderAvatar() {
    return Container(
      width: 30.r,
      height: 30.r,
      margin: EdgeInsets.only(right: 8.w),
      child: ClipOval(
        child: widget.avatar.isNotEmpty
            ? Image.network(
                widget.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderAvatar(),
              )
            : _buildPlaceholderAvatar(),
      ),
    );
  }

  Widget _buildImageMessage(MessageModel message) {
    final bool isDownloaded = MediaController.instance.isDownloaded(message.id);

    if (!isDownloaded) {
      return GestureDetector(
        onTap: () => setState(
          () => MediaController.instance.markAsDownloaded(
            message.id,
            message.mediaUrl ?? '',
          ),
        ),
        child: Container(
          width: 200.w,
          height: 150.h,
          decoration: BoxDecoration(
            color: NexoraColors.glassBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: NexoraColors.glassBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download_rounded, color: Colors.white70, size: 30.r),
              SizedBox(height: 8.h),
              Text(
                "Tap to load image",
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (message.mediaUrl != null) {
          Get.to(
            () => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(message.mediaUrl!),
                ),
              ),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          constraints: BoxConstraints(maxHeight: 250.h),
          child: Image.network(
            message.mediaUrl ?? '',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: 200.h,
                width: 200.w,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.broken_image, size: 50.r, color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: NexoraGradients.primaryButton,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMessage(MessageModel message) {
    final isSender = message.senderId == _chatRepo.currentUserId;
    final bool isDownloaded = MediaController.instance.isDownloaded(message.id);
    final String? localPath = MediaController.instance.getLocalPath(message.id);
    final bool isPlaying =
        _currentlyPlayingId == message.id &&
        _playerState == PlayerState.playing;

    return Column(
      crossAxisAlignment: isSender
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 6.h, right: 4.w, left: 4.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic_none_rounded,
                size: 10.r,
                color: isSender
                    ? Colors.white.withOpacity(0.6)
                    : NexoraColors.accentCyan,
              ),
              SizedBox(width: 4.w),
              Text(
                "Voice Message",
                style: TextStyle(
                  color: isSender
                      ? Colors.white.withOpacity(0.6)
                      : NexoraColors.accentCyan,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          final isDownloading = _downloadingIds.contains(message.id);

          return Container(
            constraints: BoxConstraints(minWidth: 180.w, maxWidth: 220.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with Play/Download overlay (WhatsApp style)
                GestureDetector(
                  onTap: () async {
                    if (message.mediaUrl == null || isDownloading) return;

                    if (!isDownloaded) {
                      _downloadAudio(message);
                      return;
                    }

                    if (isPlaying) {
                      await _audioPlayer.pause();
                      setState(() => _playerState = PlayerState.paused);
                    } else {
                      if (_currentlyPlayingId == message.id) {
                        await _audioPlayer.resume();
                      } else {
                        await _audioPlayer.stop();
                        final source =
                            (localPath != null &&
                                await File(localPath).exists())
                            ? DeviceFileSource(localPath)
                            : UrlSource(message.mediaUrl!);
                        await _audioPlayer.play(source);
                        _currentlyPlayingId = message.id;
                      }
                      setState(() => _playerState = PlayerState.playing);

                      _audioPlayer.onPlayerComplete.listen((event) {
                        if (mounted) {
                          setState(() {
                            _playerState = PlayerState.stopped;
                            _currentlyPlayingId = null;
                          });
                        }
                      });
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Avatar background
                      Container(
                        width: 36.r,
                        height: 36.r,
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
                              blurRadius: 6.r,
                              offset: Offset(0, 2.h),
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
                                      fontSize: 9.sp,
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Play/Download/Loading button overlay
                      Container(
                        width: 28.r,
                        height: 28.r,
                        decoration: BoxDecoration(
                          gradient: isPlaying
                              ? NexoraGradients.romanticGlow
                              : (isSender
                                    ? NexoraGradients.primaryButton
                                    : null),
                          color: !isSender && !isPlaying
                              ? NexoraColors.romanticPink
                              : null,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isPlaying
                                          ? NexoraColors.romanticPink
                                          : Colors.black)
                                      .withOpacity(0.3),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: isDownloading
                            ? Center(
                                child: SizedBox(
                                  width: 14.r,
                                  height: 14.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.r,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                              )
                            : Icon(
                                !isDownloaded
                                    ? Icons.download_rounded
                                    : (isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded),
                                color: Colors.white,
                                size: 18.r,
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),

                // Waveform and duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Waveform visualization
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(28, (index) {
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
                            11,
                            8,
                            14,
                            20,
                            10,
                            16,
                            10,
                            14,
                            22,
                            12,
                            18,
                            11,
                            8,
                            14,
                            10,
                          ];
                          final height = heights[index % heights.length]
                              .toDouble();

                          return AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              // Animate height slightly if playing to give a "live" feel
                              final dynamicHeight = isPlaying
                                  ? height +
                                        (4 *
                                            (index % 2 == 0
                                                ? _pulseAnimation.value
                                                : (1 - _pulseAnimation.value)))
                                  : height;

                              return Container(
                                width: 2.5.w,
                                height: dynamicHeight.h,
                                margin: EdgeInsets.only(right: 1.w),
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? (isSender
                                            ? Colors.white
                                            : NexoraColors.accentCyan)
                                      : (isSender
                                            ? Colors.white.withOpacity(0.3)
                                            : NexoraColors.textMuted
                                                  .withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(2.r),
                                  boxShadow: isPlaying
                                      ? [
                                          BoxShadow(
                                            color:
                                                (isSender
                                                        ? Colors.white
                                                        : NexoraColors
                                                              .accentCyan)
                                                    .withOpacity(0.3),
                                            blurRadius: 4.r,
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                      SizedBox(height: 6.h),

                      // Duration row
                      Row(
                        children: [
                          // Duration
                          Text(
                            !isDownloaded && !isDownloading
                                ? "Tap to download"
                                : _formatDuration(message.duration ?? 0),
                            style: TextStyle(
                              color: isSender
                                  ? Colors.white.withOpacity(0.8)
                                  : NexoraColors.textMuted,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Mic icon indicator
                          Icon(
                            Icons.mic_rounded,
                            size: 14.r,
                            color: isSender
                                ? Colors.white.withOpacity(0.6)
                                : NexoraColors.accentCyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusIcon(MessageModel message) {
    IconData icon = Icons.done_rounded;
    Color color = Colors.white.withOpacity(0.6);

    if (message.isRead) {
      icon = Icons.done_all_rounded;
      color = NexoraColors.accentCyan;
    } else if (message.isDelivered) {
      icon = Icons.done_all_rounded;
    }

    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Icon(icon, size: 14.r, color: color),
    );
  }

  Widget _buildReactionBadge(String reaction) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: NexoraColors.midnightPurple,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: NexoraColors.primaryPurple.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Text(reaction, style: TextStyle(fontSize: 14.sp)),
    );
  }

  void _showReactionSheet(MessageModel message) {
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
                // Handle
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "React to message",
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
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
                SizedBox(height: 12.h),
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
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: NexoraColors.glassBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: NexoraColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Text(reaction, style: TextStyle(fontSize: 24.sp)),
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
                // Handle
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),

                // Title
                Text(
                  'Share Content',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Choose what you want to share',
                  style: TextStyle(
                    color: NexoraColors.textMuted,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 28.h),

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
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: NexoraColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachment(String type) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (type == 'gallery') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else if (type == 'camera') {
      pickedFile = await picker.pickImage(source: ImageSource.camera);
    }

    if (pickedFile != null && widget.chatId != null) {
      Get.back(); // Close modal
      try {
        final file = File(pickedFile.path);
        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storagePath = 'chats/${widget.chatId}/images/$fileName';

        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        final downloadUrl = await _storageService.uploadFile(file, storagePath);
        Get.back(); // Close loading

        _chatRepo.sendMessage(
          chatId: widget.chatId!,
          content: 'Sent an image',
          type: MessageType.image,
          mediaUrl: downloadUrl,
        );
        _scrollToBottom();
      } catch (e) {
        Get.back(); // Close loading
        Get.snackbar('Error', 'Failed to upload image');
      }
    } else {
      Get.back();
    }
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
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
                padding: EdgeInsets.only(top: 12.h),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NexoraColors.glassBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User info header
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
                                        style: TextStyle(
                                          fontSize: 24.sp,
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
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.name,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: NexoraColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Chat options',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: NexoraColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      _buildOptionItem(
                        Icons.notifications_off_rounded,
                        'Mute notifications',
                        NexoraColors.textSecondary,
                        () => Get.back(),
                      ),

                      Divider(color: NexoraColors.glassBorder, height: 24.h),
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
                      SizedBox(height: 8.h),
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
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}
