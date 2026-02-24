import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/dark_background.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'Suggestion';

  final List<String> _categories = [
    'Bug Report',
    'Suggestion',
    'Question',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DarkBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Feedback', style: NexoraTextStyles.headline2),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: NexoraColors.textPrimary,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your thoughts',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: NexoraColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We value your feedback to make Nexora better.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: NexoraColors.textMuted,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: NexoraColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildCategorySelector(),
                SizedBox(height: 24.h),
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: NexoraColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildFeedbackField(),
                SizedBox(height: 32.h),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? NexoraColors.primaryPurple
                      : NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? NexoraColors.primaryPurple
                        : NexoraColors.primaryPurple.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : NexoraColors.textMuted,
                    fontSize: 13.sp,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackField() {
    return GlassContainer(
      borderRadius: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        controller: _feedbackController,
        maxLines: 6,
        style: TextStyle(color: NexoraColors.textPrimary, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Type your feedback here...',
          hintStyle: TextStyle(color: NexoraColors.textMuted, fontSize: 14.sp),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: NexoraColors.primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        onPressed: () {
          if (_feedbackController.text.trim().isNotEmpty) {
            Get.back();
            Get.snackbar(
              'Thank You!',
              'Your feedback has been submitted successfully.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: NexoraColors.primaryPurple.withOpacity(0.8),
              colorText: Colors.white,
              borderRadius: 12.r,
              margin: EdgeInsets.all(16.w),
            );
          }
        },
        child: Text(
          'Submit Feedback',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
