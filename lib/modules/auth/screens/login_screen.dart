import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _currentStep = 0; // 0 = phone, 1 = OTP
  bool _isLoading = false;
  String? _errorMessage;

  // Firebase Auth fields
  String? _verificationId;

  Future<void> _sendOtp() async {
    if (phoneController.text.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthRepository.instance.signInWithPhoneNumber(
        phoneController.text.trim(),
        onCodeSent: (verificationId) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
            _currentStep = 1;
          });
          Get.snackbar(
            'OTP Sent',
            'Please check your messages',
            backgroundColor: NexoraColors.success.withOpacity(0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          // Focus first OTP field
          WidgetsBinding.instance.addPostFrameCallback((_) {
            otpFocusNodes[0].requestFocus();
          });
        },
        onVerificationFailed: (e) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                e.message ?? 'Verification failed. Please try again.';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = otpControllers.map((c) => c.text).join();

    if (enteredOtp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification ID missing. Please resend OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await AuthRepository.instance.verifyOtp(
        _verificationId!,
        enteredOtp,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userPhone', phoneController.text);
        await prefs.setString('userId', firebaseUser.uid);

        setState(() {
          _isLoading = false;
        });
        // Navigation is handled by AuthWrapper
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid OTP or session expired. Please try again.';
      });
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 90.r,
                    height: 90.r,
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [NexoraShadows.purpleGlow],
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: NexoraColors.textPrimary,
                      size: 45.r,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text("Kootu", style: NexoraTextStyles.logoStyle),
                  SizedBox(height: 8.h),
                  Text(
                    "WHERE CAMPUS HEARTS CONNECT",
                    style: NexoraTextStyles.taglineStyle,
                  ),
                  SizedBox(height: 40.h),

                  // Main Card
                  GlassContainer(
                    borderRadius: 28,
                    padding: EdgeInsets.all(24.w),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 0
                          ? _buildPhoneStep()
                          : _buildOtpStep(),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  Text(
                    "By continuing, you agree to our Terms & Privacy Policy",
                    style: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your phone number',
          style: TextStyle(
            color: NexoraColors.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'We\'ll send you a verification code',
          style: TextStyle(color: NexoraColors.textSecondary, fontSize: 14.sp),
        ),
        SizedBox(height: 24.h),

        // Phone Input
        Container(
          decoration: BoxDecoration(
            color: NexoraColors.glassBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _errorMessage != null
                  ? NexoraColors.romanticPink
                  : NexoraColors.glassBorder,
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: NexoraColors.glassBorder,
                      width: 1.w,
                    ),
                  ),
                ),
                child: Text(
                  '+91',
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 16.sp,
                    letterSpacing: 2.w,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: "10-digit number",
                    hintStyle: const TextStyle(color: NexoraColors.textMuted),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 18.h,
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          SizedBox(height: 8.h),
          Text(
            _errorMessage!,
            style: TextStyle(color: NexoraColors.romanticPink, fontSize: 12.sp),
          ),
        ],

        SizedBox(height: 24.h),

        // Continue Button
        _buildPrimaryButton(
          text: 'Send OTP',
          onPressed: _sendOtp,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = 0;
                  _errorMessage = null;
                  for (var c in otpControllers) {
                    c.clear();
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: NexoraColors.textPrimary,
                  size: 16.r,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Verify OTP',
                style: TextStyle(
                  color: NexoraColors.textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          'Enter the 6-digit code sent to +91 ${phoneController.text}',
          style: TextStyle(color: NexoraColors.textSecondary, fontSize: 14.sp),
        ),
        SizedBox(height: 24.h),

        // OTP Input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45.w,
              height: 55.h,
              child: Container(
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: otpControllers[index].text.isNotEmpty
                        ? NexoraColors.primaryPurple
                        : NexoraColors.glassBorder,
                    width: otpControllers[index].text.isNotEmpty ? 2.w : 1.w,
                  ),
                ),
                child: TextField(
                  controller: otpControllers[index],
                  focusNode: otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => _onOtpChanged(value, index),
                ),
              ),
            );
          }),
        ),

        if (_errorMessage != null) ...[
          SizedBox(height: 12.h),
          Text(
            _errorMessage!,
            style: TextStyle(color: NexoraColors.romanticPink, fontSize: 12.sp),
          ),
        ],

        SizedBox(height: 16.h),

        // Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 13.sp),
            ),
            GestureDetector(
              onTap: () {
                for (var c in otpControllers) {
                  c.clear();
                }
                _sendOtp();
              },
              child: Text(
                'Resend',
                style: TextStyle(
                  color: NexoraColors.primaryPurple,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Verify Button
        _buildPrimaryButton(
          text: 'Verify & Continue',
          onPressed: _verifyOtp,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: NexoraGradients.primaryButton,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [NexoraShadows.purpleGlow],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24.r,
                    height: 24.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var f in otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
