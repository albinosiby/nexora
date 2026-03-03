import 'dart:io';

void main() {
  final file = File(
    r'd:\programs\flutter\nexora\lib\modules\chat\screens\chat_detail_screen.dart',
  );
  String text = file.readAsStringSync();

  // 1. Imports and Basic Refactoring
  text = text.replaceAll(
    "import 'package:get/get.dart';",
    "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../providers/chat_provider.dart';\nimport 'package:get/get.dart' show firstWhereOrNull;",
  );

  text = text.replaceAll(
    'class ChatDetailScreen extends StatefulWidget',
    'class ChatDetailScreen extends ConsumerStatefulWidget',
  );
  text = text.replaceAll(
    'State<ChatDetailScreen> createState() =>',
    'ConsumerState<ChatDetailScreen> createState() =>',
  );
  text = text.replaceAll(
    'class _ChatDetailScreenState extends State<ChatDetailScreen>',
    'class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>',
  );
  text = text.replaceAll(
    'final ChatRepository _chatRepo = ChatRepository.instance;',
    'late final ChatRepository _chatRepo = ref.read(chatRepositoryProvider);',
  );

  text = text.replaceAll('Get.back()', 'Navigator.pop(context)');
  text = text.replaceAll('Get.back();', 'Navigator.pop(context);');

  // Simple string replacements for UI methods so we don't mess up brackets
  text = text.replaceAll(
    "Get.snackbar(\n          'Permission Denied',\n          'Please enable microphone access in settings to send voice messages',\n          backgroundColor: Colors.red.withOpacity(0.8),\n          colorText: Colors.white,\n        );",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission Denied: Please enable microphone access')));",
  );

  text = text.replaceAll(
    "Get.snackbar(\n          'Message too short',\n          'Hold to record, release to send',\n          backgroundColor: NexoraColors.textMuted.withOpacity(0.9),\n          colorText: Colors.white,\n          snackPosition: SnackPosition.TOP,\n          duration: const Duration(seconds: 1),\n        );",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message too short')));",
  );

  text = text.replaceAll(
    "Get.snackbar(\n      'Cancelled',\n      'Voice message discarded',\n      backgroundColor: NexoraColors.textMuted.withOpacity(0.9),\n      colorText: Colors.white,\n      snackPosition: SnackPosition.TOP,\n      duration: const Duration(seconds: 1),\n      margin: EdgeInsets.all(16.w),\n      borderRadius: 12.r,\n    );",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancelled: Voice message discarded')));",
  );

  text = text.replaceAll(
    "Get.snackbar(\n                              newMuted ? 'Muted' : 'Unmuted',\n                              newMuted\n                                  ? 'Notifications muted for this chat'\n                                  : 'Notifications enabled for this chat',\n                              backgroundColor: NexoraColors.glassBackground,\n                              colorText: Colors.white,\n                              snackPosition: SnackPosition.TOP,\n                              duration: const Duration(seconds: 2),\n                              margin: EdgeInsets.all(16.r),\n                              borderRadius: 12.r,\n                              icon: Padding(\n                                padding: EdgeInsets.only(left: 12.w),\n                                child: Icon(\n                                  newMuted\n                                      ? Icons.notifications_off_rounded\n                                      : Icons.notifications_rounded,\n                                  color: Colors.white,\n                                ),\n                              ),\n                            );",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newMuted ? 'Muted' : 'Unmuted')));",
  );

  text = text.replaceAll(
    "Get.snackbar(\n                  'Cleared',\n                  'Chat history has been cleared',\n                  backgroundColor: NexoraColors.warning.withOpacity(0.9),\n                  colorText: Colors.white,\n                  snackPosition: SnackPosition.TOP,\n                  duration: const Duration(seconds: 2),\n                  margin: EdgeInsets.all(16.r),\n                  borderRadius: 12.r,\n                );",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleared: Chat history has been cleared')));",
  );

  text = text.replaceAll(
    "Get.snackbar(\n                  'Blocked',\n                  '\${widget.name} has been blocked',\n                  backgroundColor: NexoraColors.error.withOpacity(0.9),\n                  colorText: Colors.white,\n                  snackPosition: SnackPosition.TOP,\n                  duration: const Duration(seconds: 2),\n                  margin: EdgeInsets.all(16.r),\n                  borderRadius: 12.r,\n                );",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blocked: \${widget.name} has been blocked')));",
  );

  text = text.replaceAll(
    "Get.snackbar(\n                          'Reported',\n                          'Your report has been submitted. We\\'ll review it shortly.',\n                          backgroundColor: NexoraColors.glassBackground,\n                          colorText: Colors.white,\n                          snackPosition: SnackPosition.TOP,\n                          duration: const Duration(seconds: 3),\n                          margin: EdgeInsets.all(16.r),\n                          borderRadius: 12.r,\n                          icon: Padding(\n                            padding: EdgeInsets.only(left: 12.w),\n                            child: const Icon(\n                              Icons.flag_rounded,\n                              color: Colors.white,\n                            ),\n                          ),\n                        );",
    "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reported: Your report has been submitted. We\\'ll review it shortly.')));",
  );

  text = text.replaceAll(
    "Get.to(\n      () => ProfileViewScreen(\n        profile: ProfileModel(\n          id: 'user_\${widget.name.toLowerCase().replaceAll(' ', '_')}',\n          name: widget.name,\n          username: widget.name,\n          email:\n              '\${widget.name.toLowerCase().replaceAll(' ', '.')}@example.com',\n          avatar: widget.avatar,\n          bio: 'Hey there! I\\'m using Nexora 💜',\n          year: '3rd Year',\n          major: 'Computer Science',\n          interests: const ['Music', 'Tech', 'Coffee', 'Gaming'],\n          isOnline: true,\n          spotifyTrackName: 'Espresso',\n          spotifyArtist: 'Sabrina Carpenter',\n        ),\n      ),\n    );",
    "Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileViewScreen(\n        profile: ProfileModel(\n          id: 'user_\${widget.name.toLowerCase().replaceAll(' ', '_')}',\n          name: widget.name,\n          username: widget.name,\n          email:\n              '\${widget.name.toLowerCase().replaceAll(' ', '.')}@example.com',\n          avatar: widget.avatar,\n          bio: 'Hey there! I\\'m using Nexora 💜',\n          year: '3rd Year',\n          major: 'Computer Science',\n          interests: const ['Music', 'Tech', 'Coffee', 'Gaming'],\n          isOnline: true,\n          spotifyTrackName: 'Espresso',\n          spotifyArtist: 'Sabrina Carpenter',\n        ),\n      )));",
  );

  text = text.replaceAll(
    "Get.to(\n            () => Scaffold(\n              backgroundColor: Colors.black,\n              appBar: AppBar(\n                backgroundColor: Colors.transparent,\n                leading: IconButton(\n                  icon: const Icon(Icons.close, color: Colors.white),\n                  onPressed: () => Navigator.pop(context),\n                ),\n              ),\n              body: Center(\n                child: InteractiveViewer(\n                  child: Image.network(message.mediaUrl!),\n                ),\n              ),\n            ),\n          );",
    "Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(\n              backgroundColor: Colors.black,\n              appBar: AppBar(\n                backgroundColor: Colors.transparent,\n                leading: IconButton(\n                  icon: const Icon(Icons.close, color: Colors.white),\n                  onPressed: () => Navigator.pop(context),\n                ),\n              ),\n              body: Center(\n                child: InteractiveViewer(\n                  child: Image.network(message.mediaUrl!),\n                ),\n              ),\n            )));",
  );

  text = text.replaceAll("showBottomSheet", "showModalBottomSheet");

  // Migrating messages to riverpod Consumer
  text = text.replaceAll('List<MessageModel> _messages = [];\n', '');
  text = text.replaceAll(
    'StreamSubscription<List<MessageModel>>? _messageSubscription;\n',
    '',
  );
  text = text.replaceAll(
    '    _messageSubscription?.cancel();\n',
    '',
  ); // two occurrences
  text = text.replaceAll(
    'final msg = _messages.firstWhereOrNull((m) => m.id == messageId);',
    'final messages = ref.read(chatMessagesProvider(_activeChatId!)).value ?? [];\n    final msg = messages.firstWhereOrNull((m) => m.id == messageId);',
  );

  text = text.replaceAll(
    'Widget _buildMessageBubble(MessageModel message, int index) {',
    'Widget _buildMessageBubble(MessageModel message, int index, List<MessageModel> _messages) {',
  );

  final setupStreamsTarget = '''      // Message stream
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
      );''';
  text = text.replaceAll(setupStreamsTarget, '');

  final buildTarget = '''  @override
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
              ),''';
  final buildReplacement = '''  @override
  Widget build(BuildContext context) {
    if (_activeChatId != null) {
      ref.listen(chatMessagesProvider(_activeChatId!), (previous, next) {
        if (next.hasValue && next.value!.isNotEmpty) {
          Future.microtask(() {
            _scrollToBottom();
          });
          _chatRepo.markMessagesAsDelivered(_activeChatId!);
          _chatRepo.markAsRead(_activeChatId!);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackgroundPatterns(),
          Column(
            children: [
              Expanded(
                child: _activeChatId == null
                    ? const Center(child: CircularProgressIndicator())
                    : Consumer(
                        builder: (context, ref, child) {
                          final messagesAsyncValue = ref.watch(chatMessagesProvider(_activeChatId!));
                          
                          return messagesAsyncValue.when(
                            data: (messages) {
                              if (messages.isEmpty) {
                                return const Center(child: Text('No messages yet', style: TextStyle(color: Colors.white70)));
                              }
                              return ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(20.r),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  return _buildMessageBubble(messages[index], index, messages);
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, st) => Center(child: Text('Error')),
                          );
                        },
                      ),
              ),''';
  text = text.replaceAll(buildTarget, buildReplacement);

  file.writeAsStringSync(text);
  print('Safe fast migration complete.');
}
