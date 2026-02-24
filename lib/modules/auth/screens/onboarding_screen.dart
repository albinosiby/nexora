import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../repositories/auth_repository.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Real-time Matching',
      description:
          'Find your perfect campus match with our real-time discovery and Spotify integration.',
      icon: Icons.favorite_rounded,
      color: NexoraColors.romanticPink,
    ),
    OnboardingData(
      title: 'Discover Connections',
      description:
          'Connect with students based on your major, year, and mutual interests.',
      icon: Icons.people_alt_rounded,
      color: NexoraColors.primaryPurple,
    ),
    OnboardingData(
      title: 'Multimedia Chat',
      description:
          'Express yourself better with voice messages, images, and quick reactions.',
      icon: Icons.chat_bubble_rounded,
      color: NexoraColors.accentCyan,
    ),
  ];

  Future<void> _completeOnboarding() async {
    await AuthRepository.instance.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),

            // Bottom navigation and indicators
            Positioned(
              bottom: 50.h,
              left: 30.w,
              right: 30.w,
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index == _currentPage),
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: NexoraTextStyles.bodyMedium.copyWith(
                            color: NexoraColors.textMuted,
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          if (_currentPage == _pages.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: NexoraGradients.primaryButton,
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [NexoraShadows.purpleGlow],
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: NexoraTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: EdgeInsets.all(40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.color.withOpacity(0.3),
                width: 2.w,
              ),
            ),
            child: Icon(data.icon, size: 100.sp, color: data.color),
          ),
          SizedBox(height: 60.h),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: NexoraTextStyles.headline1.copyWith(
              fontSize: 28.sp,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: NexoraTextStyles.bodyLarge.copyWith(
              color: NexoraColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      height: 8.h,
      width: isActive ? 24.w : 8.w,
      decoration: BoxDecoration(
        color: isActive
            ? NexoraColors.primaryPurple
            : NexoraColors.textMuted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
