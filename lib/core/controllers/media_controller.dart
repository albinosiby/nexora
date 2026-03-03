import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaController extends Notifier<Map<String, String>> {
  static const String _storageKey = 'downloaded_media_ids';
  late SharedPreferences _prefs;

  @override
  Map<String, String> build() {
    _loadFromPrefs();
    return {};
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
      state = loadedPaths;
    }
  }

  bool isDownloaded(String id) => state.containsKey(id);

  String? getLocalPath(String id) => state[id];

  void markAsDownloaded(String id, String path) {
    if (state[id] != path) {
      state = {...state, id: path};
      _saveToPrefs();
    }
  }

  Future<void> _saveToPrefs() async {
    final List<String> entriesToSave = state.entries
        .map((e) => '${e.key}|${e.value}')
        .toList();
    await _prefs.setStringList(_storageKey, entriesToSave);
  }

  void clearCache() {
    state = {};
    _saveToPrefs();
  }
}

final mediaControllerProvider =
    NotifierProvider<MediaController, Map<String, String>>(() {
      return MediaController();
    });
