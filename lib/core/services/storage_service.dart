import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

class StorageService extends GetxService {
  static StorageService get instance => Get.find<StorageService>();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage and return the download URL
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Firebase Storage Upload Error: $e');
      rethrow;
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Firebase Storage Delete Error: $e');
      rethrow;
    }
  }
}
