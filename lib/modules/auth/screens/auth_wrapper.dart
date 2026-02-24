import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'user_details_screen.dart';
import '../../../core/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = AuthRepository.instance;
      final firebaseUser = auth.user;
      final profile = auth.currentUserProfile;
      final isLoading = auth.isProfileLoading;
      final showOnboarding = auth.showOnboarding;

      if (showOnboarding) {
        return const OnboardingScreen();
      }

      if (firebaseUser == null) {
        return const LoginScreen();
      }

      if (isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (profile == null) {
        return UserDetailsScreen(phoneNumber: firebaseUser.phoneNumber ?? '');
      }

      return const MainScreen();
    });
  }
}
