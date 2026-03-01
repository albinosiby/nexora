import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/chat/screens/chat_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` first.
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService extends GetxService {
  static PushNotificationService get instance => Get.find();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission (iOS/Web)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle initial message when app is opened from a terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.body}');
      // NotificationController takes care of showing in-app snackbars via Firestore snapshots,
      // so we don't necessarily need to show another one here unless we want to handle data-only payloads.
    });

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((token) {
      AuthRepository.instance.saveFcmToken(token);
    });

    // Initial token save if user is already logged in
    final token = await _fcm.getToken();
    if (token != null) {
      AuthRepository.instance.saveFcmToken(token);
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (AuthRepository.instance.user == null) return;

    final data = message.data;
    if (data['type'] == 'chat') {
      final chatId = data['chatId'];
      final senderId = data['senderId'];
      final senderName = data['senderName'] ?? "Nexora User";
      final senderAvatar = data['senderAvatar'] ?? "";

      if (chatId != null && senderId != null) {
        Get.to(
          () => ChatDetailScreen(
            chatId: chatId,
            participantId: senderId,
            name: senderName,
            avatar: senderAvatar,
          ),
          preventDuplicates: false,
        );
      }
    } else if (data['type'] == 'connection') {
      // In a real app, you might want to find the ConnectionsScreen in the stack or use a specific route
      // For now, let's just go to the screen
      // Get.to(() => const ConnectionsScreen());
    }
  }
}
