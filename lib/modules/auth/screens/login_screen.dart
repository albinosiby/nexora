import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/dummy_database.dart';
import '../../../core/main_screen.dart';
import 'user_details_screen.dart';

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

  // Simulated OTP for demo
  String _generatedOtp = '';

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

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate a random 6-digit OTP (for demo, always use 123456)
    _generatedOtp = '123456';

    setState(() {
      _isLoading = false;
      _currentStep = 1;
    });

    // Show OTP in snackbar for demo purposes
    Get.snackbar(
      'OTP Sent',
      'Demo OTP: $_generatedOtp',
      backgroundColor: NexoraColors.success.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );

    // Focus first OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      otpFocusNodes[0].requestFocus();
    });
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = otpControllers.map((c) => c.text).join();

    if (enteredOtp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (enteredOtp == _generatedOtp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhone', phoneController.text);

      // Check if user exists in database
      final db = DummyDatabase.instance;
      final existingUser = db.users.firstWhereOrNull(
        (u) => u.phone == phoneController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (existingUser != null) {
        // Existing user - go to main screen
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', existingUser.name);
        await prefs.setString('userId', existingUser.id);
        if (mounted) {
          Get.offAll(() => const MainScreen());
        }
      } else {
        // New user - go to details screen
        if (mounted) {
          Get.off(() => UserDetailsScreen(phoneNumber: phoneController.text));
        }
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid OTP. Please try again.';
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [NexoraShadows.purpleGlow],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: NexoraColors.textPrimary,
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("NEXORA", style: NexoraTextStyles.logoStyle),
                  const SizedBox(height: 8),
                  Text(
                    "WHERE CAMPUS HEARTS CONNECT",
                    style: NexoraTextStyles.taglineStyle,
                  ),
                  const SizedBox(height: 40),

                  // Main Card
                  GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 0
                          ? _buildPhoneStep()
                          : _buildOtpStep(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "By continuing, you agree to our Terms & Privacy Policy",
                    style: TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 12,
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
        const Text(
          'Enter your phone number',
          style: TextStyle(
            color: NexoraColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send you a verification code',
          style: TextStyle(color: NexoraColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Phone Input
        Container(
          decoration: BoxDecoration(
            color: NexoraColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _errorMessage != null
                  ? NexoraColors.romanticPink
                  : NexoraColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: NexoraColors.glassBorder),
                  ),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: const TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: "10-digit number",
                    hintStyle: TextStyle(color: NexoraColors.textMuted),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
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
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: NexoraColors.romanticPink,
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 24),

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: NexoraColors.textPrimary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Verify OTP',
                style: TextStyle(
                  color: NexoraColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to +91 ${phoneController.text}',
          style: TextStyle(color: NexoraColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // OTP Input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: Container(
                decoration: BoxDecoration(
                  color: NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: otpControllers[index].text.isNotEmpty
                        ? NexoraColors.primaryPurple
                        : NexoraColors.glassBorder,
                    width: otpControllers[index].text.isNotEmpty ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: otpControllers[index],
                  focusNode: otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
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
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: NexoraColors.romanticPink,
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 13),
            ),
            GestureDetector(
              onTap: () {
                for (var c in otpControllers) {
                  c.clear();
                }
                _sendOtp();
              },
              child: const Text(
                'Resend',
                style: TextStyle(
                  color: NexoraColors.primaryPurple,
                  fontSize: 13,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: NexoraGradients.primaryButton,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [NexoraShadows.purpleGlow],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
