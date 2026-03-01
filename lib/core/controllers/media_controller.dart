import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaController extends GetxController {
  static MediaController get instance => Get.find<MediaController>();

  static const String _storageKey = 'downloaded_media_ids';
  late SharedPreferences _prefs;

  // Use a reactive Map to track downloaded media IDs and their local paths
  final RxMap<String, String> _downloadedPaths = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String>? storedEntries = _prefs.getStringList(_storageKey);
    if (storedEntries != null) {
      final Map<String, String> loadedPaths = {};
      for (var entry in storedEntries) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          loadedPaths[parts[0]] = parts[1];
        }
      }
      _downloadedPaths.assignAll(loadedPaths);
    }
  }

  bool isDownloaded(String id) => _downloadedPaths.containsKey(id);

  String? getLocalPath(String id) => _downloadedPaths[id];

  void markAsDownloaded(String id, String path) {
    if (_downloadedPaths[id] != path) {
      _downloadedPaths[id] = path;
      _saveToPrefs();
    }
  }

  Future<void> _saveToPrefs() async {
    final List<String> entriesToSave = _downloadedPaths.entries
        .map((e) => '${e.key}|${e.value}')
        .toList();
    await _prefs.setStringList(_storageKey, entriesToSave);
  }

  void clearCache() {
    _downloadedPaths.clear();
    _saveToPrefs();
  }
}
