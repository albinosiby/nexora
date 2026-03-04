import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/nexora_theme.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/chat/screens/chat_detail_screen.dart';
import '../../modules/notifications/screens/notification_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Must initialize Firebase in the background isolate first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    }

    // Required on iOS to show foreground notifications as banners
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set background message handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle initial message when app is opened from a terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Received foreground message: ${message.notification?.title} - ${message.notification?.body}',
      );

      final notification = message.notification;
      if (notification != null) {
        Get.snackbar(
          notification.title ?? 'Nexora',
          notification.body ?? '',
          snackPosition: SnackPosition.TOP,
          backgroundColor: NexoraColors.cardSurface.withOpacity(0.95),
          colorText: NexoraColors.textPrimary,
          margin: EdgeInsets.all(16.r),
          borderRadius: 16.r,
          duration: const Duration(seconds: 4),
          onTap: (_) => _handleMessage(message),
          icon: Icon(
            Icons.notifications_active_rounded,
            color: NexoraColors.primaryOrange,
          ),
          boxShadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
      }
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
    } else if (data['type'] == 'like' ||
        data['type'] == 'comment' ||
        data['type'] == 'mention' ||
        data['type'] == 'feed') {
      // Redirect to notifications for context, or a single post view if available
      Get.to(() => const NotificationScreen());
    } else if (data['type'] == 'connectionRequest' ||
        data['type'] == 'match' ||
        data['type'] == 'connection') {
      Get.to(() => const NotificationScreen());
    }
  }
}
