import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/nexora_theme.dart';
import 'core/services/dummy_database.dart';
import 'modules/auth/screens/splash_screen.dart';
import 'modules/connections/repositories/connection_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'modules/auth/repositories/auth_repository.dart';
import 'modules/feed/repositories/feed_repo.dart';
import 'modules/profile/repositories/user_repository.dart';
import 'modules/chat/repositories/chat_repository.dart';
import 'modules/discover/repositories/match_repository.dart';
import 'modules/discover/controllers/match_controller.dart';
import 'core/services/spotify_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize services
  Get.put(DummyDatabase()); // Initialize dummy database first
  Get.put(AuthRepository());
  Get.put(PostRepository());
  Get.put(UserRepository());
  Get.put(ChatRepository());
  Get.put(MatchRepository());
  Get.put(MatchController());
  Get.put(SpotifyService());
  Get.put(StorageService());
  Get.put(ConnectionService());

  runApp(const CampusApp());
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
          debugShowCheckedModeBanner: false,
          title: 'NEXORA',
          themeMode: ThemeMode.dark,
          theme: NexoraTheme.darkTheme,
          darkTheme: NexoraTheme.darkTheme,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
          home: const SplashScreen(),
        );
      },
    );
  }
}
