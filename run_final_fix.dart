import 'dart:io';

void main() {
  final file = File(
    r'd:\programs\flutter\nexora\lib\modules\chat\screens\chat_detail_screen.dart',
  );
  String text = file.readAsStringSync();

  // 1. Remove Get dependency for firstWhereOrNull since we use .where().firstOrNull
  text = text.replaceAll(
    "import 'package:get/get.dart' show firstWhereOrNull;",
    '',
  );

  // 2. RxSet -> Set
  text = text.replaceAll(
    'final RxSet<String> _downloadingIds = <String>{}.obs;',
    'final Set<String> _downloadingIds = {};',
  );

  // 3. Obx -> Builder
  text = text.replaceAll('Obx(() {', 'Builder(builder: (context) {');

  // 4. SetState around _downloadingIds.add
  text = text.replaceAll(
    '_downloadingIds.add(message.id);',
    'setState(() => _downloadingIds.add(message.id));',
  );

  // 5. SetState around _downloadingIds.remove
  text = text.replaceAll(
    '_downloadingIds.remove(message.id);',
    'setState(() => _downloadingIds.remove(message.id));',
  );

  // 6. Fix Get.dialog and Get.snackbar near _handleAttachment
  text = text.replaceAll(
    '''        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );''',
    '''        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );''',
  );

  text = text.replaceAll(
    "Get.snackbar('Error', 'Failed to upload image');",
    "ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Failed to upload image')));",
  );

  file.writeAsStringSync(text);
  print('Final fix complete.');
}
