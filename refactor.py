import sys, re

file_path = r'd:\programs\flutter\nexora\lib\modules\chat\screens\chat_detail_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Imports and DI
text = text.replace("import 'package:get/get.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../providers/chat_provider.dart';")
text = text.replace('class ChatDetailScreen extends StatefulWidget', 'class ChatDetailScreen extends ConsumerStatefulWidget')
text = text.replace('State<ChatDetailScreen> createState() =>', 'ConsumerState<ChatDetailScreen> createState() =>')
text = text.replace('class _ChatDetailScreenState extends State<ChatDetailScreen>', 'class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>')
text = text.replace('final ChatRepository _chatRepo = ChatRepository.instance;', 'late final ChatRepository _chatRepo = ref.read(chatRepositoryProvider);')

# Safe GetX Replacements for simple things
text = text.replace('Get.back()', 'Navigator.pop(context)')

# Regex replacements for UI methods
text = re.sub(
    r"Get\.snackbar\(\s*['\"](.*?)['\"]\s*,\s*['\"](.*?)['\"]\s*\)",
    r"ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\1: \2')))",
    text
)
# Note: Get.snackbar with nested vars like $e can get tricky with python regex, 
# so let's stick to basic replacement if possible or allow generic matching.
text = re.sub(
    r"Get\.snackbar\((.*?),\s*(.*?)\)",
    r"ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(\1 + ': ' + \2)))",
    text
)

text = re.sub(
    r"Get\.to\(\s*\(\)\s*=>\s*(.*?),\s*transition.*?\)",
    r"Navigator.push(context, MaterialPageRoute(builder: (context) => \1))",
    text
)
text = re.sub(
    r"Get\.to\(\s*\(\)\s*=>\s*(.*?)\)",
    r"Navigator.push(context, MaterialPageRoute(builder: (context) => \1))",
    text
)

# Fix double string concat issues if they happen
text = text.replace("Text('Error' + ': ' + '", "Text('Error: ")
text = text.replace("Text('Success' + ': ' + '", "Text('Success: ")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Refactored GetX calls safely.')
