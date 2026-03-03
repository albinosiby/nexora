import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/nexora_theme.dart';
import 'modules/auth/screens/splash_screen.dart';
import 'modules/connections/repositories/connection_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'modules/auth/repositories/auth_repository.dart';
import 'modules/feed/repositories/feed_repo.dart';
import 'modules/profile/repositories/user_repository.dart';
import 'modules/chat/repositories/chat_repository.dart';
import 'modules/discover/repositories/match_repository.dart';
import 'modules/discover/controllers/match_controller.dart';
import 'modules/notifications/controllers/notification_controller.dart';
import 'core/services/storage_service.dart';
import 'core/services/push_notification_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Realtime Database persistence
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
    100 * 1024 * 1024,
  ); // 100MB

  // Initialize services
  Get.put(AuthRepository());
  Get.put(PostRepository());
  Get.put(UserRepository());
  Get.put(ChatRepository());
  Get.put(MatchRepository());
  Get.put(MatchController());

  Get.put(StorageService());
  Get.put(ConnectionService());
  Get.put(NotificationController());

  // Push Notifications
  final pushService = Get.put(PushNotificationService());
  await pushService.init();

  runApp(const ProviderScope(child: CampusApp()));
}

class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Nexora',
          debugShowCheckedModeBanner: false,
          theme: NexoraTheme.lightTheme,
          darkTheme: NexoraTheme.darkTheme,
          themeMode: ThemeMode.system,
          defaultTransition: Transition.cupertino,
          home: const SplashScreen(),
        );
      },
    );
  }
}
