import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/nexora_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../connections/repositories/connection_service.dart';
import '../../chat/screens/chat_detail_screen.dart';

/// Profile View Screen - View another user's profile with message option
class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String avatar;
  final String bio;
  final String year;
  final String major;
  final List<String> interests;
  final String? instagram;
  final String? spotify;
  final String? lookingFor;
  final bool isOnline;

  const ProfileViewScreen({
    required this.userId,
    required this.name,
    required this.avatar,
    this.bio = '',
    this.year = '',
    this.major = '',
    this.interests = const [],
    this.instagram,
    this.spotify,
    this.lookingFor,
    this.isOnline = false,
    super.key,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLiked = false;
  final ConnectionService _connectionService = Get.find<ConnectionService>();

  // Interest emojis map
  final Map<String, String> interestEmojis = {
    'Coding': '💻',
    'Gaming': '🎮',
    'Music': '🎵',
    'Photography': '📸',
    'Travel': '✈️',
    'Reading': '📚',
    'Movies': '🎬',
    'Fitness': '🏃',
    'Art': '🎨',
    'Coffee': '☕',
    'Cooking': '🍳',
    'Pets': '🐕',
    'Theater': '🎭',
    'Sports': '⚽',
    'Yoga': '🧘',
    'Nature': '🌱',
    'Singing': '🎤',
    'Dancing': '💃',
    'Instruments': '🎸',
    'Board Games': '🎲',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openChat() {
    Get.to(
      () => ChatDetailScreen(name: widget.name, avatar: widget.avatar),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      Get.snackbar(
        'Liked! 💜',
        'You liked ${widget.name}\'s profile',
        backgroundColor: NexoraColors.romanticPink.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.favorite, color: Colors.white),
      );
    }
  }

  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NexoraColors.midnightPurple.withOpacity(0.98),
              NexoraColors.midnightDark.withOpacity(0.98),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: NexoraColors.primaryPurple.withOpacity(0.3),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                icon: Icons.share_outlined,
                label: 'Share Profile',
                color: NexoraColors.accentCyan,
                onTap: () {
                  Get.back();
                  Get.snackbar(
                    'Share',
                    'Profile link copied!',
                    backgroundColor: NexoraColors.accentCyan.withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.block_outlined,
                label: 'Block User',
                color: NexoraColors.warning,
                onTap: () {},
              ),
              _buildOptionTile(
                icon: Icons.report_outlined,
                label: 'Report Profile',
                color: NexoraColors.error,
                onTap: () {
                  Get.back();
                  _showReportDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: NexoraColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showReportDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexoraColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report,
                  color: NexoraColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Report Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                'Inappropriate content',
                'Fake profile',
                'Harassment',
                'Spam',
              ].map((reason) => _buildReportOption(reason)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.snackbar(
          'Report Submitted',
          'Thank you for keeping Nexora safe',
          backgroundColor: NexoraColors.success.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: NexoraColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NexoraColors.cardBorder),
        ),
        child: Text(
          reason,
          style: const TextStyle(color: NexoraColors.textPrimary, fontSize: 15),
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
          // Background gradients
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
            bottom: 150,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
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

          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                _buildAppBar(),

                // Scrollable content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Profile Header
                            _buildProfileHeader(),

                            const SizedBox(height: 24),

                            // Bio Section
                            if (widget.bio.isNotEmpty) _buildBioSection(),

                            const SizedBox(height: 20),

                            // Spotify Anthem Section
                            _buildSpotifySection(),

                            const SizedBox(height: 20),

                            // Interests Section
                            if (widget.interests.isNotEmpty)
                              _buildInterestsSection(),

                            const SizedBox(height: 20),

                            // Looking For Section
                            if (widget.lookingFor != null &&
                                widget.lookingFor!.isNotEmpty)
                              _buildLookingForSection(),

                            const SizedBox(height: 20),

                            // Social Links
                            if (widget.instagram != null ||
                                widget.spotify != null)
                              _buildSocialLinks(),

                            const SizedBox(
                              height: 100,
                            ), // Space for bottom buttons
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActions(),
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
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NexoraColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NexoraColors.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NexoraColors.glassBorder),
              ),
              child: const Icon(
                Icons.more_vert,
                color: NexoraColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar with online indicator
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NexoraColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 35,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            // Avatar
            Container(
              width: 130,
              height: 130,
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
                  color: NexoraColors.primaryPurple.withOpacity(0.6),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: widget.avatar.startsWith('http')
                    ? Image.network(
                        widget.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            widget.name.isNotEmpty
                                ? widget.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 50,
                              color: NexoraColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.name.isNotEmpty
                              ? widget.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 50,
                            color: NexoraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            // Online indicator
            if (widget.isOnline)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: NexoraColors.online,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NexoraColors.midnightDark,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.online.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: NexoraColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: NexoraGradients.cyanAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Year & Major
        if (widget.year.isNotEmpty || widget.major.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NexoraColors.primaryPurple.withOpacity(0.2),
                  NexoraColors.romanticPink.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: NexoraColors.primaryPurple.withOpacity(0.3),
              ),
            ),
            child: Text(
              [
                widget.year,
                widget.major,
              ].where((s) => s.isNotEmpty).join(' • '),
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Online status
        if (widget.isOnline)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: NexoraColors.online,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Online now',
                  style: TextStyle(
                    color: NexoraColors.online,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About', Icons.person_outline),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.bio,
            style: const TextStyle(
              color: NexoraColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpotifySection() {
    // Mock Spotify data for the viewed profile
    const spotifyAnthem = {
      'title': 'Starboy',
      'artist': 'The Weeknd',
      'albumArt':
          'https://i.scdn.co/image/ab67616d0000b27304e80018e9a3a9b2f5ba8f95',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('On Repeat', Icons.music_note_rounded),
        const SizedBox(height: 12),
        Container(
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
            border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.2)),
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
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  spotifyAnthem['albumArt']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF1DB954),
                                            Color(0xFF169C46),
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.music_note_rounded,
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
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    borderRadius: BorderRadius.circular(3),
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

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Interests', Icons.favorite_outline),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.interests.map((interest) {
            final emoji = interestEmojis[interest] ?? '✨';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    interest,
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
      ],
    );
  }

  Widget _buildLookingForSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Looking For', Icons.search_outlined),
        const SizedBox(height: 12),
        GlassContainer(
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
              Expanded(
                child: Text(
                  widget.lookingFor!,
                  style: const TextStyle(
                    color: NexoraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Socials', Icons.link),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (widget.instagram != null && widget.instagram!.isNotEmpty)
                _buildSocialRow(
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  value: '@${widget.instagram}',
                  color: const Color(0xFFE4405F),
                ),
              if (widget.instagram != null &&
                  widget.instagram!.isNotEmpty &&
                  widget.spotify != null &&
                  widget.spotify!.isNotEmpty)
                const SizedBox(height: 12),
              if (widget.spotify != null && widget.spotify!.isNotEmpty)
                _buildSocialRow(
                  icon: Icons.music_note,
                  label: 'Spotify',
                  value: widget.spotify!,
                  color: const Color(0xFF1DB954),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: NexoraColors.textMuted, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            NexoraColors.midnightDark.withOpacity(0.9),
            NexoraColors.midnightDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Like Button
            GestureDetector(
              onTap: _toggleLike,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: _isLiked ? NexoraGradients.romanticGlow : null,
                  color: _isLiked ? null : NexoraColors.glassBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isLiked
                        ? Colors.transparent
                        : NexoraColors.romanticPink.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: _isLiked
                      ? [
                          BoxShadow(
                            color: NexoraColors.romanticPink.withOpacity(0.4),
                            blurRadius: 15,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.white : NexoraColors.romanticPink,
                  size: 28,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Connect Button
            _buildConnectionButton(),

            const SizedBox(width: 12),

            // Message Button
            Expanded(
              child: GestureDetector(
                onTap: _openChat,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: NexoraGradients.primaryButton,
                    borderRadius: BorderRadius.circular(18),
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
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Send Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton() {
    return Obx(() {
      final status = _connectionService.getStatus(widget.userId);

      IconData icon;
      String label;
      Color bgColor;
      Color borderColor;
      Color contentColor;
      VoidCallback? onTap;

      switch (status) {
        case ConnectionStatus.connected:
          icon = Icons.check_circle_rounded;
          label = 'Connected';
          bgColor = NexoraColors.success.withOpacity(0.15);
          borderColor = NexoraColors.success.withOpacity(0.3);
          contentColor = NexoraColors.success;
          onTap = () {
            _showDisconnectDialog();
          };
          break;
        case ConnectionStatus.pending:
          icon = Icons.schedule_rounded;
          label = 'Pending';
          bgColor = NexoraColors.textMuted.withOpacity(0.15);
          borderColor = NexoraColors.textMuted.withOpacity(0.3);
          contentColor = NexoraColors.textSecondary;
          onTap = () {
            _connectionService.cancelRequest(widget.userId);
            Get.snackbar(
              'Request Cancelled',
              'Connection request to ${widget.name} cancelled',
              backgroundColor: NexoraColors.glassBackground,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          };
          break;
        case ConnectionStatus.incoming:
          icon = Icons.person_add_alt_1_rounded;
          label = 'Accept';
          bgColor = NexoraColors.success.withOpacity(0.15);
          borderColor = NexoraColors.success.withOpacity(0.3);
          contentColor = NexoraColors.success;
          onTap = () {
            _connectionService.acceptRequest(widget.userId);
            Get.snackbar(
              'Connected!',
              'You are now connected with ${widget.name}',
              backgroundColor: NexoraColors.success.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              icon: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.check_circle_rounded, color: Colors.white),
              ),
            );
          };
          break;
        case ConnectionStatus.none:
          icon = Icons.person_add_rounded;
          label = 'Connect';
          bgColor = NexoraColors.accentCyan.withOpacity(0.15);
          borderColor = NexoraColors.accentCyan.withOpacity(0.3);
          contentColor = NexoraColors.accentCyan;
          onTap = () {
            _connectionService.sendRequest(
              userId: widget.userId,
              name: widget.name,
              avatar: widget.avatar,
              major: widget.major,
              year: widget.year,
            );
            Get.snackbar(
              'Connection Request Sent',
              'You sent a connection request to ${widget.name}',
              backgroundColor: NexoraColors.primaryPurple.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              icon: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.person_add_rounded, color: Colors.white),
              ),
            );
          };
      }

      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: contentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showDisconnectDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: NexoraColors.midnightDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Connection',
          style: TextStyle(color: NexoraColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${widget.name} from your connections?',
          style: const TextStyle(color: NexoraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: NexoraColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              _connectionService.removeConnection(widget.userId);
              Get.back();
              Get.snackbar(
                'Connection Removed',
                '${widget.name} has been removed from your connections',
                backgroundColor: NexoraColors.glassBackground,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: NexoraColors.romanticPink),
            ),
          ),
        ],
      ),
    );
  }
}
