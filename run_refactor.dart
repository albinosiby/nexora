import 'dart:io';

void main() {
  final file = File(
    r'd:\programs\flutter\nexora\lib\modules\chat\screens\chat_detail_screen.dart',
  );
  String text = file.readAsStringSync();

  // Replace dependencies
  text = text.replaceAll(
    "import 'package:get/get.dart';",
    "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../providers/chat_provider.dart';\nimport 'package:get/get.dart' show firstWhereOrNull; // For extension",
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

  // We are NOT doing full Get.to removal in one go, because it misses some named params.
  // Let's use simple string replacements for the most common ones.
  text = text.replaceAll('Get.back()', 'Navigator.pop(context)');
  text = text.replaceAll('Get.back();', 'Navigator.pop(context);');

  // Basic regexes
  text = text.replaceAllMapped(
    RegExp(r"Get\.snackbar\(\s*'(.*?)'\s*,\s*'(.*?)'\s*\);"),
    (match) {
      return "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${match.group(1)}: ${match.group(2)}')));";
    },
  );

  text = text.replaceAllMapped(
    RegExp(r"Get\.snackbar\(\s*'(.*?)'\s*,\s*(.*?)\s*\);"),
    (match) {
      return "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${match.group(1)}: ' + (${match.group(2)}).toString())));";
    },
  );

  text = text.replaceAllMapped(
    RegExp(r"Get\.to\(\s*\(\)\s*=>\s*(.*?),\s*transition.*?\);"),
    (match) {
      return "Navigator.push(context, MaterialPageRoute(builder: (context) => ${match.group(1)}));";
    },
  );
  text = text.replaceAllMapped(RegExp(r"Get\.to\(\s*\(\)\s*=>\s*(.*?)\);"), (
    match,
  ) {
    return "Navigator.push(context, MaterialPageRoute(builder: (context) => ${match.group(1)}));";
  });

  text = text.replaceAllMapped(RegExp(r"Get\.dialog\(([\s\S]*?)\);"), (match) {
    return "showDialog(context: context, builder: (context) => ${match.group(1)});";
  });

  file.writeAsStringSync(text);
  print('Refined replacements complete.');
}
