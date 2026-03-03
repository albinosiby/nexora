import 'dart:io';

void main() {
  final file = File(
    r'd:\programs\flutter\nexora\lib\modules\chat\screens\chat_detail_screen.dart',
  );
  String text = file.readAsStringSync();

  // 1. Remove _messages variable
  text = text.replaceAll('List<MessageModel> _messages = [];\n', '');

  // 2. Remove _messageSubscription from fields and dispose
  text = text.replaceAll(
    'StreamSubscription<List<MessageModel>>? _messageSubscription;\n',
    '',
  );
  text = text.replaceAll('_messageSubscription?.cancel();\n', '');

  // 3. Setup _messages in _setupStreams
  // We'll replace the block that sets up _messageSubscription with empty string using a regex
  final streamBlockRegex = RegExp(r"// Message stream.*?\);", dotAll: true);
  text = text.replaceAll(streamBlockRegex, '');

  // 4. Update _addReaction
  text = text.replaceAll(
    'final msg = _messages.firstWhereOrNull((m) => m.id == messageId);',
    'if (_activeChatId == null) return;\n    final messages = ref.read(chatMessagesProvider(_activeChatId!)).value ?? [];\n    final msg = messages.firstWhereOrNull((m) => m.id == messageId);',
  );

  // 5. Update build method to include ref.listen and Consumer
  // First, find the start of the build method
  text = text.replaceAll(
    'Widget build(BuildContext context) {',
    '''Widget build(BuildContext context) {
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
    }''',
  );

  // 6. Wrap ListView.builder in a Consumer
  final listViewStr = '''              Expanded(
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

  final replacementListViewStr = '''              Expanded(
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
                            error: (e, st) => Center(child: Text('Error: \$e', style: const TextStyle(color: Colors.red))),
                          );
                        },
                      ),
              ),''';
  text = text.replaceAll(listViewStr, replacementListViewStr);

  // 7. Update _buildMessageBubble signature and usages
  text = text.replaceAll(
    'Widget _buildMessageBubble(MessageModel message, int index) {',
    'Widget _buildMessageBubble(MessageModel message, int index, List<MessageModel> _messages) {',
  );

  file.writeAsStringSync(text);
  print('Refactored message provider successfully.');
}
