import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/services/dummy_database.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final DummyDatabase _db = DummyDatabase.instance;

  String get userName => _db.currentUser.value.name;
  String get userDisplayName => _db.currentUser.value.displayName;
  String get userBio => _db.currentUser.value.bio;
  String get userYear => _db.currentUser.value.year;
  String get userMajor => _db.currentUser.value.major;

  // Spotify anthem from database
  Map<String, String> get spotifyAnthem => {
    'title': _db.currentUser.value.spotifyTrackName ?? 'No track',
    'artist': _db.currentUser.value.spotifyArtist ?? 'Unknown',
    'albumArt':
        'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36',
  };

  // Avatar customization options
  String avatarSeed = 'Alex Chen';
  String avatarStyle = 'avataaars';

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

    return _db.currentUser.value.interests.map((interest) {
      return {'emoji': interestEmojis[interest] ?? '⭐', 'label': interest};
    }).toList();
  }

  // Avatar style options
  final List<Map<String, String>> avatarStyles = [
    {'value': 'avataaars', 'label': 'Classic'},
    {'value': 'avataaars-neutral', 'label': 'Neutral'},
    {'value': 'big-smile', 'label': 'Big Smile'},
    {'value': 'lorelei', 'label': 'Lorelei'},
    {'value': 'notionists', 'label': 'Notionists'},
    {'value': 'personas', 'label': 'Personas'},
    {'value': 'adventurer', 'label': 'Adventure'},
    {'value': 'fun-emoji', 'label': 'Emoji'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      avatarSeed = prefs.getString('avatarSeed') ?? _db.currentUser.value.name;
      avatarStyle = prefs.getString('avatarStyle') ?? 'avataaars';
    });
  }

  Future<void> _saveAvatarPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatarSeed', avatarSeed);
    await prefs.setString('avatarStyle', avatarStyle);
  }

  String get avatarUrl {
    // Using PNG format for better compatibility
    return 'https://api.dicebear.com/7.x/$avatarStyle/png?seed=${Uri.encodeComponent(avatarSeed)}&backgroundColor=transparent&size=200';
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: NexoraColors.error, size: 50),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(color: NexoraColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.error,
                      ),
                      onPressed: () async {
                        Get.back();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);
                        Get.off(() => const LoginScreen());
                      },
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarEditor() {
    // Temporary state for preview
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
                          style: TextStyle(color: NexoraColors.textSecondary),
                        ),
                      ),
                      const Text(
                        'Edit Avatar',
                        style: TextStyle(
                          fontSize: 18,
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
                          _saveAvatarPreferences();
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
                  width: 150,
                  height: 150,
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
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      previewUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: NexoraColors.primaryPurple,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          tempSeed.isNotEmpty ? tempSeed[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 44,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        tempSeed = DateTime.now().millisecondsSinceEpoch
                            .toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: NexoraGradients.primaryButton,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: NexoraColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shuffle, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Style selector
                        _buildSectionTitle('Avatar Style'),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: avatarStyles.length,
                            itemBuilder: (context, index) {
                              final style = avatarStyles[index];
                              final isSelected = tempStyle == style['value'];
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    tempStyle = style['value']!;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? NexoraGradients.primaryButton
                                        : null,
                                    color: isSelected
                                        ? null
                                        : NexoraColors.cardBackground,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : NexoraColors.cardBorder,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: NexoraColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background gradients
          Positioned.fill(
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
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
                  bottom: 100,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
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
              ],
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

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
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: NexoraColors.primaryPurple
                                            .withOpacity(0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                // Avataaars Avatar
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        NexoraColors.primaryPurple.withOpacity(
                                          0.3,
                                        ),
                                        NexoraColors.romanticPink.withOpacity(
                                          0.2,
                                        ),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: NexoraColors.primaryPurple
                                          .withOpacity(0.5),
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: Text(
                                                userName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 44,
                                                  color:
                                                      NexoraColors.textPrimary,
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
                                              style: const TextStyle(
                                                fontSize: 44,
                                                color: NexoraColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                // Edit avatar button
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showAvatarEditor,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: NexoraGradients.primaryButton,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: NexoraColors.midnightDark,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: NexoraColors.primaryPurple
                                                .withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 16,
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
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
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
                                const Text('✨', style: TextStyle(fontSize: 20)),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Year & Major badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    NexoraColors.primaryPurple.withOpacity(0.2),
                                    NexoraColors.romanticPink.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: NexoraColors.primaryPurple.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '$userYear • $userMajor',
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

                  // Spotify Anthem Section
                  _buildSection(
                    title: 'On Repeat',
                    icon: Icons.music_note_rounded,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1DB954).withOpacity(0.15),
                            NexoraColors.glassBackground,
                            NexoraColors.primaryPurple.withOpacity(0.08),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF1DB954).withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1DB954).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Background blur effect
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withOpacity(0.05),
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.03),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Album art with glass frame
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.3),
                                          Colors.white.withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            child: Image.network(
                                              spotifyAnthem['albumArt']!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                const Color(
                                                                  0xFF1DB954,
                                                                ),
                                                                const Color(
                                                                  0xFF1DB954,
                                                                ).withOpacity(
                                                                  0.7,
                                                                ),
                                                              ],
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .music_note_rounded,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                        // Frosted play button
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Song info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          spotifyAnthem['title']!,
                                          style: const TextStyle(
                                            color: NexoraColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1DB954),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: const Icon(
                                                Icons.music_note,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                spotifyAnthem['artist']!,
                                                style: TextStyle(
                                                  color: NexoraColors.textMuted,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Animated bars indicator
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildMusicBar(8),
                                        const SizedBox(width: 2),
                                        _buildMusicBar(14),
                                        const SizedBox(width: 2),
                                        _buildMusicBar(10),
                                        const SizedBox(width: 2),
                                        _buildMusicBar(16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Section with Glass Effect
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Posts',
                          '24',
                          NexoraColors.romanticPink,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          'Connections',
                          '128',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                NexoraColors.glassBackground,
                                NexoraColors.primaryPurple.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: NexoraColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                interest['emoji']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                interest['label']!,
                                style: const TextStyle(
                                  color: NexoraColors.textPrimary,
                                  fontSize: 13,
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: NexoraGradients.romanticGlow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Something meaningful 💜',
                              style: TextStyle(
                                color: NexoraColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  TextButton(
                    onPressed: _logout,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          color: NexoraColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            color: NexoraColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // App Version
                  Text(
                    'NEXORA v1.0.0',
                    style: TextStyle(
                      color: NexoraColors.textMuted.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildMusicBar(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954),
        borderRadius: BorderRadius.circular(2),
      ),
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
  final String currentName;
  final String currentBio;
  final String currentYear;
  final String currentMajor;

  const EditProfileScreen({
    required this.currentName,
    required this.currentBio,
    required this.currentYear,
    required this.currentMajor,
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController yearController;
  late TextEditingController majorController;
  late TextEditingController instagramController;
  late TextEditingController spotifyController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Avatar preferences
  String avatarSeed = '';
  String avatarStyle = 'avataaars';

  // Selected interests
  List<String> selectedInterests = [];

  // Looking for option
  String lookingFor = 'Something meaningful 💜';

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
    if (instagramController.text.isNotEmpty ||
        spotifyController.text.isNotEmpty)
      completed++;

    return completed / total;
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    bioController = TextEditingController(text: widget.currentBio);
    yearController = TextEditingController(text: widget.currentYear);
    majorController = TextEditingController(text: widget.currentMajor);
    instagramController = TextEditingController();
    spotifyController = TextEditingController();

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

    _loadPreferences();
    _animController.forward();

    // Add listeners for profile completion updates
    nameController.addListener(_updateState);
    bioController.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      avatarSeed = prefs.getString('avatarSeed') ?? widget.currentName;
      avatarStyle = prefs.getString('avatarStyle') ?? 'avataaars';

      // Load saved interests
      final savedInterests = prefs.getStringList('userInterests');
      if (savedInterests != null) {
        selectedInterests = savedInterests;
      } else {
        selectedInterests = ['Coding', 'Gaming', 'Music'];
      }

      // Load social links
      instagramController.text = prefs.getString('instagram') ?? '';
      spotifyController.text = prefs.getString('spotify') ?? '';
      lookingFor = prefs.getString('lookingFor') ?? 'Something meaningful 💜';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', nameController.text);
    await prefs.setStringList('userInterests', selectedInterests);
    await prefs.setString('instagram', instagramController.text);
    await prefs.setString('spotify', spotifyController.text);
    await prefs.setString('lookingFor', lookingFor);

    Get.back(
      result: {
        'name': nameController.text,
        'bio': bioController.text,
        'year': yearController.text,
        'major': majorController.text,
        'interests': selectedInterests,
        'instagram': instagramController.text,
        'spotify': spotifyController.text,
        'lookingFor': lookingFor,
      },
    );

    Get.snackbar(
      'Profile Updated',
      'Your changes have been saved',
      backgroundColor: NexoraColors.success.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
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
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
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
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NexoraColors.primaryPurple.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Completion Card
                            _buildProfileCompletionCard(),

                            const SizedBox(height: 24),

                            // Profile Avatar Section
                            _buildAvatarSection(),

                            const SizedBox(height: 32),

                            // Basic Info Section
                            _buildSectionHeader(
                              'Basic Info',
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildBasicInfoCard(),

                            const SizedBox(height: 28),

                            // Interests Section
                            _buildSectionHeader(
                              'Your Interests',
                              Icons.favorite_outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select up to 8 interests (${selectedInterests.length}/8)',
                              style: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInterestsGrid(),

                            const SizedBox(height: 28),

                            // Looking For Section
                            _buildSectionHeader(
                              'Looking For',
                              Icons.search_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildLookingForSection(),

                            const SizedBox(height: 28),

                            // Social Links Section
                            _buildSectionHeader(
                              'Connect Your Socials',
                              Icons.link,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Let others discover you on other platforms',
                              style: TextStyle(
                                color: NexoraColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSocialLinksCard(),

                            const SizedBox(height: 32),

                            // Save Button
                            _buildSaveButton(),

                            const SizedBox(height: 40),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NexoraColors.glassBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: NexoraColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NexoraColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: _saveProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: NexoraGradients.primaryButton,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: NexoraColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final completion = profileCompletion;
    final percentage = (completion * 100).round();

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: completion >= 1.0
                      ? const LinearGradient(
                          colors: [NexoraColors.success, Color(0xFF81C784)],
                        )
                      : NexoraGradients.primaryButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  completion >= 1.0 ? Icons.check_circle : Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completion >= 1.0
                          ? 'Profile Complete! 🎉'
                          : 'Complete Your Profile',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NexoraColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      completion >= 1.0
                          ? 'You\'re ready to make connections!'
                          : 'Complete profiles get more visibility',
                      style: TextStyle(
                        fontSize: 12,
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: NexoraColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: MediaQuery.of(context).size.width * completion * 0.85,
                  decoration: BoxDecoration(
                    gradient: completion >= 1.0
                        ? const LinearGradient(
                            colors: [NexoraColors.success, Color(0xFF81C784)],
                          )
                        : NexoraGradients.logoGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NexoraColors.primaryPurple.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Avatar
              Container(
                width: 120,
                height: 120,
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
                    width: 3,
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
                          style: const TextStyle(
                            fontSize: 44,
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
                        style: const TextStyle(
                          fontSize: 44,
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
                  onTap: () {
                    // Navigate back to profile to use avatar editor
                    Get.snackbar(
                      'Edit Avatar',
                      'Use the avatar editor on your profile page',
                      backgroundColor: NexoraColors.midnightPurple.withOpacity(
                        0.9,
                      ),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: NexoraGradients.primaryButton,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NexoraColors.midnightDark,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexoraColors.primaryPurple.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to change avatar',
            style: TextStyle(color: NexoraColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
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
    );
  }

  Widget _buildBasicInfoCard() {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField(
            label: 'Display Name',
            controller: nameController,
            icon: Icons.person_outline,
            hint: 'What should people call you?',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Bio',
            controller: bioController,
            icon: Icons.edit_note,
            maxLines: 3,
            hint: 'Tell others about yourself...',
            maxLength: 150,
          ),
          const SizedBox(height: 20),
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
              const SizedBox(width: 16),
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
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: allInterests.map((interest) {
          final isSelected = selectedInterests.contains(interest['label']);
          return GestureDetector(
            onTap: () => _toggleInterest(interest['label']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? NexoraGradients.primaryButton : null,
                color: isSelected ? null : NexoraColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
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
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    interest['emoji']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    interest['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : NexoraColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check, color: Colors.white, size: 14),
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
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: lookingForOptions.map((option) {
          final isSelected = lookingFor == option['label'];
          return GestureDetector(
            onTap: () {
              setState(() {
                lookingFor = option['label'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (option['color'] as Color).withOpacity(0.6)
                      : NexoraColors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      option['icon'],
                      color: isSelected ? Colors.white : NexoraColors.textMuted,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option['label'],
                      style: TextStyle(
                        color: isSelected
                            ? NexoraColors.textPrimary
                            : NexoraColors.textSecondary,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: option['color'],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSocialLinksCard() {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSocialField(
            label: 'Instagram',
            controller: instagramController,
            icon: Icons.camera_alt_outlined,
            color: const Color(0xFFE4405F),
            prefix: '@',
            hint: 'username',
          ),
          const SizedBox(height: 16),
          _buildSocialField(
            label: 'Spotify',
            controller: spotifyController,
            icon: Icons.music_note,
            color: const Color(0xFF1DB954),
            hint: 'Share your music taste',
          ),
        ],
      ),
    );
  }

  Widget _buildSocialField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    String? prefix,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: NexoraColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NexoraColors.cardBorder),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: NexoraColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: prefix != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Text(
                        prefix,
                        style: TextStyle(
                          color: NexoraColors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: NexoraColors.textMuted.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(
                left: prefix != null ? 0 : 16,
                right: 16,
                top: 14,
                bottom: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: NexoraGradients.primaryButton,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: NexoraColors.primaryPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 12),
            ),
            if (maxLength != null)
              Text(
                '${controller.text.length}/$maxLength',
                style: TextStyle(
                  color: controller.text.length > maxLength
                      ? NexoraColors.error
                      : NexoraColors.textMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: NexoraColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NexoraColors.cardBorder),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: const TextStyle(color: NexoraColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: maxLines > 1 ? 50 : 0),
                child: Icon(icon, color: NexoraColors.primaryPurple, size: 20),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: NexoraColors.textMuted.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
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
          style: TextStyle(color: NexoraColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: NexoraColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NexoraColors.cardBorder),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: NexoraColors.textPrimary,
                        fontSize: 14,
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

  @override
  void dispose() {
    nameController.removeListener(_updateState);
    bioController.removeListener(_updateState);
    nameController.dispose();
    bioController.dispose();
    yearController.dispose();
    majorController.dispose();
    instagramController.dispose();
    spotifyController.dispose();
    _animController.dispose();
    super.dispose();
  }
}
