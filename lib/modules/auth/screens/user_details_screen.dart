import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/dark_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class UserDetailsScreen extends StatefulWidget {
  final String phoneNumber;

  const UserDetailsScreen({super.key, required this.phoneNumber});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedDepartment;
  bool _isVjecStudent = false;
  bool _isLoading = false;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _departmentOptions = [
    'Computer Science',
    'Electronics & Communication',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Information Technology',
    'Applied Science',
    'Business Administration',
    'Other',
  ];

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(now.year - 30);
    final lastDate = DateTime(now.year - 17);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select your date of birth',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: NexoraColors.primaryPurple,
              onPrimary: Colors.white,
              surface: NexoraColors.cardBackground,
              onSurface: NexoraColors.textPrimary,
            ),
            dialogBackgroundColor: NexoraColors.cardBackground,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      Get.snackbar(
        'Missing Information',
        'Please select your date of birth',
        backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (_selectedGender == null) {
      Get.snackbar(
        'Missing Information',
        'Please select your gender',
        backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final authRepo = AuthRepository.instance;
      final firebaseUser = authRepo.user;

      if (firebaseUser == null) {
        throw Exception("No authenticated user found");
      }

      final newUser = UserModel(
        id: firebaseUser.uid,
        name: nameController.text.trim(),
        username: usernameController.text.trim(),
        email: firebaseUser.email ?? '',
        phone: widget.phoneNumber,
        bio: aboutController.text.trim(),
        major: _selectedDepartment,
        createdAt: DateTime.now(),
        isOnline: true,
      );

      await authRepo.createUserProfile(newUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', newUser.name);
      await prefs.setString('userId', newUser.id);
      await prefs.setString('userPhone', widget.phoneNumber);
      await prefs.setBool('profileCompleted', true);

      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        'Welcome to Kottu!',
        'Your account has been created successfully',
        backgroundColor: NexoraColors.success.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      // Navigation is now handled by AuthWrapper reactive logic
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Something went wrong: ${e.toString()}',
        backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 70.r,
                          height: 70.r,
                          decoration: BoxDecoration(
                            gradient: NexoraGradients.primaryButton,
                            borderRadius: BorderRadius.circular(22.r),
                            boxShadow: [NexoraShadows.purpleGlow],
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            color: NexoraColors.textPrimary,
                            size: 35.r,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Tell us about yourself to get started',
                          style: TextStyle(
                            color: NexoraColors.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  GlassContainer(
                    borderRadius: 24,
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username field
                        _buildLabel('Username'),
                        SizedBox(height: 8.h),
                        _buildTextField(
                          controller: usernameController,
                          hintText: 'Choose a unique username',
                          prefixIcon: Icons.alternate_email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username is required';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                              return 'Only letters, numbers, and underscores allowed';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Full Name field
                        _buildLabel('Full Name'),
                        SizedBox(height: 8.h),
                        _buildTextField(
                          controller: nameController,
                          hintText: 'Enter your full name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Full name is required';
                            }
                            if (value.length < 2) {
                              return 'Name is too short';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // About field
                        _buildLabel('About'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: aboutController,
                          maxLines: 3,
                          maxLength: 150,
                          style: TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 15.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tell us about yourself...',
                            hintStyle: TextStyle(color: NexoraColors.textMuted),
                            filled: true,
                            fillColor: NexoraColors.glassBackground,
                            counterStyle: TextStyle(
                              color: NexoraColors.textMuted,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 50.h),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: NexoraColors.primaryPurple,
                                size: 22.r,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(
                                color: NexoraColors.glassBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(
                                color: NexoraColors.glassBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: const BorderSide(
                                color: NexoraColors.primaryPurple,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Department dropdown
                        _buildLabel('Department'),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: NexoraColors.glassBackground,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: NexoraColors.glassBorder,
                              width: 1.w,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedDepartment,
                              hint: Row(
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    color: NexoraColors.primaryPurple,
                                    size: 22.r,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Select your department',
                                    style: TextStyle(
                                      color: NexoraColors.textMuted,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                              dropdownColor: NexoraColors.cardBackground,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: NexoraColors.textMuted,
                              ),
                              items: _departmentOptions.map((dept) {
                                return DropdownMenuItem(
                                  value: dept,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.business_rounded,
                                        color: NexoraColors.primaryPurple,
                                        size: 22.r,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        dept,
                                        style: TextStyle(
                                          color: NexoraColors.textPrimary,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Date of Birth
                        _buildLabel('Date of Birth'),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: NexoraColors.glassBackground,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: NexoraColors.glassBorder,
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cake_outlined,
                                  color: NexoraColors.primaryPurple,
                                  size: 22.r,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : 'Select your birthday',
                                    style: TextStyle(
                                      color: _selectedDate != null
                                          ? NexoraColors.textPrimary
                                          : NexoraColors.textMuted,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: NexoraColors.textMuted,
                                  size: 20.r,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Gender
                        _buildLabel('Gender'),
                        SizedBox(height: 8.h),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: NexoraColors.glassBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: NexoraColors.glassBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedGender,
                              hint: Row(
                                children: [
                                  Icon(
                                    Icons.wc_outlined,
                                    color: NexoraColors.primaryPurple,
                                    size: 22.r,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Select your gender',
                                    style: TextStyle(
                                      color: NexoraColors.textMuted,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                              dropdownColor: NexoraColors.cardBackground,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: NexoraColors.textMuted,
                              ),
                              items: _genderOptions.map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.wc_outlined,
                                        color: NexoraColors.primaryPurple,
                                        size: 22.r,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        gender,
                                        style: TextStyle(
                                          color: NexoraColors.textPrimary,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // VJEC Student Toggle
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: NexoraColors.glassBackground,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: _isVjecStudent
                                  ? NexoraColors.primaryPurple.withOpacity(0.5)
                                  : NexoraColors.glassBorder,
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44.r,
                                height: 44.r,
                                decoration: BoxDecoration(
                                  gradient: _isVjecStudent
                                      ? NexoraGradients.primaryButton
                                      : null,
                                  color: _isVjecStudent
                                      ? null
                                      : NexoraColors.glassBorder,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: _isVjecStudent
                                      ? Colors.white
                                      : NexoraColors.textMuted,
                                  size: 24.r,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Are you a VJEC student?',
                                      style: TextStyle(
                                        color: NexoraColors.textPrimary,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Get verified student badge',
                                      style: TextStyle(
                                        color: NexoraColors.textMuted,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isVjecStudent,
                                onChanged: (value) {
                                  setState(() {
                                    _isVjecStudent = value;
                                  });
                                },
                                activeColor: NexoraColors.primaryPurple,
                                activeTrackColor: NexoraColors.primaryPurple
                                    .withOpacity(0.4),
                                inactiveThumbColor: NexoraColors.textMuted,
                                inactiveTrackColor: NexoraColors.glassBorder,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Create Account Button
                  _buildPrimaryButton(
                    text: 'Create Account',
                    onPressed: _createAccount,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
                      style: TextStyle(
                        color: NexoraColors.textMuted,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: NexoraColors.textPrimary,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: NexoraColors.textPrimary, fontSize: 15.sp),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: NexoraColors.textMuted),
        filled: true,
        fillColor: NexoraColors.glassBackground,
        prefixIcon: Icon(
          prefixIcon,
          color: NexoraColors.primaryPurple,
          size: 22.r,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: NexoraColors.glassBorder, width: 1.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: NexoraColors.glassBorder, width: 1.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: NexoraColors.primaryPurple, width: 2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: NexoraColors.romanticPink, width: 1.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: NexoraColors.romanticPink, width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
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
    usernameController.dispose();
    nameController.dispose();
    aboutController.dispose();
    super.dispose();
  }
}
