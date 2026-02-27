import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../modules/auth/repositories/auth_repository.dart';

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
    // Navigate based on message data
    final data = message.data;
    if (data['type'] == 'chat') {
      // Navigate to chat detail
      final chatId = data['chatId'];
      if (chatId != null) {
        // Logic to navigate if needed, but usually handled by user tapping notification
      }
    } else if (data['type'] == 'connection') {
      // Navigate to connections screen
    }
  }
}
