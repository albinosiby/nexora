import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/nexora_theme.dart';
import 'core/services/dummy_database.dart';
import 'modules/auth/screens/splash_screen.dart';
import 'modules/connections/repositories/connection_service.dart';

void main() {
  // Initialize services
  Get.put(DummyDatabase()); // Initialize dummy database first
  final connectionService = Get.put(ConnectionService());
  connectionService.initMockData();

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
