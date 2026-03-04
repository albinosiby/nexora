import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../repositories/user_repository.dart';
import '../models/profile_model.dart';

import '../../settings/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final UserRepository _userRepo = UserRepository.instance;

  ProfileModel get profile => _userRepo.currentUser;

  // These will now be reactive through Obx
  String get userName => profile.name;
  String get userDisplayName => profile.displayName;
  String get userBio => profile.bio;
  String get userYear => profile.year;
  String get userMajor => profile.major;
  String get avatarUrl => profile.avatar;

  late AnimationController _animController;

  List<Map<String, String>> get interests {
    final interestEmojis = {
      'Coding': '💻',
      'Gaming': '🎮',
      'Music': '🎵',
      'Photography': '📸',
      'Travel': '✈️',
      'Reading': '📚',
      'Coffee': '☕',
      'Hackathons': '🚀',
      'Marketing': '📊',
      'Yoga': '🧘‍♀️',
      'Robotics': '🤖',
      'Sports': '⚽',
      'Fitness': '💪',
      'Psychology': '🧠',
      'Art': '🎨',
      'Cats': '🐱',
      'Medicine': '⚕️',
      'Chess': '♟️',
      'Running': '🏃',
      'Tea': '🍵',
      'AI': '🤖',
      'Dancing': '💃',
      'Food': '🍕',
      'Finance': '💰',
      'Basketball': '🏀',
      'Crypto': '📈',
      'Design': '🎨',
      'Dogs': '🐕',
      'Science': '🔬',
      'Cooking': '👨‍🍳',
      'K-pop': '🎤',
      'Fashion': '👗',
      'Sneakers': '👟',
      'F1': '🏎️',
    };

    return profile.interests.map((interest) {
      return {'emoji': interestEmojis[interest] ?? '⭐', 'label': interest};
    }).toList();
  }

  // Avatar style options

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(
        () => Stack(
          children: [
            // Animated background gradients
            Positioned(
              top: -100.h,
              right: -100.w,
              child: Container(
                width: 300.r,
                height: 300.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      NexoraColors.primaryPurple.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100.h,
              left: -50.w,
              child: Container(
                width: 200.r,
                height: 200.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      NexoraColors.romanticPink.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),

                    // Profile Header with Animation
                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: FadeTransition(
                        opacity: _animController,
                        child: Center(
                          child: Column(
                            children: [
                              // Profile Avatar with Glow
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow effect
                                  Container(
                                    width: 130.r,
                                    height: 130.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: NexoraColors.primaryPurple
                                              .withOpacity(0.4),
                                          blurRadius: 30.r,
                                          spreadRadius: 5.r,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Avataaars Avatar
                                  Container(
                                    width: 120.r,
                                    height: 120.r,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          NexoraColors.primaryPurple
                                              .withOpacity(0.3),
                                          NexoraColors.romanticPink.withOpacity(
                                            0.2,
                                          ),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: NexoraColors.primaryPurple
                                            .withOpacity(0.5),
                                        width: 3.w,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: Text(
                                                  userName[0].toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 44.sp,
                                                    color: NexoraColors
                                                        .textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Center(
                                              child: Text(
                                                userName[0].toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 44.sp,
                                                  color:
                                                      NexoraColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  // Verified badge
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: NexoraGradients.cyanAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: NexoraColors.midnightDark,
                                          width: 3,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14.r,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Name with sparkle
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: NexoraColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '✨',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Username
                              Text(
                                '@${profile.displayName}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: NexoraColors.textMuted,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Major badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      NexoraColors.primaryPurple.withOpacity(
                                        0.2,
                                      ),
                                      NexoraColors.romanticPink.withOpacity(
                                        0.1,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: NexoraColors.primaryPurple
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  userMajor,
                                  style: const TextStyle(
                                    color: NexoraColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bio Section
                    _buildSection(
                      title: 'About Me',
                      icon: Icons.edit_note,
                      child: GlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          userBio,
                          style: const TextStyle(
                            color: NexoraColors.textPrimary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    // Stats Section with Glass Effect
                    GlassContainer(
                      borderRadius: 24.r,
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            'Likes',
                            '${profile.profileLikes}',
                            NexoraColors.romanticPink,
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            'Connections',
                            '${profile.connections}',
                            NexoraColors.accentCyan,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Interests Section
                    _buildSection(
                      title: 'Interests',
                      icon: Icons.favorite_outline,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: interests.map((interest) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  NexoraColors.glassBackground,
                                  NexoraColors.primaryPurple.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: NexoraColors.glassBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  interest['emoji']!,
                                  style: TextStyle(fontSize: 16.sp),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  interest['label']!,
                                  style: TextStyle(
                                    color: NexoraColors.textPrimary,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Looking For Section
                    _buildSection(
                      title: 'Looking For',
                      icon: Icons.search_outlined,
                      child: GlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                gradient: NexoraGradients.romanticGlow,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 20.r,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                profile.lookingFor ??
                                    'Looking for connections 💜',
                                style: TextStyle(
                                  color: NexoraColors.textPrimary,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // App Version
                    Text(
                      'Kootu v1.0.0',
                      style: TextStyle(
                        color: NexoraColors.textMuted.withOpacity(0.5),
                        fontSize: 10.sp,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Settings Icon (must be last in Stack to be tappable)
            Positioned(
              top: 10.h,
              right: 10.w,
              child: SafeArea(
                child: _buildHeaderIcon(
                  Icons.settings_outlined,
                  onTap: () => Get.to(() => const SettingsScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: NexoraColors.glassBackground,
          shape: BoxShape.circle,
          border: Border.all(color: NexoraColors.glassBorder),
        ),
        child: Icon(icon, color: NexoraColors.textPrimary, size: 20.r),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NexoraColors.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: NexoraColors.primaryPurple, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: NexoraColors.glassBorder);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: NexoraColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// Enhanced Edit Profile Screen with animations, profile completion, and more
class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;

  const EditProfileScreen({required this.profile, super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController usernameController;
  late TextEditingController yearController;
  late TextEditingController majorController;
  late TextEditingController instagramController;

  // Username validation state
  String? _usernameError;
  bool _isCheckingUsername = false;
  bool _isUsernameValid = false;
  Timer? _usernameDebounce;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Avatar preferences
  String avatarSeed = '';
  String avatarStyle = 'avataaars';

  // Selected interests
  List<String> selectedInterests = [];

  // Looking for option
  String selectedLookingFor = 'Something meaningful 💜';

  String get avatarUrl {
    final seed = avatarSeed.isNotEmpty ? avatarSeed : nameController.text;
    return 'https://api.dicebear.com/7.x/$avatarStyle/png?seed=${Uri.encodeComponent(seed)}&backgroundColor=transparent&size=200';
  }

  final List<String> years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Graduate',
  ];

  final List<String> majors = [
    'Computer Science',
    'Business',
    'Engineering',
    'Psychology',
    'Art',
    'Medicine',
    'Law',
    'Communications',
    'Biology',
    'Chemistry',
    'Mathematics',
    'Physics',
    'Economics',
    'Political Science',
    'History',
    'Philosophy',
  ];

  final List<Map<String, String>> allInterests = [
    {'emoji': '💻', 'label': 'Coding'},
    {'emoji': '🎮', 'label': 'Gaming'},
    {'emoji': '🎵', 'label': 'Music'},
    {'emoji': '📸', 'label': 'Photography'},
    {'emoji': '✈️', 'label': 'Travel'},
    {'emoji': '📚', 'label': 'Reading'},
    {'emoji': '🎬', 'label': 'Movies'},
    {'emoji': '🏃', 'label': 'Fitness'},
    {'emoji': '🎨', 'label': 'Art'},
    {'emoji': '☕', 'label': 'Coffee'},
    {'emoji': '🍳', 'label': 'Cooking'},
    {'emoji': '🐕', 'label': 'Pets'},
    {'emoji': '🎭', 'label': 'Theater'},
    {'emoji': '⚽', 'label': 'Sports'},
    {'emoji': '🧘', 'label': 'Yoga'},
    {'emoji': '🌱', 'label': 'Nature'},
    {'emoji': '🎤', 'label': 'Singing'},
    {'emoji': '💃', 'label': 'Dancing'},
    {'emoji': '🎸', 'label': 'Instruments'},
    {'emoji': '🎲', 'label': 'Board Games'},
  ];

  final List<Map<String, dynamic>> lookingForOptions = [
    {
      'icon': Icons.favorite,
      'label': 'Something meaningful 💜',
      'color': NexoraColors.romanticPink,
    },
    {
      'icon': Icons.people,
      'label': 'New friends 👋',
      'color': NexoraColors.accentCyan,
    },
    {
      'icon': Icons.explore,
      'label': 'Just exploring 🔍',
      'color': NexoraColors.brightPurple,
    },
    {
      'icon': Icons.school,
      'label': 'Study buddies 📚',
      'color': NexoraColors.softCyan,
    },
    {
      'icon': Icons.nights_stay,
      'label': 'Late night chats 🌙',
      'color': NexoraColors.deepPurple,
    },
  ];

  double get profileCompletion {
    int completed = 0;
    int total = 6;

    if (nameController.text.isNotEmpty) completed++;
    if (bioController.text.length > 10) completed++;
    if (yearController.text.isNotEmpty) completed++;
    if (majorController.text.isNotEmpty) completed++;
    if (selectedInterests.length >= 3) completed++;
    if (instagramController.text.isNotEmpty) {
      completed++;
    }

    return completed / total;
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.name);
    bioController = TextEditingController(text: widget.profile.bio);
    usernameController = TextEditingController(text: widget.profile.username);
    // Mark existing username as valid initially
    if (widget.profile.username.isNotEmpty) _isUsernameValid = true;
    yearController = TextEditingController(text: widget.profile.year);
    majorController = TextEditingController(text: widget.profile.major);
    instagramController = TextEditingController(
      text: widget.profile.instagram ?? '',
    );

    // Initialize from profile
    avatarSeed = widget.profile.avatarSeed;
    avatarStyle = widget.profile.avatarStyle;
    selectedInterests = List.from(widget.profile.interests);
    selectedLookingFor = widget.profile.lookingFor ?? 'Something meaningful 💜';

    // Initialize animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();

    // Add listeners for profile completion updates
    nameController.addListener(_updateState);
    bioController.addListener(_updateState);
    usernameController.addListener(_onUsernameChanged);
  }

  void _updateState() => setState(() {});

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    final username = usernameController.text.trim().toLowerCase();

    // Basic format validation
    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
        _isUsernameValid = false;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _usernameError = 'Min 3 characters';
        _isCheckingUsername = false;
        _isUsernameValid = false;
      });
      return;
    }

    final validPattern = RegExp(r'^[a-z0-9._]+$');
    if (!validPattern.hasMatch(username)) {
      setState(() {
        _usernameError = 'Only lowercase letters, numbers, . and _';
        _isCheckingUsername = false;
        _isUsernameValid = false;
      });
      return;
    }

    // If it's the same as current username, no need to check
    if (username == widget.profile.username.toLowerCase()) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
        _isUsernameValid = true;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
      _isUsernameValid = false;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final taken = await UserRepository.instance.isUsernameTaken(username);
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
        if (taken) {
          _usernameError = 'Username already taken';
          _isUsernameValid = false;
        } else {
          _usernameError = null;
          _isUsernameValid = true;
        }
      });
    });
  }

  // Removed _loadPreferences to use widget.profile exclusively

  Future<void> _saveProfile() async {
    // Block save if username is taken
    if (_usernameError != null) {
      Get.snackbar(
        'Invalid Username',
        _usernameError!,
        backgroundColor: NexoraColors.error.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    if (_isCheckingUsername) {
      Get.snackbar(
        'Please Wait',
        'Checking username availability...',
        backgroundColor: NexoraColors.cardBackground,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
      return;
    }

    final String name = nameController.text;
    final String username = usernameController.text.trim().toLowerCase();
    final String bio = bioController.text;
    final String year = yearController.text;
    final String major = majorController.text;
    final String instagram = instagramController.text;
    final String looking = selectedLookingFor;

    // Recalculate avatar URL to ensure it persists correctly
    final String currentAvatarSeed = avatarSeed.isNotEmpty ? avatarSeed : name;
    final String newAvatarUrl =
        'https://api.dicebear.com/7.x/$avatarStyle/png?seed=${Uri.encodeComponent(currentAvatarSeed)}&backgroundColor=transparent&size=200';

    final updatedProfile = widget.profile.copyWith(
      name: name,
      username: username,
      bio: bio,
      year: year,
      major: major,
      interests: selectedInterests,
      instagram: instagram,
      lookingFor: looking,
      avatarSeed: avatarSeed,
      avatarStyle: avatarStyle,
      avatar: newAvatarUrl,
    );

    // Update via repository (saves to Firestore and syncs RTDB)
    await UserRepository.instance.updateProfile(updatedProfile);

    Get.back(result: updatedProfile);

    Get.snackbar(
      'Profile Updated',
      'Your changes have been saved',
      backgroundColor: NexoraColors.success.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else if (selectedInterests.length < 8) {
        selectedInterests.add(interest);
      } else {
        Get.snackbar(
          'Maximum Reached',
          'You can select up to 8 interests',
          backgroundColor: NexoraColors.warning.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.all(16.r),
          borderRadius: 12.r,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background gradients
          Positioned(
            top: -100.h,
            right: -100.w,
            child: Container(
              width: 300.r,
              height: 300.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NexoraColors.primaryPurple.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150.h,
            left: -80.w,
            child: Container(
              width: 250.r,
              height: 250.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NexoraColors.romanticPink.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),

                // Scrollable content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Completion Card
                            _buildProfileCompletionCard(),

                            SizedBox(height: 24.h),

                            // Profile Avatar Section
                            _buildAvatarSection(),

                            SizedBox(height: 32.h),

                            // Basic Info Section
                            _buildSectionHeader(
                              'Basic Info',
                              Icons.person_outline,
                            ),
                            SizedBox(height: 12.h),
                            _buildBasicInfoCard(),

                            SizedBox(height: 28.h),

                            // Interests Section
                            _buildSectionHeader(
                              'Your Interests',
                              Icons.favorite_outline,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Select up to 8 interests (${selectedInterests.length}/8)',
                              style: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildInterestsGrid(),

                            SizedBox(height: 28.h),

                            // Looking For Section
                            _buildSectionHeader(
                              'Looking For',
                              Icons.search_outlined,
                            ),
                            SizedBox(height: 12.h),
                            _buildLookingForSection(),

                            SizedBox(height: 28.h),

                            // Save Button
                            _buildSaveButton(),

                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: NexoraColors.glassBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: NexoraColors.textPrimary,
                size: 18.r,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: NexoraColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48), // Placeholder for symmetry
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final completion = profileCompletion;
    final percentage = (completion * 100).round();

    return GlassContainer(
      borderRadius: 20.r,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: completion >= 1.0
                      ? const LinearGradient(
                          colors: [NexoraColors.success, Color(0xFF81C784)],
                        )
                      : NexoraGradients.primaryButton,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  completion >= 1.0 ? Icons.check_circle : Icons.trending_up,
                  color: Colors.white,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completion >= 1.0
                          ? 'Profile Complete! 🎉'
                          : 'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: NexoraColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      completion >= 1.0
                          ? 'You\'re ready to make connections!'
                          : 'Complete profiles get more visibility',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: NexoraColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: completion >= 1.0
                      ? [NexoraColors.success, const Color(0xFF81C784)]
                      : [NexoraColors.primaryPurple, NexoraColors.romanticPink],
                ).createShader(bounds),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Stack(
              children: [
                Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: NexoraColors.cardBackground,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: 8.h,
                  width:
                      (1.sw * 0.85 * completion) - 40.w, // Adjusted for padding
                  decoration: BoxDecoration(
                    gradient: completion >= 1.0
                        ? const LinearGradient(
                            colors: [NexoraColors.success, Color(0xFF81C784)],
                          )
                        : NexoraGradients.primaryButton,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarEditor() {
    // Temporary state for preview, initialized from controllers/fields
    String tempSeed = avatarSeed;
    String tempStyle = avatarStyle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          String previewUrl =
              'https://api.dicebear.com/7.x/$tempStyle/png?seed=${Uri.encodeComponent(tempSeed)}&backgroundColor=transparent&size=200';

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NexoraColors.midnightPurple.withOpacity(0.95),
                  NexoraColors.midnightDark.withOpacity(0.98),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: NexoraColors.primaryPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: NexoraColors.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Text(
                        'Edit Avatar',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: NexoraColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            avatarSeed = tempSeed;
                            avatarStyle = tempStyle;
                          });
                          Navigator.pop(context);
                        },
                        child: ShaderMask(
                          shaderCallback: (bounds) => NexoraGradients
                              .primaryButton
                              .createShader(bounds),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar Preview
                Container(
                  width: 150.r,
                  height: 150.r,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NexoraColors.primaryPurple.withOpacity(0.3),
                        NexoraColors.romanticPink.withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NexoraColors.primaryPurple.withOpacity(0.5),
                      width: 3.w,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      previewUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: NexoraColors.primaryPurple,
                            strokeWidth: 3.w,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          tempSeed.isNotEmpty ? tempSeed[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 44.sp,
                            color: NexoraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Randomize button
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        tempSeed = DateTime.now().millisecondsSinceEpoch
                            .toString();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: NexoraGradients.primaryButton,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: NexoraColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 10.r,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shuffle, color: Colors.white, size: 18.r),
                          SizedBox(width: 8.w),
                          const Text(
                            'Randomize',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Options
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Style selector
                        _buildSectionTitleInSheet('Avatar Style'),
                        SizedBox(
                          height: 50.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: avatarStylesInSheet.length,
                            itemBuilder: (context, index) {
                              final style = avatarStylesInSheet[index];
                              final isSelected = tempStyle == style['value'];
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    tempStyle = style['value']!;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 10.w),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? NexoraGradients.primaryButton
                                        : null,
                                    color: isSelected
                                        ? null
                                        : NexoraColors.cardBackground,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : NexoraColors.cardBorder,
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      style['label']!,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : NexoraColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Moved helper constants/methods for avatar from ProfileScreen to EditProfileScreen if needed
  final List<Map<String, String>> avatarStylesInSheet = [
    {'value': 'avataaars', 'label': 'Classic'},
    {'value': 'avataaars-neutral', 'label': 'Neutral'},
    {'value': 'big-smile', 'label': 'Big Smile'},
    {'value': 'lorelei', 'label': 'Lorelei'},
    {'value': 'notionists', 'label': 'Notionists'},
    {'value': 'personas', 'label': 'Personas'},
    {'value': 'adventurer', 'label': 'Adventure'},
    {'value': 'fun-emoji', 'label': 'Emoji'},
  ];

  Widget _buildSectionTitleInSheet(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: NexoraColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 130.r,
                height: 130.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NexoraColors.primaryPurple.withOpacity(0.4),
                      blurRadius: 30.r,
                      spreadRadius: 5.r,
                    ),
                  ],
                ),
              ),
              // Avatar
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NexoraColors.primaryPurple.withOpacity(0.3),
                      NexoraColors.romanticPink.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NexoraColors.primaryPurple.withOpacity(0.5),
                    width: 3.w,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Text(
                          nameController.text.isNotEmpty
                              ? nameController.text[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 44.sp,
                            color: NexoraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        nameController.text.isNotEmpty
                            ? nameController.text[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 44.sp,
                          color: NexoraColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showAvatarEditor,
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NexoraColors.midnightDark,
                        width: 3.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexoraColors.primaryPurple.withOpacity(0.5),
                          blurRadius: 10.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18.r,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Tap to change avatar',
            style: TextStyle(color: NexoraColors.textMuted, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: NexoraColors.primaryPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: NexoraColors.primaryPurple, size: 18.r),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            color: NexoraColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    return GlassContainer(
      borderRadius: 24.r,
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildTextField(
            label: 'Display Name',
            controller: nameController,
            icon: Icons.person_outline,
            hint: 'What should people call you?',
          ),
          SizedBox(height: 20.h),
          // Username field with validation
          _buildUsernameField(),
          SizedBox(height: 20.h),
          _buildTextField(
            label: 'Bio',
            controller: bioController,
            icon: Icons.edit_note,
            maxLines: 3,
            hint: 'Tell others about yourself...',
            maxLength: 150,
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Year',
                  value: yearController.text,
                  items: years,
                  icon: Icons.school_outlined,
                  onChanged: (value) {
                    setState(() {
                      yearController.text = value ?? yearController.text;
                    });
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildDropdownField(
                  label: 'Major',
                  value: majorController.text,
                  items: majors,
                  icon: Icons.book_outlined,
                  onChanged: (value) {
                    setState(() {
                      majorController.text = value ?? majorController.text;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid() {
    return GlassContainer(
      borderRadius: 20.r,
      padding: EdgeInsets.all(16.w),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: allInterests.map((interest) {
          final isSelected = selectedInterests.contains(interest['label']);
          return GestureDetector(
            onTap: () => _toggleInterest(interest['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: isSelected ? NexoraGradients.primaryButton : null,
                color: isSelected ? null : NexoraColors.cardBackground,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : NexoraColors.cardBorder,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: NexoraColors.primaryPurple.withOpacity(0.3),
                          blurRadius: 3.r,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(interest['emoji']!, style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 6.w),
                  Text(
                    interest['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : NexoraColors.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 4.w),
                    Icon(Icons.check, color: Colors.white, size: 14.r),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLookingForSection() {
    return GlassContainer(
      borderRadius: 20.r,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: lookingForOptions.map((option) {
          final isSelected = selectedLookingFor == option['label'];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedLookingFor = option['label'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          (option['color'] as Color).withOpacity(0.3),
                          (option['color'] as Color).withOpacity(0.1),
                        ],
                      )
                    : null,
                color: isSelected ? null : NexoraColors.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? (option['color'] as Color).withOpacity(0.6)
                      : NexoraColors.cardBorder,
                  width: isSelected ? 2.w : 1.w,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                option['color'],
                                (option['color'] as Color).withOpacity(0.7),
                              ],
                            )
                          : null,
                      color: isSelected ? null : NexoraColors.cardBackground,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      option['icon'],
                      color: isSelected ? Colors.white : NexoraColors.textMuted,
                      size: 18.r,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      option['label'],
                      style: TextStyle(
                        color: isSelected
                            ? NexoraColors.textPrimary
                            : NexoraColors.textSecondary,
                        fontSize: 15.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: option['color'],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 14.r),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveProfile,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: NexoraGradients.glassyGradient,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.2),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: NexoraColors.primaryPurple.withOpacity(0.1),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, color: Colors.white, size: 20.r),
            SizedBox(width: 10.w),
            Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 12.sp),
            ),
            if (maxLength != null)
              Text(
                '${controller.text.length}/$maxLength',
                style: TextStyle(
                  color: controller.text.length > maxLength
                      ? NexoraColors.error
                      : NexoraColors.textMuted,
                  fontSize: 11.sp,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: NexoraColors.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: NexoraColors.cardBorder, width: 1.w),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: const TextStyle(color: NexoraColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: maxLines > 1 ? 50.h : 0),
                child: Icon(
                  icon,
                  color: NexoraColors.primaryPurple,
                  size: 20.r,
                ),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: NexoraColors.textMuted.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: NexoraColors.textMuted, fontSize: 12.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: NexoraColors.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: NexoraColors.cardBorder, width: 1.w),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: NexoraColors.midnightPurple,
              style: const TextStyle(color: NexoraColors.textPrimary),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: NexoraColors.primaryPurple,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Username',
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 12.sp),
            ),
            if (_isCheckingUsername)
              SizedBox(
                width: 14.r,
                height: 14.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  color: NexoraColors.accentCyan,
                ),
              )
            else if (_isUsernameValid && usernameController.text.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: NexoraColors.success,
                    size: 14.r,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Available',
                    style: TextStyle(
                      color: NexoraColors.success,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              )
            else if (_usernameError != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, color: NexoraColors.error, size: 14.r),
                  SizedBox(width: 4.w),
                  Text(
                    _usernameError!,
                    style: TextStyle(
                      color: NexoraColors.error,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: NexoraColors.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _usernameError != null
                  ? NexoraColors.error.withOpacity(0.5)
                  : _isUsernameValid && usernameController.text.isNotEmpty
                  ? NexoraColors.success.withOpacity(0.5)
                  : NexoraColors.cardBorder,
              width: 1.w,
            ),
          ),
          child: TextField(
            controller: usernameController,
            style: const TextStyle(color: NexoraColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.alternate_email,
                color: NexoraColors.primaryPurple,
                size: 20.r,
              ),
              hintText: 'Choose a unique username',
              hintStyle: TextStyle(
                color: NexoraColors.textMuted.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.removeListener(_updateState);
    bioController.removeListener(_updateState);
    usernameController.removeListener(_onUsernameChanged);
    _usernameDebounce?.cancel();
    nameController.dispose();
    bioController.dispose();
    usernameController.dispose();
    yearController.dispose();
    majorController.dispose();
    instagramController.dispose();

    _animController.dispose();
    super.dispose();
  }
}
